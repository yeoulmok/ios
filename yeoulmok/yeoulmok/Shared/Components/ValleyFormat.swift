import Foundation

/// Turns observation values into the text shown on screen (Figma 01 v2 card).
/// A missing value is always `missing` ("-"), never "0", so "unknown" and
/// "no rain" never look the same.
nonisolated enum ValleyFormat {
    static let missing = "-"

    /// Rainfall with one decimal: `18.0mm`, `0.0mm`.
    static func rainfall(_ mm: Double?) -> String {
        guard let mm else { return missing }
        return String(format: "%.1fmm", mm)
    }

    /// Water level change with two decimals and a sign: `+0.22m`, `0.00m`, `-0.05m`.
    /// Values that round to zero show as `0.00m` (no `+` or `-`).
    static func waterRise(_ meters: Double?) -> String {
        guard let meters else { return missing }
        let rounded = (meters * 100).rounded() / 100
        if rounded == 0 { return "0.00m" }
        return (rounded > 0 ? "+" : "-") + String(format: "%.2fm", abs(rounded))
    }

    /// Observation time in Korean time: `21:50` for today, `11/13 21:50` for
    /// another day, so an old observation never looks current.
    static func observedTime(_ date: Date?, now: Date = .now) -> String {
        guard let date else { return missing }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = ServerDate.timeZone
        let sameDay = calendar.isDate(date, inSameDayAs: now)
        return formatter(sameDay ? "HH:mm" : "M/d HH:mm").string(from: date)
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = ServerDate.timeZone
        formatter.dateFormat = format
        return formatter
    }
}
