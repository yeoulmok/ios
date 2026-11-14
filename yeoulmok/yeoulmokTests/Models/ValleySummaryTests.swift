import Foundation
import Testing
@testable import yeoulmok

struct ValleySummaryTests {
    private func decode(_ json: String) throws -> ValleyListResponse {
        try JSONDecoder.yeoulmok().decode(ValleyListResponse.self, from: Data(json.utf8))
    }

    @Test func decodesSpecExample() throws {
        let response = try decode("""
        {
          "updated_at": "2026-11-07T22:00",
          "source": "자료: 한강홍수통제소, 기상청",
          "valleys": [{
            "id": 1, "name": "금대리 계곡", "region": "원주시 판부면",
            "lat": 37.278313, "lon": 128.019563, "level": "caution",
            "rain_1h_mm": 18.0, "water_rise_30m_m": 0.06,
            "observed_at": "2026-11-07T21:50", "stale": false, "subscribed": true
          }]
        }
        """)

        #expect(response.source == "자료: 한강홍수통제소, 기상청")
        let valley = try #require(response.valleys.first)
        #expect(valley.id == 1)
        #expect(valley.level == .caution)
        #expect(valley.rainLastHourMM == 18.0)
        #expect(valley.waterRise30MinM == 0.06)
        #expect(valley.isStale == false)
        #expect(valley.isSubscribed == true)
    }

    @Test func nullValuesStayNilNotZero() throws {
        let response = try decode("""
        {
          "updated_at": "2026-11-07T22:00", "source": "자료",
          "valleys": [{
            "id": 2, "name": "갑천 계곡", "region": "횡성군 갑천면",
            "lat": 37.5, "lon": 128.0, "level": "unknown",
            "rain_1h_mm": null, "water_rise_30m_m": null,
            "observed_at": null, "stale": true, "subscribed": false
          }]
        }
        """)

        let valley = try #require(response.valleys.first)
        #expect(valley.level == .unknown)
        #expect(valley.rainLastHourMM == nil)
        #expect(valley.waterRise30MinM == nil)
        #expect(valley.observedAt == nil)
        #expect(valley.isStale == true)
    }

    @Test func zeroRainfallIsKeptAsZero() throws {
        let response = try decode("""
        {
          "updated_at": "2026-11-07T22:00", "source": "자료",
          "valleys": [{
            "id": 1, "name": "금대리 계곡", "region": "원주시 판부면",
            "lat": 37.0, "lon": 128.0, "level": "safe",
            "rain_1h_mm": 0.0, "water_rise_30m_m": 0.0,
            "observed_at": "2026-11-07T21:50", "stale": false, "subscribed": false
          }]
        }
        """)

        #expect(response.valleys.first?.rainLastHourMM == 0.0)
    }

    @Test(arguments: ["safe", "caution", "danger", "evacuate", "unknown"])
    func decodesEveryKnownLevel(rawValue: String) throws {
        let level = try JSONDecoder().decode(ValleyLevel.self, from: Data("\"\(rawValue)\"".utf8))
        #expect(level.rawValue == rawValue)
    }

    @Test func unrecognizedLevelBecomesUnknown() throws {
        let level = try JSONDecoder().decode(ValleyLevel.self, from: Data("\"flood\"".utf8))
        #expect(level == .unknown)
    }
}
