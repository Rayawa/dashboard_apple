import Foundation

nonisolated enum DashboardFormat {
    static func count(_ value: Int64) -> String {
        if value >= 100_000_000 {
            return String(format: "%.1f 亿", Double(value) / 100_000_000)
        }
        if value >= 10_000 {
            return String(format: "%.1f 万", Double(value) / 10_000)
        }
        return value.formatted(.number.grouping(.automatic))
    }

    static func count(_ value: Int) -> String {
        count(Int64(value))
    }

    static func bytes(_ value: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: value, countStyle: .file)
    }

    static func duration(_ interval: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        let normalized = max(0, interval)
        formatter.allowedUnits = normalized >= 3_600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: normalized) ?? "-"
    }

    static func dateTime(_ raw: String) -> String {
        guard !raw.isEmpty else { return "-" }
        let input = ISO8601DateFormatter()
        input.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = input.date(from: raw) ?? ISO8601DateFormatter().date(from: raw)
        guard let date else { return raw }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
