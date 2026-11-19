import Foundation
import Testing
@testable import yeoulmok

struct ObservationFormatTests {
    private static let observedAt = ServerDate.parse("2026-11-07T21:50")
    private static let now = ServerDate.parse("2026-11-07T22:00")!

    private static func observation(
        _ kind: ObservationKind, station: String = "원주 신림(AWS)", observedAt: Date? = observedAt,
        value: Double?, unit: String = "mm", threshold: Double? = 15, note: String? = nil
    ) -> ValleyObservation {
        ValleyObservation(kind: kind, station: station, observedAt: observedAt, value: value,
                          unit: unit, threshold: threshold, note: note)
    }

    @Test func rainShowsAllFourLines() {
        let rain = Self.observation(.rainLastHour, value: 18)

        #expect(ObservationFormat.station(rain) == "원주 신림(AWS) (강수)")
        #expect(ObservationFormat.time(rain, now: Self.now) == "21:50")
        #expect(ObservationFormat.value(rain) == "18.0mm / 1시간")
        #expect(ObservationFormat.threshold(rain) == "15.0mm / 1시간")
    }

    @Test func waterRiseHasSignButLimitDoesNot() {
        let water = Self.observation(.waterRise30Min, station: "원주시(동부교)", value: 0.06, unit: "m", threshold: 0.1)

        #expect(ObservationFormat.station(water) == "원주시(동부교) (수위)")
        #expect(ObservationFormat.value(water) == "+0.06m / 30분")
        #expect(ObservationFormat.threshold(water) == "0.10m / 30분")
    }

    @Test func zeroIsShownAsZero() {
        // 0 mm means "no rain": a real value, unlike nil.
        #expect(ObservationFormat.value(Self.observation(.rainLastHour, value: 0)) == "0.0mm / 1시간")
        #expect(ObservationFormat.value(Self.observation(.waterRise30Min, value: 0, unit: "m")) == "0.00m / 30분")
    }

    @Test func missingValueIsDashNeverZero() {
        let missing = Self.observation(.rainLastHour, observedAt: nil, value: nil)

        #expect(ObservationFormat.value(missing) == "-")
        #expect(ObservationFormat.time(missing, now: Self.now) == "-")
        #expect(!ObservationFormat.value(missing).contains("0"))
    }

    @Test func missingValueShowsTheServersReason() {
        let missing = Self.observation(.waterRise30Min, value: nil, unit: "m", note: "수위 결측")

        #expect(ObservationFormat.value(missing) == "- (수위 결측)")
    }

    @Test func emptyNoteIsIgnored() {
        #expect(ObservationFormat.value(Self.observation(.rainLastHour, value: nil, note: "")) == "-")
    }

    @Test func missingLimitIsDash() {
        #expect(ObservationFormat.threshold(Self.observation(.rainLastHour, value: 18, threshold: nil)) == "-")
    }

    @Test func otherDayShowsDate() throws {
        let rain = Self.observation(.rainLastHour, value: 18)
        let nextDay = try #require(ServerDate.parse("2026-11-08T09:00"))

        #expect(ObservationFormat.time(rain, now: nextDay) == "11/7 21:50")
    }

    @Test func unknownKindShowsNumberWithServerUnit() {
        let other = Self.observation(.other, station: "새 관측소", value: 3.2, unit: "cm", threshold: 10)

        #expect(ObservationFormat.station(other) == "새 관측소")
        #expect(ObservationFormat.value(other) == "3.2cm")
        #expect(ObservationFormat.threshold(other) == "10cm")
    }

    @Test func voiceOverReadsTheWholeBox() {
        let rain = Self.observation(.rainLastHour, value: 18)

        #expect(ObservationFormat.accessibilityLabel(rain, now: Self.now)
                == "강수, 원주 신림(AWS), 관측 시각 21:50, 실측값 18.0mm / 1시간, 기준값 15.0mm / 1시간")
    }

    // MARK: AI estimate (#63)

    @Test func estimatedRiseReadsAsThreeHours() {
        let estimate = ValleyObservation(kind: .estRise3h, station: "AI 추정(강수 기반)",
                                         observedAt: nil, value: 0.04, unit: "m", threshold: 0.3,
                                         note: nil, isEstimated: true)
        #expect(ObservationFormat.value(estimate) == "+0.04m / 3시간")
        #expect(ObservationFormat.threshold(estimate) == "0.30m / 3시간")
        #expect(ObservationFormat.station(estimate) == "AI 추정(강수 기반) (AI 추정 수위)")
        #expect(ObservationFormat.accessibilityLabel(estimate).hasPrefix("AI 추정 수위, "))
    }
}
