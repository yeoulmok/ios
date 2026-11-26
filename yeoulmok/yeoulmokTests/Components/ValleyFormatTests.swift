import Foundation
import Testing
@testable import yeoulmok

struct ValleyFormatTests {
    @Test(arguments: [
        (18.0, "18.0mm"),
        (0.5, "0.5mm"),
        (0.0, "0.0mm"),
        (32.45, "32.5mm"),
    ] as [(Double, String)])
    func rainfall(mm: Double, expected: String) {
        #expect(ValleyFormat.rainfall(mm) == expected)
    }

    @Test(arguments: [
        (0.22, "+0.22m"),
        (0.06, "+0.06m"),
        (0.0, "+0.00m"),
        (-0.05, "-0.05m"),
        (0.001, "+0.00m"),
        (-0.001, "+0.00m"),
    ] as [(Double, String)])
    func waterRise(meters: Double, expected: String) {
        #expect(ValleyFormat.waterRise(meters) == expected)
    }

    @Test func missingValuesShowDashNotZero() {
        #expect(ValleyFormat.rainfall(nil) == "-")
        #expect(ValleyFormat.waterRise(nil) == "-")
        #expect(ValleyFormat.observedTime(nil) == "-")
        // 0 is a real value and must look different from nil.
        #expect(ValleyFormat.rainfall(0) != ValleyFormat.rainfall(nil))
    }

    @Test func observedTimeTodayShowsHourAndMinute() throws {
        let observed = try #require(ServerDate.parse("2026-11-07T21:50"))
        let now = try #require(ServerDate.parse("2026-11-07T22:00"))
        #expect(ValleyFormat.observedTime(observed, now: now) == "21:50")
    }

    @Test func observedTimeOnAnotherDayShowsDate() throws {
        let observed = try #require(ServerDate.parse("2026-11-07T23:50"))
        let now = try #require(ServerDate.parse("2026-11-08T00:10"))
        #expect(ValleyFormat.observedTime(observed, now: now) == "11/7 23:50")
    }

    @Test func observedTimeIsKoreanTimeOnAnyDevice() throws {
        let original = NSTimeZone.default
        defer { NSTimeZone.default = original }
        NSTimeZone.default = TimeZone(identifier: "America/New_York")!

        let observed = try #require(ServerDate.parse("2026-11-07T21:50"))
        let now = try #require(ServerDate.parse("2026-11-07T22:00"))
        #expect(ValleyFormat.observedTime(observed, now: now) == "21:50")
    }

    /// #107: the detail shows rain with a `+`; missing stays `-` (never `+-`).
    @Test func signedRainfall() {
        #expect(ValleyFormat.rainfallSigned(18) == "+18.0mm")
        #expect(ValleyFormat.rainfallSigned(0) == "+0.0mm")
        #expect(ValleyFormat.rainfallSigned(nil) == "-")
        #expect(ObservationBox.rain24hText(31) == "24시간 강수 +31.0mm")
        #expect(ObservationBox.rain24hSpoken(31) == "24시간 강수 31.0mm")
    }
}
