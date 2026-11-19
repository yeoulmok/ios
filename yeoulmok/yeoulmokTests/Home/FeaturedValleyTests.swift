import CoreLocation
import Testing
@testable import yeoulmok

/// APP-HOME-05 (#59): which subscribed valley is shown large on home.
/// The rule was decided by a person on 2026-11-19; these tests pin it down.
struct FeaturedValleyTests {
    /// The user stands at (37, 128). A valley `km` kilometers north of that.
    private func valley(_ id: Int, _ level: ValleyLevel, kmNorth km: Double = 1,
                        name: String? = nil) -> ValleySummary {
        ValleySummary(
            id: id, name: name ?? "계곡 \(id)", region: "지역",
            latitude: 37 + km / 111.0, longitude: 128, level: level,
            rainLastHourMM: nil, waterRise30MinM: nil, observedAt: nil,
            isStale: false, isSubscribed: true
        )
    }

    private let user = CLLocationCoordinate2D(latitude: 37, longitude: 128)

    @Test func nothingSubscribedMeansNoCard() {
        #expect(FeaturedValley.pick(from: [], near: user) == nil)
        #expect(FeaturedValley.pick(from: [], near: nil) == nil)
    }

    // Rule 1: 주의 or higher, the highest level.

    @Test func highestLevelWinsEvenIfFarther() {
        let picked = FeaturedValley.pick(
            from: [valley(1, .caution, kmNorth: 1), valley(2, .evacuate, kmNorth: 50), valley(3, .danger, kmNorth: 2)],
            near: user)
        #expect(picked?.valley.id == 2)
        #expect(picked?.reason == .mostUrgent)
    }

    @Test func sameLevelPicksTheCloserOne() {
        let picked = FeaturedValley.pick(
            from: [valley(1, .danger, kmNorth: 30), valley(2, .danger, kmNorth: 3)], near: user)
        #expect(picked?.valley.id == 2)
    }

    @Test func sameLevelWithoutLocationUsesHomeOrder() {
        let picked = FeaturedValley.pick(
            from: [valley(1, .danger, name: "하늘 계곡"), valley(2, .danger, name: "가람 계곡")], near: nil)
        #expect(picked?.valley.id == 2)
        #expect(picked?.reason == .mostUrgent)
        #expect(picked?.distanceMeters == nil)
    }

    @Test func cautionCountsAsUrgent() {
        let picked = FeaturedValley.pick(
            from: [valley(1, .safe, kmNorth: 1), valley(2, .caution, kmNorth: 40)], near: user)
        #expect(picked?.valley.id == 2)
        #expect(picked?.reason == .mostUrgent)
    }

    @Test func unknownIsNotUrgent() {
        // 판정 불가 is missing data, not a higher risk: the closest valley wins.
        let picked = FeaturedValley.pick(
            from: [valley(1, .unknown, kmNorth: 40), valley(2, .safe, kmNorth: 1)], near: user)
        #expect(picked?.valley.id == 2)
        #expect(picked?.reason == .closest)
    }

    // Rule 2: no valley at 주의 or higher, the closest.

    @Test func closestWhenNothingIsUrgent() {
        let picked = FeaturedValley.pick(
            from: [valley(1, .safe, kmNorth: 20), valley(2, .safe, kmNorth: 5), valley(3, .unknown, kmNorth: 9)],
            near: user)
        #expect(picked?.valley.id == 2)
        #expect(picked?.reason == .closest)
        let meters = try? #require(picked?.distanceMeters)
        #expect(abs((meters ?? 0) - 5_000) < 50)
    }

    @Test func closestCanBeUnknown() {
        let picked = FeaturedValley.pick(
            from: [valley(1, .unknown, kmNorth: 1), valley(2, .safe, kmNorth: 9)], near: user)
        #expect(picked?.valley.id == 1)
    }

    // Rule 3: no location, the top of the home list.

    @Test func withoutLocationUnknownRanksAboveSafe() {
        let picked = FeaturedValley.pick(
            from: [valley(1, .safe, name: "가람 계곡"), valley(2, .unknown, name: "하늘 계곡")], near: nil)
        #expect(picked?.valley.id == 2)
        #expect(picked?.reason == .firstInList)
    }

    @Test func oneSubscriptionIsAlwaysShown() {
        let picked = FeaturedValley.pick(from: [valley(7, .safe)], near: nil)
        #expect(picked?.valley.id == 7)
    }

    @Test func reasonTitles() {
        #expect(FeaturedValley.Reason.mostUrgent.title == "가장 위험한 구독 계곡")
        #expect(FeaturedValley.Reason.closest.title == "가장 가까운 구독 계곡")
        #expect(FeaturedValley.Reason.firstInList.title == "구독한 계곡")
    }
}
