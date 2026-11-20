import Testing
@testable import yeoulmok

@MainActor
struct ValleyCardTests {
    private func valley(rain: Double?, rise: Double?) -> ValleySummary {
        ValleySummary(
            id: 1, name: "금대리 계곡", region: "원주시 판부면", latitude: 37, longitude: 128,
            level: .caution, rainLastHourMM: rain, waterRise30MinM: rise, observedAt: nil,
            isStale: false, isSubscribed: true
        )
    }

    @Test func observationTextMatchesFigma() {
        #expect(ValleyCard.observationText(for: valley(rain: 18.0, rise: 0.22))
            == "상류 1시간 강수 18.0mm · 하류 30분 상승 +0.22m")
    }

    @Test func zeroValuesStayZero() {
        #expect(ValleyCard.observationText(for: valley(rain: 0, rise: 0))
            == "상류 1시간 강수 0.0mm · 하류 30분 상승 +0.00m")
    }

    @Test func missingValuesShowDashWithoutUnit() {
        #expect(ValleyCard.observationText(for: valley(rain: nil, rise: nil))
            == "상류 1시간 강수 - · 하류 30분 상승 -")
    }
}
