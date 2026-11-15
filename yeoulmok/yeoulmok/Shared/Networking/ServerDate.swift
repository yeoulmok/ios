import Foundation

/// Server times are Korean time written without an offset, e.g. `"2026-11-07T22:00"`.
/// A string like that does not say which time zone it is in, so we state it here.
nonisolated enum ServerDate {
    /// Korea has no daylight saving time, so this is always UTC+9.
    static let timeZone = TimeZone(identifier: "Asia/Seoul")!

    /// The spec uses minutes; seconds are accepted in case the server adds them later.
    private static let formats = ["yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd'T'HH:mm:ss"]

    /// `"2026-11-07T22:00:00"`: the server's format with seconds, so `parse` reads it back
    /// exactly. Used to save responses on the device (`ValleyCache`).
    static func string(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = formats[1]
        return formatter.string(from: date)
    }

    static func parse(_ text: String) -> Date? {
        let formatter = DateFormatter()
        // Fixed locale and calendar so the user's device settings (12-hour clock,
        // Buddhist calendar, etc.) cannot change how the text is read.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) {
                return date
            }
        }
        return nil
    }
}

extension JSONEncoder {
    /// Writes models in the server's own JSON shape and time format, so
    /// `JSONDecoder.yeoulmok()` reads them back unchanged.
    nonisolated static func yeoulmok() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ServerDate.string(from: date))
        }
        return encoder
    }
}

extension JSONDecoder {
    /// Decoder for every server response. Turns server time strings into `Date`.
    nonisolated static func yeoulmok() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            guard let date = ServerDate.parse(text) else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected Korean time like 2026-11-07T22:00, got \(text)"
                )
            }
            return date
        }
        return decoder
    }
}
