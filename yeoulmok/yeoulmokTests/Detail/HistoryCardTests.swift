import Foundation
import Testing
@testable import yeoulmok

/// APP-DTL-09 (#90): the "최근 3시간" card, the level marks on the gauge, and loading
/// the history next to the detail.
@MainActor
struct HistoryCardTests {
    private static func point(_ time: String, rain: Double?, water: Double?) -> HistoryPoint {
        HistoryPoint(at: ServerDate.parse("2026-11-20T\(time)")!, rainLastHourMM: rain,
                     waterLevelM: water, waterRise30MinM: nil, level: nil)
    }

    private static func history(_ points: [HistoryPoint], hasWater: Bool = true) -> ValleyHistory {
        ValleyHistory(updatedAt: ServerDate.parse("2026-11-20T10:35")!, valleyID: 1, hours: 3,
                      stepMinutes: 10, hasWater: hasWater,
                      thresholds: HistoryThresholds(rainLastHour: nil, waterRise30Min: nil),
                      points: points, source: "자료")
    }

    // MARK: Chart math

    /// A missing value breaks the line instead of being drawn as 0.
    @Test func missingValueSplitsTheLine() {
        let points = [Self.point("10:00", rain: 0, water: 0.2), Self.point("10:10", rain: nil, water: nil),
                      Self.point("10:20", rain: 1, water: 0.3), Self.point("10:30", rain: 2, water: 0.4)]

        let segments = HistoryChartMath.segments(points, \.waterLevelM)

        #expect(segments.map { $0.map(\.value) } == [[0.2], [0.3, 0.4]])
        #expect(HistoryChartMath.values(points, \.rainLastHourMM).map(\.value) == [0, 1, 2])
    }

    /// The rain scale stops just above the next limit not yet reached.
    @Test(arguments: [(0.0, 15.0), (18.0, 25.0), (32.5, 40.0), (55.0, 55.0)] as [(Double, Double)])
    func rainScaleShowsTheNextLimit(maxValue: Double, shownUpTo: Double) {
        let steps: [(level: ValleyLevel, value: Double)] = [(.caution, 15), (.danger, 25), (.evacuate, 40)]
        let top = HistoryChartMath.scaleTop(maxValue: maxValue, steps: steps)
        #expect(abs(top - shownUpTo * 1.15) < 0.0001)
    }

    @Test func rainScaleWithoutLimits() {
        #expect(HistoryChartMath.scaleTop(maxValue: 0, steps: []) == 1)
        #expect(HistoryChartMath.scaleTop(maxValue: 10, steps: []) == 10 * 1.15)
    }

    /// Times are Korean time whatever the phone's time zone.
    @Test func timeLabelIsKoreanTime() {
        #expect(HistoryChartMath.timeLabel(ServerDate.parse("2026-11-20T21:00")!) == "21:00")
    }

    @Test func waterIsHiddenWithoutGaugeOrValues() {
        let withWater = Self.history([Self.point("10:00", rain: 0, water: 0.2)])
        let noGauge = Self.history([Self.point("10:00", rain: 0, water: nil)], hasWater: false)
        let noValues = Self.history([Self.point("10:00", rain: 0, water: nil)])

        #expect(HistoryChartMath.hasWater(withWater))
        #expect(!HistoryChartMath.hasWater(noGauge))
        #expect(!HistoryChartMath.hasWater(noValues))
    }

    /// #107: a window of only 0s gets the "no rain now" line; a gap or any rain does not.
    @Test func allZeroRainIsOnlyKnownZeros() {
        let at = Date(timeIntervalSince1970: 0)
        let zero = HistoryChartMath.Item(at: at, value: 0)
        #expect(HistoryChartMath.isAllZero([zero, zero]))
        #expect(!HistoryChartMath.isAllZero([]))   // nothing known is not "no rain"
        #expect(!HistoryChartMath.isAllZero([zero, HistoryChartMath.Item(at: at, value: 0.2)]))
    }

    /// #107: each card reads its own chart after its sentence.
    @Test func eachCardSaysItsOwnRange() throws {
        let history = try #require(try MockData.valleyHistories().first { $0.valleyID == 1 })
        #expect(HistoryChartMath.rainSpoken(history) == "최근 3시간 0.0mm에서 18.0mm")
        #expect(HistoryChartMath.waterSpoken(history) == "최근 3시간 수위 0.21m에서 0.34m")
    }

    @Test func accessibilityTextSaysFirstAndLastValues() {
        let history = Self.history([Self.point("10:00", rain: 0, water: 0.21), Self.point("10:10", rain: nil, water: nil),
                                    Self.point("10:20", rain: 18, water: 0.34)])
        #expect(HistoryChartMath.accessibilityText(history)
            == "최근 3시간, 강수 1시간 0.0mm에서 18.0mm, 수위 0.21m에서 0.34m")
        let noGauge = Self.history([Self.point("10:00", rain: nil, water: nil)], hasWater: false)
        #expect(HistoryChartMath.accessibilityText(noGauge) == "최근 3시간, 강수 1시간 -")
    }

    // MARK: Gauge level marks

    /// Without level limits the bar is unchanged: 1.5× the threshold.
    @Test func gaugeWithoutStagesIsUnchanged() {
        #expect(GaugeMath.scale(threshold: 15, stages: []) == 22.5)
        #expect(GaugeMath.fill(value: 15, threshold: 15, stages: []) == GaugeMath.fill(value: 15, threshold: 15))
    }

    /// With limits the bar reaches a bit past the highest, so every mark fits.
    @Test func gaugeWithStagesFitsEveryMark() {
        let stages = [15.0, 25.0, 40.0]
        #expect(GaugeMath.scale(threshold: 15, stages: stages) == 44)
        #expect(GaugeMath.position(40, threshold: 15, stages: stages) < 1)
        #expect(GaugeMath.position(15, threshold: 15, stages: stages) == 15.0 / 44)
        #expect(GaugeMath.fill(value: 100, threshold: 15, stages: stages) == 1)
    }

    // MARK: Loading

    @Test func loadGetsTheHistoryToo() async {
        let viewModel = ValleyDetailViewModel(valleyID: 4, repository: StubRepository())

        await viewModel.load()

        #expect(viewModel.history?.valleyID == 4)
        #expect(viewModel.history?.points.count == 19)
    }

    /// The history is extra: failing to get it keeps the detail and hides the card.
    @Test func historyFailureOnlyHidesTheCard() async {
        let repository = StubRepository(history: { _, _ in throw URLError(.badServerResponse) })
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: repository)

        await viewModel.load()

        #expect(viewModel.history == nil)
        guard case .loaded = viewModel.state else {
            Issue.record("expected .loaded, got \(viewModel.state)")
            return
        }
    }

    /// A failed refresh keeps the history already shown.
    @Test func failedRefreshKeepsTheShownHistory() async {
        let fails = Flag()
        let repository = StubRepository(history: { id, hours in
            if await fails.isOn { throw URLError(.notConnectedToInternet) }
            return try await MockValleyRepository().history(valleyID: id, hours: hours)
        })
        let viewModel = ValleyDetailViewModel(valleyID: 1, repository: repository)
        await viewModel.load()
        await fails.turnOn()

        await viewModel.load()

        #expect(viewModel.history?.valleyID == 1)
    }

    @Test func asksForThreeHours() async {
        let hours = Recorder()
        let repository = StubRepository(history: { id, hoursAsked in
            await hours.record(hoursAsked)
            return try await MockValleyRepository().history(valleyID: id, hours: hoursAsked)
        })

        await ValleyDetailViewModel(valleyID: 1, repository: repository).load()

        #expect(await hours.values == [3])
    }
}

private actor Flag {
    private(set) var isOn = false
    func turnOn() { isOn = true }
}

private actor Recorder {
    private(set) var values: [Int] = []
    func record(_ value: Int) { values.append(value) }
}
