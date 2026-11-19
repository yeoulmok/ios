import Foundation
import Testing
@testable import yeoulmok

struct ValleyDetailTests {
    private func decode(_ json: String) throws -> ValleyDetail {
        try JSONDecoder.yeoulmok().decode(ValleyDetail.self, from: Data(json.utf8))
    }

    @Test func decodesSpecExample() throws {
        let detail = try decode("""
        {
          "updated_at": "2026-11-07T22:00", "id": 1, "name": "금대리 계곡",
          "level": "caution", "summary": "상류에 비가 많이 오고 있어요",
          "ai_explanation": "상류 관측소의 1시간 강수가 기준을 넘었어요.",
          "ai_fallback": false,
          "observations": [
            {"type": "rain_1h", "station": "원주 신림(AWS)", "observed_at": "2026-11-07T21:50",
             "value": 18.0, "unit": "mm", "threshold": 15.0, "note": null},
            {"type": "water_rise_30m", "station": "원주시(동부교)", "observed_at": "2026-11-07T21:50",
             "value": 0.06, "unit": "m", "threshold": 0.10, "note": null}
          ],
          "actions": ["물가에서 떨어지기", "높은 곳으로 이동 준비"],
          "disclaimer": "판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.",
          "source": "자료: 한강홍수통제소, 기상청",
          "subscribed": true, "stale": false
        }
        """)

        #expect(detail.level == .caution)
        #expect(detail.aiExplanation == "상류 관측소의 1시간 강수가 기준을 넘었어요.")
        #expect(detail.isAIFallback == false)
        #expect(detail.actions == ["물가에서 떨어지기", "높은 곳으로 이동 준비"])
        #expect(detail.disclaimer.isEmpty == false)
        #expect(detail.isSubscribed == true)

        try #require(detail.observations.count == 2)
        let rain = detail.observations[0]
        #expect(rain.kind == .rainLastHour)
        #expect(rain.value == 18.0)
        #expect(rain.unit == "mm")
        #expect(rain.threshold == 15.0)
        #expect(rain.note == nil)
        #expect(detail.observations[1].kind == .waterRise30Min)
    }

    @Test func missingValuesStayNilWithReason() throws {
        let detail = try decode("""
        {
          "updated_at": "2026-11-07T22:00", "id": 2, "name": "갑천 계곡",
          "level": "unknown", "summary": "지금은 판단할 수 없어요",
          "ai_explanation": null, "ai_fallback": true,
          "observations": [
            {"type": "water_rise_30m", "station": "횡성(갑천)", "observed_at": null,
             "value": null, "unit": "m", "threshold": null, "note": "수위 결측"}
          ],
          "actions": [], "disclaimer": "면책", "source": "자료",
          "subscribed": false, "stale": true
        }
        """)

        #expect(detail.level == .unknown)
        #expect(detail.aiExplanation == nil)
        #expect(detail.isAIFallback == true)
        let water = try #require(detail.observations.first)
        #expect(water.value == nil)
        #expect(water.observedAt == nil)
        #expect(water.threshold == nil)
        #expect(water.note == "수위 결측")
    }

    @Test func emptyObservationsAreAllowed() throws {
        let detail = try decode("""
        {
          "updated_at": "2026-11-07T22:00", "id": 1, "name": "금대리 계곡",
          "level": "safe", "summary": "지금은 위험 신호가 없어요",
          "ai_explanation": null, "ai_fallback": true,
          "observations": [], "actions": ["상류 날씨 변화에 계속 주의하기"],
          "disclaimer": "면책", "source": "자료", "subscribed": false, "stale": false
        }
        """)

        #expect(detail.observations.isEmpty)
    }

    @Test func unrecognizedObservationTypeBecomesOther() throws {
        let observation = try JSONDecoder.yeoulmok().decode(ValleyObservation.self, from: Data("""
        {"type": "soil_moisture", "station": "새 관측소", "observed_at": "2026-11-07T21:50",
         "value": 0.3, "unit": "%", "threshold": null, "note": null}
        """.utf8))

        #expect(observation.kind == .other)
        #expect(observation.value == 0.3)
    }

    // MARK: AI estimate (API spec v0.4, #63)

    @Test func estimatedRiseObservationDecodes() throws {
        let observation = try JSONDecoder.yeoulmok().decode(ValleyObservation.self, from: Data("""
        {"type": "est_rise_3h", "station": "AI 추정(강수 기반)", "observed_at": "2026-11-07T21:10",
         "value": 0.04, "unit": "m", "threshold": 0.3, "note": null, "estimated": true}
        """.utf8))

        #expect(observation.kind == .estRise3h)
        #expect(observation.isEstimated)
        #expect(observation.value == 0.04)
        #expect(observation.threshold == 0.3)
    }

    @Test func missingEstimatedMeansMeasured() throws {
        // Answers before v0.4 (and saved copies) have no "estimated": a measured value.
        let observation = try JSONDecoder.yeoulmok().decode(ValleyObservation.self, from: Data("""
        {"type": "rain_1h", "station": "원주 신림(AWS)", "observed_at": "2026-11-07T21:50",
         "value": 18.0, "unit": "mm", "threshold": 15.0, "note": null}
        """.utf8))

        #expect(!observation.isEstimated)
    }

    @Test func detailEstimatedFlag() throws {
        let mock = try MockData.valleyDetails(bundle: .main)
        #expect(mock.first { $0.id == 2 }?.isEstimated == true)
        #expect(mock.first { $0.id == 1 }?.isEstimated == false)
        let estimate = try #require(mock.first { $0.id == 2 }?.observations.last)
        #expect(estimate.kind == .estRise3h)
        #expect(estimate.isEstimated)
    }

    @Test func savedDetailKeepsEstimatedFlag() throws {
        let detail = try #require(try MockData.valleyDetails(bundle: .main).first { $0.id == 2 })
        let data = try JSONEncoder.yeoulmok().encode(detail)
        let again = try JSONDecoder.yeoulmok().decode(ValleyDetail.self, from: data)
        #expect(again == detail)
    }
}
