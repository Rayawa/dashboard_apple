import Foundation

/// Shared validation for values handed to Swift Charts.
///
/// Swift Charts assumes domains and gesture-derived values are finite. Keeping
/// those checks here prevents a malformed response or transient gesture value
/// from reaching framework interpolation code and terminating the process.
enum ChartInteractionSupport {
    static let secondsPerDay = 24.0 * 60.0 * 60.0

    static func daySpan(for dates: [Date], minimum: Double = 14) -> Double {
        guard let first = dates.min(), let last = dates.max() else { return minimum }
        let span = last.timeIntervalSince(first) / secondsPerDay + 1
        guard span.isFinite else { return minimum }
        return max(minimum, span)
    }

    static func zoomedDaySpan(
        start: Double,
        magnification: Double,
        fullSpan: Double,
        maximumZoom: Double = 4
    ) -> Double? {
        guard start.isFinite,
              magnification.isFinite,
              magnification > 0,
              fullSpan.isFinite,
              fullSpan > 0,
              maximumZoom.isFinite,
              maximumZoom >= 1 else { return nil }
        let result = start / magnification
        guard result.isFinite else { return nil }
        return min(fullSpan, max(fullSpan / maximumZoom, result))
    }

    static func validSelection(_ value: Double?, total: Double) -> Double? {
        guard let value, value.isFinite, total.isFinite, total > 0 else { return nil }
        return min(max(0, value), total)
    }

    static func finitePercentage(_ value: Double?) -> Double {
        guard let value, value.isFinite else { return 0 }
        return min(100, max(0, value))
    }

    static func nonnegativeSum(_ values: some Sequence<Int>) -> Int {
        DashboardDataSupport.nonnegativeSum(values)
    }

    static func addingNonnegative(_ value: Int, to total: Int) -> Int {
        DashboardDataSupport.addingNonnegative(value, to: total)
    }
}
