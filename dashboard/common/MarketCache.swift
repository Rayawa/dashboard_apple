import Foundation

actor MarketCache {
    static let shared = MarketCache()

    private struct Entry<Value: Codable>: Codable {
        let savedAt: Date
        let value: Value
    }

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let directory: URL
    private let maximumCacheBytes: Int64 = 128 * 1_024 * 1_024
    private let trimTargetBytes: Int64 = 96 * 1_024 * 1_024

    private init() {
        encoder = JSONEncoder()
        decoder = JSONDecoder()
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        directory = base.appending(path: "top.rayawa.dashboard.api-cache", directoryHint: .isDirectory)
    }

    func read<Value: Codable & Sendable>(
        _ type: Value.Type,
        key: String,
        freshFor: TimeInterval,
        maximumAge: TimeInterval
    ) -> APIDataResult<Value>? {
        let url = fileURL(for: key)
        guard freshFor.isFinite, maximumAge.isFinite,
              freshFor >= 0, maximumAge >= freshFor else {
            return nil
        }
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let entry = try? decoder.decode(Entry<Value>.self, from: data) else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        let age = max(0, Date().timeIntervalSince(entry.savedAt))
        guard age <= maximumAge else {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        return APIDataResult(
            data: entry.value,
            isFromCache: true,
            isStale: age > freshFor,
            cachedAt: entry.savedAt
        )
    }

    func write<Value: Codable & Sendable>(_ value: Value, key: String) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try encoder.encode(Entry(savedAt: Date(), value: value))
            try data.write(to: fileURL(for: key), options: .atomic)
            trimIfNeeded()
        } catch {
            // Cache failures must never make a successful API request fail.
        }
    }

    func removeAll() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        try FileManager.default.removeItem(at: directory)
    }

    func size() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            let values = try? url.resourceValues(forKeys: [.fileSizeKey])
            total = addingFileSize(values?.fileSize, to: total)
        }
        return total
    }

    private func fileURL(for key: String) -> URL {
        directory.appending(path: "\(stableHash(key)).json")
    }

    private func stableHash(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return String(hash, radix: 16)
    }

    private func trimIfNeeded() {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var files: [(url: URL, size: Int64, modifiedAt: Date)] = []
        var total: Int64 = 0
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [
                .fileSizeKey, .contentModificationDateKey, .isRegularFileKey,
            ]), values.isRegularFile == true else { continue }
            let fileSize = Int64(max(0, values.fileSize ?? 0))
            files.append((url, fileSize, values.contentModificationDate ?? .distantPast))
            total = addingFileSize(values.fileSize, to: total)
        }
        guard total > maximumCacheBytes else { return }

        for file in files.sorted(by: { $0.modifiedAt < $1.modifiedAt }) where total > trimTargetBytes {
            do {
                try FileManager.default.removeItem(at: file.url)
                total -= file.size
            } catch {
                // A failed eviction is non-fatal; the next write will retry trimming.
            }
        }
    }

    private func addingFileSize(_ size: Int?, to total: Int64) -> Int64 {
        let value = Int64(max(0, size ?? 0))
        let (sum, overflow) = max(0, total).addingReportingOverflow(value)
        return overflow ? Int64.max : sum
    }
}
