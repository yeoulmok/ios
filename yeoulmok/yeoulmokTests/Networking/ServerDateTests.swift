import Foundation
import Testing
@testable import yeoulmok

struct ServerDateTests {
    @Test func readsTextAsKoreanTime() throws {
        let date = try #require(ServerDate.parse("2026-11-07T22:00"))
        // 22:00 in Korea is 13:00 UTC on the same day.
        let utc = try #require(ISO8601DateFormatter().date(from: "2026-11-07T13:00:00Z"))
        #expect(date == utc)
    }

    @Test func resultDoesNotDependOnDeviceTimeZone() throws {
        let original = NSTimeZone.default
        defer { NSTimeZone.default = original }

        NSTimeZone.default = TimeZone(identifier: "America/New_York")!
        let inNewYork = ServerDate.parse("2026-11-07T22:00")
        NSTimeZone.default = TimeZone(identifier: "Asia/Seoul")!
        let inSeoul = ServerDate.parse("2026-11-07T22:00")

        #expect(inNewYork != nil)
        #expect(inNewYork == inSeoul)
    }

    /// The formatters are shared (#103): reading from many threads at once gives the
    /// same answers as one at a time.
    @Test func sameAnswersFromManyThreadsAtOnce() async throws {
        let texts = (0..<1000).map { String(format: "2026-11-%02dT%02d:%02d", 1 + $0 % 28, $0 % 24, $0 % 60) }
        let oneByOne = texts.map(ServerDate.parse)

        let together = await withTaskGroup(of: (Int, Date?).self) { group in
            for (index, text) in texts.enumerated() {
                group.addTask { (index, ServerDate.parse(text)) }
            }
            var answers = [Date?](repeating: nil, count: texts.count)
            for await (index, date) in group { answers[index] = date }
            return answers
        }

        #expect(together == oneByOne)
        #expect(oneByOne.allSatisfy { $0 != nil })
    }

    @Test func acceptsSeconds() throws {
        let withSeconds = try #require(ServerDate.parse("2026-11-07T22:00:00"))
        #expect(withSeconds == ServerDate.parse("2026-11-07T22:00"))
    }

    @Test(arguments: ["", "2026-11-07", "22:00", "2026-11-07 22:00", "2026-11-07T22:00+09:00"])
    func rejectsOtherFormats(text: String) {
        #expect(ServerDate.parse(text) == nil)
    }

    @Test func decoderFailsOnBadTime() {
        let json = #"{"updated_at": "yesterday", "source": "자료", "valleys": []}"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder.yeoulmok().decode(ValleyListResponse.self, from: Data(json.utf8))
        }
    }

    @Test func decoderReadsListTimes() throws {
        let json = """
        {
          "updated_at": "2026-11-07T22:00", "source": "자료",
          "valleys": [{
            "id": 1, "name": "금대리 계곡", "region": "원주시 판부면",
            "lat": 37.0, "lon": 128.0, "level": "safe",
            "rain_1h_mm": 0.0, "water_rise_30m_m": 0.0,
            "observed_at": "2026-11-07T21:50", "stale": false, "subscribed": false
          }]
        }
        """
        let response = try JSONDecoder.yeoulmok().decode(ValleyListResponse.self, from: Data(json.utf8))
        let observedAt = try #require(response.valleys.first?.observedAt)
        #expect(response.updatedAt.timeIntervalSince(observedAt) == 10 * 60)
    }
}
