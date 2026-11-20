import Foundation
import Testing
@testable import yeoulmok

/// APP-DTL-09 (#90): API spec v0.6 — history (item 12), level limits and 24-hour rain.
struct ValleyHistoryTests {
    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder.yeoulmok().decode(T.self, from: Data(json.utf8))
    }

    /// The example in API spec v0.6, item 12.
    @Test func decodesSpecExample() throws {
        let history = try decode(ValleyHistory.self, """
        {
          "updated_at": "2026-11-20T10:35", "valley_id": 1, "hours": 3, "step_minutes": 10,
          "has_water": true,
          "thresholds": {
            "rain_1h_mm": {"caution": 15.0, "danger": 25.0, "evacuate": 40.0},
            "water_rise_30m_m": {"caution": 0.1, "danger": 0.2, "evacuate": 0.3}
          },
          "points": [
            {"at": "2026-11-20T07:30", "rain_1h_mm": 0.0, "water_level_m": 0.21, "water_rise_30m_m": 0.0, "level": "safe"},
            {"at": "2026-11-20T07:40", "rain_1h_mm": null, "water_level_m": null, "water_rise_30m_m": null, "level": "unknown"}
          ],
          "source": "자료: 한강홍수통제소, 기상청"
        }
        """)

        #expect(history.valleyID == 1)
        #expect(history.stepMinutes == 10)
        #expect(history.hasWater)
        #expect(history.thresholds.rainLastHour == LevelThresholds(caution: 15, danger: 25, evacuate: 40))
        #expect(history.thresholds.waterRise30Min?.evacuate == 0.3)
        try #require(history.points.count == 2)
        #expect(history.points[0].at == ServerDate.parse("2026-11-20T07:30"))
        #expect(history.points[0].rainLastHourMM == 0.0)
        #expect(history.points[0].waterLevelM == 0.21)
        #expect(history.points[0].level == .safe)
        // Missing stays nil, never 0.
        #expect(history.points[1].rainLastHourMM == nil)
        #expect(history.points[1].waterLevelM == nil)
        #expect(history.points[1].level == .unknown)
    }

    /// A valley without a water gauge: `has_water: false`, no water limits.
    @Test func decodesValleyWithoutWater() throws {
        let history = try decode(ValleyHistory.self, """
        {"updated_at": "2026-11-20T10:35", "valley_id": 3, "hours": 3, "step_minutes": 10,
         "has_water": false,
         "thresholds": {"rain_1h_mm": {"caution": 15.0, "danger": 25.0, "evacuate": 40.0}, "water_rise_30m_m": null},
         "points": [{"at": "2026-11-20T07:30", "rain_1h_mm": 1.5, "water_level_m": null, "water_rise_30m_m": null}],
         "source": "자료"}
        """)

        #expect(history.hasWater == false)
        #expect(history.thresholds.waterRise30Min == nil)
        #expect(history.points.first?.level == nil)
    }

    /// v0.6 detail: `thresholds` on each observation (AI estimate has only `caution`)
    /// and `rain_24h_mm`.
    @Test func detailDecodesLevelLimitsAnd24HourRain() throws {
        let detail = try decode(ValleyDetail.self, """
        {"updated_at": "2026-11-20T10:35", "id": 1, "name": "금대리 계곡", "level": "caution",
         "summary": "요약", "ai_explanation": null, "ai_fallback": true,
         "observations": [
           {"type": "rain_1h", "station": "원주 신림(AWS)", "observed_at": "2026-11-20T10:30",
            "value": 18.0, "unit": "mm", "threshold": 15.0, "note": null,
            "thresholds": {"caution": 15.0, "danger": 25.0, "evacuate": 40.0}},
           {"type": "est_rise_3h", "station": "AI 추정(강수 기반)", "observed_at": "2026-11-20T10:00",
            "value": 0.08, "unit": "m", "threshold": 0.07, "note": null, "estimated": true,
            "thresholds": {"caution": 0.07, "danger": null, "evacuate": null}}
         ],
         "rain_24h_mm": 12.5,
         "actions": [], "disclaimer": "면책", "source": "자료", "subscribed": false, "stale": false}
        """)

        #expect(detail.rainLast24hMM == 12.5)
        #expect(detail.observations[0].thresholds?.steps.map(\.value) == [15, 25, 40])
        #expect(detail.observations[0].thresholds?.steps.map(\.level) == [.caution, .danger, .evacuate])
        // Levels without a limit are left out, not drawn at 0.
        #expect(detail.observations[1].thresholds?.steps.map(\.level) == [.caution])
    }

    /// The server before v0.6 sends neither: everything still reads, both are nil.
    @Test func olderDetailHasNoLimitsOr24HourRain() throws {
        let detail = try decode(ValleyDetail.self, """
        {"updated_at": "2026-11-20T10:35", "id": 1, "name": "금대리 계곡", "level": "safe",
         "summary": "요약", "ai_explanation": null, "ai_fallback": true,
         "observations": [{"type": "rain_1h", "station": "원주 신림(AWS)", "observed_at": "2026-11-20T10:30",
                           "value": 0.0, "unit": "mm", "threshold": 15.0, "note": null}],
         "actions": [], "disclaimer": "면책", "source": "자료", "subscribed": false, "stale": false}
        """)

        #expect(detail.rainLast24hMM == nil)
        #expect(detail.observations[0].thresholds == nil)
    }

    @Test func mockHistoriesLoad() throws {
        let histories = try MockData.valleyHistories(bundle: .main)
        #expect(histories.map(\.valleyID) == [1, 2, 3, 4, 5])
        #expect(histories.allSatisfy { $0.points.count == 19 })
        #expect(histories.first { $0.valleyID == 2 }?.hasWater == false)
    }
}
