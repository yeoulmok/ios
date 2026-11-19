import CoreLocation
import MapKit
import Testing
@testable import yeoulmok

/// APP-NEAR-03 (#58): the first map area holds the user and every valley on the list.
struct NearbyMapRegionTests {
    private let user = CLLocationCoordinate2D(latitude: 37.0, longitude: 128.0)

    private func contains(_ region: MKCoordinateRegionLike, _ point: CLLocationCoordinate2D) -> Bool {
        abs(point.latitude - region.centerLat) <= region.latDelta / 2
            && abs(point.longitude - region.centerLon) <= region.lonDelta / 2
    }

    @Test func holdsTheUserAndEveryValley() {
        let valleys = [CLLocationCoordinate2D(latitude: 37.3, longitude: 127.8),
                       CLLocationCoordinate2D(latitude: 36.9, longitude: 128.4)]

        let region = MKCoordinateRegionLike(NearbyMapRegion.fitting(user: user, valleys: valleys))

        #expect(contains(region, user))
        for valley in valleys {
            #expect(contains(region, valley))
        }
    }

    @Test func leavesRoomAroundThePoints() {
        let valley = CLLocationCoordinate2D(latitude: 37.5, longitude: 129.0)

        let region = MKCoordinateRegionLike(NearbyMapRegion.fitting(user: user, valleys: [valley]))

        #expect(abs(region.latDelta - 0.5 * NearbyMapRegion.padding) < 1e-9)
        #expect(abs(region.lonDelta - 1.0 * NearbyMapRegion.padding) < 1e-9)
        #expect(abs(region.centerLat - 37.25) < 1e-9)
        #expect(abs(region.centerLon - 128.5) < 1e-9)
    }

    @Test func veryCloseValleyStillShowsAnArea() {
        let valley = CLLocationCoordinate2D(latitude: 37.0001, longitude: 128.0001)

        let region = MKCoordinateRegionLike(NearbyMapRegion.fitting(user: user, valleys: [valley]))

        #expect(region.latDelta == NearbyMapRegion.minimumSpan)
        #expect(region.lonDelta == NearbyMapRegion.minimumSpan)
    }

    @Test func noValleysCentersOnTheUser() {
        let region = MKCoordinateRegionLike(NearbyMapRegion.fitting(user: user, valleys: []))

        #expect(region.centerLat == user.latitude)
        #expect(region.centerLon == user.longitude)
        #expect(region.latDelta == NearbyMapRegion.minimumSpan)
    }
}

/// Plain numbers from `MKCoordinateRegion`, easier to compare in tests.
struct MKCoordinateRegionLike {
    let centerLat, centerLon, latDelta, lonDelta: Double

    init(_ region: MKCoordinateRegion) {
        centerLat = region.center.latitude
        centerLon = region.center.longitude
        latDelta = region.span.latitudeDelta
        lonDelta = region.span.longitudeDelta
    }
}
