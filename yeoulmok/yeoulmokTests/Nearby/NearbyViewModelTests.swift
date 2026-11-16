import CoreLocation
import Testing
@testable import yeoulmok

@MainActor
struct NearbyViewModelTests {
    @Test func firstVisitAsksForPermission() {
        let permission = FakeLocationPermission(.notDetermined)
        let viewModel = NearbyViewModel(permission: permission)

        viewModel.onAppear()

        #expect(viewModel.state == .askingPermission)
        #expect(permission.requestCount == 1)
    }

    @Test func doesNotAskAgainOnceAnswered() {
        for answered in [LocationAuthorization.allowed, .denied] {
            let permission = FakeLocationPermission(answered)
            NearbyViewModel(permission: permission).onAppear()
            #expect(permission.requestCount == 0, "\(answered)")
        }
    }

    @Test func answersChangeTheScreen() {
        let permission = FakeLocationPermission(.notDetermined)
        let viewModel = NearbyViewModel(permission: permission)
        viewModel.onAppear()

        permission.answer(.denied)
        #expect(viewModel.state == .denied)

        // Allowed later in the Settings app, then back to the app.
        permission.answer(.allowed)
        #expect(viewModel.state == .allowed)
    }

    @Test func startsFromTheCurrentAuthorization() {
        #expect(NearbyViewModel(permission: FakeLocationPermission(.allowed)).state == .allowed)
        #expect(NearbyViewModel(permission: FakeLocationPermission(.denied)).state == .denied)
    }

    @Test(arguments: [
        (CLAuthorizationStatus.notDetermined, LocationAuthorization.notDetermined),
        (.authorizedWhenInUse, .allowed),
        (.authorizedAlways, .allowed),
        (.denied, .denied),
        (.restricted, .denied),
    ])
    func systemStatusMapping(status: CLAuthorizationStatus, expected: LocationAuthorization) {
        #expect(SystemLocationPermission.authorization(for: status) == expected)
    }
}
