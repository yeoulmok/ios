import Foundation

/// Server times are Korean time written without an offset, e.g. `"2026-11-07T22:00"`.
/// A string like that does not say which time zone it is in, so we state it here.
nonisolated enum ServerDate {
    /// Korea has no daylight saving time, so this is always UTC+9.
    static let timeZone = TimeZone(identifier: "Asia/Seoul")!

    // One formatter per format, made once and shared (#103): making a `DateFormatter`
    // is slow, and a list of 126 valleys has 127 times. Never changed after they are
    // made, and `DateFormatter` is thread-safe (the SDK marks it `Sendable`), so decoders on any thread
    // may use them at the same time.

    /// The spec uses minutes.
    private static let minutes = formatter("yyyy-MM-dd'T'HH:mm")
    /// Accepted in case the server adds seconds later; also how `ValleyCache` saves.
    private static let seconds = formatter("yyyy-MM-dd'T'HH:mm:ss")

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        // Fixed locale and calendar so the user's device settings (12-hour clock,
        // Buddhist calendar, etc.) cannot change how the text is read.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter
    }

    /// `"2026-11-07T22:00:00"`: the server's format with seconds, so `parse` reads it back
    /// exactly. Used to save responses on the device (`ValleyCache`).
    static func string(from date: Date) -> String {
        seconds.string(from: date)
    }

    static func parse(_ text: String) -> Date? {
        minutes.date(from: text) ?? seconds.date(from: text)
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
