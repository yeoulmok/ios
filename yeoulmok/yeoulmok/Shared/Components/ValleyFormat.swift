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

    /// Rainfall with a `+` on the alert detail (#107): `+18.0mm`, `+0.0mm`, so it reads
    /// like the water rise next to it. A missing value stays `-`.
    static func rainfallSigned(_ mm: Double?) -> String {
        guard let mm else { return missing }
        return "+" + rainfall(mm)
    }

    /// Water level change with two decimals and a sign: `+0.22m`, `+0.00m`, `-0.05m`.
    /// Values that round to zero show as `+0.00m`, so it reads as a change, not a level (#83).
    static func waterRise(_ meters: Double?) -> String {
        guard let meters else { return missing }
        let rounded = (meters * 100).rounded() / 100
        if rounded == 0 { return "+0.00m" }
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

    /// "방금 전", "12분 전", "3시간 전", older than a day: the date and time (#59).
    /// Missing: "-".
    static func timeAgo(_ date: Date?, now: Date = .now) -> String {
        guard let date else { return missing }
        let minutes = Int(now.timeIntervalSince(date) / 60)
        switch minutes {
        case ..<1: return "방금 전"
        case ..<60: return "\(minutes)분 전"
        case ..<(24 * 60): return "\(minutes / 60)시간 전"
        default: return observedTime(date, now: now)
        }
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
