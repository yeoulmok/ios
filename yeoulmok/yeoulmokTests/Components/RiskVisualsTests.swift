import Foundation
import Testing
@testable import yeoulmok

/// #59: the numbers behind the level scale, threshold gauge, change arrow and "○분 전".
struct RiskVisualsTests {
    // MARK: LevelScale

    @Test func scaleOrderIsSafeToEvacuate() {
        #expect(LevelScaleSteps.steps == [.safe, .caution, .danger, .evacuate])
        #expect(LevelScaleSteps.index(of: .danger) == 2)
    }

    @Test func unknownIsNotOnTheScale() {
        // 판정 불가 must never mark the 안전 segment.
        #expect(LevelScaleSteps.index(of: .unknown) == nil)
        for step in LevelScaleSteps.steps {
            #expect(!LevelScaleSteps.isCurrent(step, .unknown))
            #expect(!LevelScaleSteps.isPassed(step, .unknown))
        }
    }

    @Test func stepsBelowTheLevelArePassed() {
        #expect(LevelScaleSteps.isPassed(.safe, .danger))
        #expect(LevelScaleSteps.isPassed(.caution, .danger))
        #expect(!LevelScaleSteps.isPassed(.danger, .danger))
        #expect(!LevelScaleSteps.isPassed(.evacuate, .danger))
        #expect(LevelScaleSteps.isCurrent(.danger, .danger))
    }

    // MARK: GaugeMath

    @Test func thresholdSitsAtTwoThirds() {
        #expect(abs(GaugeMath.thresholdPosition - 2.0 / 3.0) < 1e-9)
        #expect(abs((GaugeMath.fill(value: 15, threshold: 15) ?? -1) - GaugeMath.thresholdPosition) < 1e-9)
    }

    @Test(arguments: [
        (0.0, 15.0, 0.0),
        (7.5, 15.0, 1.0 / 3.0),
        (45.0, 15.0, 1.0),
        (100.0, 15.0, 1.0),     // capped
        (-0.05, 0.10, 0.0),     // falling water fills nothing
    ])
    func fillFraction(value: Double, threshold: Double, expected: Double) {
        #expect(abs((GaugeMath.fill(value: value, threshold: threshold) ?? -1) - expected) < 1e-9)
    }

    @Test func missingValueDrawsNoBar() {
        // null is "unknown", not 0: no bar at all.
        #expect(GaugeMath.fill(value: nil, threshold: 15) == nil)
        #expect(GaugeMath.fill(value: 3, threshold: nil) == nil)
        #expect(GaugeMath.fill(value: 3, threshold: 0) == nil)
    }

    @Test func overMeansReachedTheThreshold() {
        #expect(GaugeMath.isOver(value: 15, threshold: 15))
        #expect(GaugeMath.isOver(value: 32.5, threshold: 15))
        #expect(!GaugeMath.isOver(value: 14.9, threshold: 15))
        #expect(!GaugeMath.isOver(value: nil, threshold: 15))
    }

    // MARK: ChangeDirection

    @Test(arguments: [
        (0.18, ChangeDirection.rising),
        (-0.07, ChangeDirection.falling),
        (0.004, ChangeDirection.steady),
        (0.0, ChangeDirection.steady),
    ])
    func direction(change: Double, expected: ChangeDirection) {
        #expect(ChangeDirection(change) == expected)
    }

    @Test func missingChangeShowsNoArrow() {
        #expect(ChangeDirection(nil) == nil)
    }

    // MARK: timeAgo

    @Test func timeAgo() {
        let now = ServerDate.parse("2026-11-19T21:00")!
        #expect(ValleyFormat.timeAgo(ServerDate.parse("2026-11-19T21:00"), now: now) == "방금 전")
        #expect(ValleyFormat.timeAgo(ServerDate.parse("2026-11-19T20:48"), now: now) == "12분 전")
        #expect(ValleyFormat.timeAgo(ServerDate.parse("2026-11-19T18:00"), now: now) == "3시간 전")
        #expect(ValleyFormat.timeAgo(ServerDate.parse("2026-11-17T09:30"), now: now) == "11/17 09:30")
        #expect(ValleyFormat.timeAgo(nil, now: now) == "-")
    }
}

/// #63: the detail's level card.
struct DetailLevelCardTests {
    @Test func latestObservationIgnoresAIEstimates() throws {
        let details = try MockData.valleyDetails(bundle: .main)
        // 금대리: both stations observed at 21:50.
        let geumdaeri = try #require(details.first { $0.id == 1 })
        #expect(DetailLevelCard.latestObservation(in: geumdaeri) == ServerDate.parse("2026-11-07T21:50"))
        // 갑천: no measured data; the AI estimate (21:10) does not count as observed.
        let gapcheon = try #require(details.first { $0.id == 2 })
        #expect(DetailLevelCard.latestObservation(in: gapcheon) == nil)
    }

    @Test func urgentLevels() {
        #expect(ValleyLevel.danger.isUrgent)
        #expect(ValleyLevel.evacuate.isUrgent)
        #expect(!ValleyLevel.caution.isUrgent)
        #expect(!ValleyLevel.unknown.isUrgent)
        #expect(!ValleyLevel.safe.isUrgent)
    }
}
