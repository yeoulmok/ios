import CoreLocation
import Testing
@testable import yeoulmok

struct NearbyValleysTests {
    /// The user stands at (37, 128). A valley `km` kilometers north of that.
    private func valley(_ id: Int, kmNorth km: Double) -> ValleySummary {
        ValleySummary(
            id: id, name: "계곡 \(id)", region: "지역",
            latitude: 37 + km / 111.0, longitude: 128, level: .safe,
            rainLastHourMM: nil, waterRise30MinM: nil, observedAt: nil,
            isStale: false, isSubscribed: false
        )
    }

    private let user = CLLocationCoordinate2D(latitude: 37, longitude: 128)

    @Test func closestFirstAndOnlyFive() {
        let valleys = [valley(1, kmNorth: 30), valley(2, kmNorth: 2), valley(3, kmNorth: 50),
                       valley(4, kmNorth: 10), valley(5, kmNorth: 1), valley(6, kmNorth: 20)]

        let nearby = NearbyValleys.closest(to: user, in: valleys)

        #expect(nearby.map(\.id) == [5, 2, 4, 6, 1])
    }

    @Test func noRadiusLimit() {
        // Feature spec 6: far valleys are still shown when they are among the closest five.
        let nearby = NearbyValleys.closest(to: user, in: [valley(1, kmNorth: 300)])
        #expect(nearby.map(\.id) == [1])
    }

    @Test func fewerThanFiveShowsAll() {
        let nearby = NearbyValleys.closest(to: user, in: [valley(1, kmNorth: 3), valley(2, kmNorth: 1)])
        #expect(nearby.map(\.id) == [2, 1])
    }

    @Test func noValleysMeansEmpty() {
        #expect(NearbyValleys.closest(to: user, in: []).isEmpty)
    }

    @Test func sameDistanceKeepsOrderById() {
        let nearby = NearbyValleys.closest(to: user, in: [valley(9, kmNorth: 5), valley(3, kmNorth: 5)])
        #expect(nearby.map(\.id) == [3, 9])
    }

    @Test func distanceIsInMeters() throws {
        // About 11.1 km for 0.1° of latitude; allow 1% for the earth's shape.
        let nearby = NearbyValleys.closest(to: user, in: [valley(1, kmNorth: 11.1)])
        let meters = try #require(nearby.first?.distanceMeters)
        #expect(abs(meters - 11_100) < 111)
    }

    @Test func sameInputAlwaysGivesTheSameDistance() {
        // CLLocation.distance(from:) did not (see NearbyValleys.distanceMeters).
        let wonju = CLLocationCoordinate2D(latitude: 37.3422, longitude: 127.9202)
        let gapcheon = CLLocationCoordinate2D(latitude: 37.548, longitude: 128.104)
        let first = NearbyValleys.distanceMeters(from: wonju, to: gapcheon)
        for _ in 0..<100 {
            #expect(NearbyValleys.distanceMeters(from: wonju, to: gapcheon) == first)
        }
    }

    @Test func oneDegreeOfLatitudeIsAbout111Km() {
        let meters = NearbyValleys.distanceMeters(from: .init(latitude: 37, longitude: 128),
                                                  to: .init(latitude: 38, longitude: 128))
        #expect(abs(meters - 111_195) < 1)
    }

    @Test(arguments: [
        (1_234.0, "1.2km"),
        (400.0, "0.4km"),
        (12_345.0, "12.3km"),
        (0.0, "0.0km"),
    ])
    func distanceText(meters: Double, expected: String) {
        #expect(NearbyValleys.distanceText(meters: meters) == expected)
    }
}
