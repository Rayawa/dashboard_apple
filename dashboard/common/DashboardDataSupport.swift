import Foundation

/// Normalizes untrusted API values before they reach SwiftUI and Swift Charts.
enum DashboardDataSupport {
    static func addingNonnegative(_ value: Int, to total: Int) -> Int {
        let safeValue = max(0, value)
        let (sum, overflow) = max(0, total).addingReportingOverflow(safeValue)
        return overflow ? Int.max : sum
    }

    static func nonnegativeSum(_ values: some Sequence<Int>) -> Int {
        values.reduce(0) { addingNonnegative($1, to: $0) }
    }

    static func boundedPageCount(
        reported: Int,
        totalCount: Int,
        pageSize: Int,
        maximum: Int = 1_000
    ) -> Int {
        let safeMaximum = max(1, maximum)
        let safeTotal = max(0, totalCount)
        let safePageSize = max(1, pageSize)
        let calculated = safeTotal / safePageSize + (safeTotal % safePageSize == 0 ? 0 : 1)
        let dataBound = max(1, calculated)
        return min(max(1, reported), dataBound, safeMaximum)
    }

    static func progress(_ values: [Int]?) -> (value: Int, total: Int)? {
        guard let values, values.count >= 2 else { return nil }
        let total = max(0, values[1])
        guard total > 0 else { return nil }
        return (min(max(0, values[0]), total), total)
    }
}

extension Sequence {
    /// Preserves the first value for each key so list identity remains stable.
    func stableUniqued<Key: Hashable>(by key: (Element) -> Key) -> [Element] {
        var seen = Set<Key>()
        return filter { seen.insert(key($0)).inserted }
    }
}
