import CoreLocation
import Foundation
import Testing
@testable import yeoulmok

/// APP-NEAR-02 (#15): the closest valleys from `GET /valleys`, and the failure
/// rules of feature spec 3-1 (#16 · #17) on the nearby tab.
@MainActor
struct NearbyListTests {
    private let cache = ValleyCache(directory: FileManager.default.temporaryDirectory
        .appending(path: "NearbyListTests-\(UUID().uuidString)", directoryHint: .isDirectory))
    /// Mock valley 1 (금대리 계곡) and mock valley 5.
    private let atValley1 = CLLocationCoordinate2D(latitude: 37.278313, longitude: 128.019563)
    private let atValley5 = CLLocationCoordinate2D(latitude: 37.6, longitude: 128.3)
    private let mockTime = ServerDate.parse("2026-11-07T22:00")

    private func allowed(at location: CLLocationCoordinate2D) -> FakeLocationPermission {
        let permission = FakeLocationPermission(.allowed)
        permission.location = .success(location)
        return permission
    }

    private func ids(_ list: NearbyViewModel.ListState) -> [Int] {
        if case let .loaded(valleys, _) = list { valleys.map(\.id) } else { [] }
    }

    @Test func showsValleysClosestFirst() async {
        let viewModel = NearbyViewModel(permission: allowed(at: atValley1), repository: StubRepository())

        await viewModel.load()

        #expect(ids(viewModel.list) == [1, 3, 4, 2, 5])
        guard case let .loaded(valleys, source) = viewModel.list else { return }
        #expect(valleys.first?.distanceMeters ?? -1 < 1)
        #expect(source == "자료: 한강홍수통제소, 기상청")
        #expect(viewModel.offlineAsOf == nil)
    }

    @Test func refreshUsesTheNewLocation() async {
        let permission = allowed(at: atValley1)
        let viewModel = NearbyViewModel(permission: permission, repository: StubRepository())
        await viewModel.load()

        permission.location = .success(atValley5)
        await viewModel.load()

        #expect(ids(viewModel.list).first == 5)
        #expect(permission.locationCount == 2)
    }

    @Test func doesNothingWithoutPermission() async {
        for authorization in [LocationAuthorization.notDetermined, .denied] {
            let permission = FakeLocationPermission(authorization)
            let viewModel = NearbyViewModel(permission: permission, repository: StubRepository())

            await viewModel.load()

            #expect(permission.locationCount == 0, "\(authorization)")
            #expect(viewModel.list == .loading, "\(authorization)")
        }
    }

    @Test func noValleysOnTheServerIsEmpty() async throws {
        let empty = ValleyListResponse(updatedAt: try #require(mockTime), source: "자료: ", valleys: [])
        let viewModel = NearbyViewModel(permission: allowed(at: atValley1),
                                        repository: StubRepository(list: { _ in empty }))

        await viewModel.load()

        #expect(viewModel.list == .empty(source: "자료: "))
    }

    @Test func noLocationWithNothingShownIsAnError() async {
        let permission = FakeLocationPermission(.allowed)
        permission.location = .failure(CLError(.locationUnknown))
        let viewModel = NearbyViewModel(permission: permission, repository: StubRepository())

        await viewModel.load()

        #expect(viewModel.list == .failed(message: "현재 위치를 확인할 수 없어요"))
    }

    @Test func noLocationOnRefreshKeepsTheList() async {
        let permission = allowed(at: atValley1)
        let viewModel = NearbyViewModel(permission: permission, repository: StubRepository())
        await viewModel.load()
        let shown = viewModel.list

        permission.location = .failure(CLError(.locationUnknown))
        await viewModel.load()

        #expect(viewModel.list == shown)
        #expect(viewModel.offlineAsOf == nil, "the server was not asked, so no offline banner")
    }

    @Test func successSavesEveryValley() async throws {
        let viewModel = NearbyViewModel(permission: allowed(at: atValley1),
                                        repository: StubRepository(), cache: cache)

        await viewModel.load()

        let saved = try #require(await cache.allValleys())
        #expect(saved.valleys.map(\.id).sorted() == [1, 2, 3, 4, 5])
    }

    @Test func failedRefreshKeepsTheListWithItsTimeAndNewDistances() async {
        let permission = allowed(at: atValley1)
        let server = FakeServer()
        let viewModel = NearbyViewModel(permission: permission, repository: server.repository, cache: cache)
        await viewModel.load()

        server.isDown = true
        permission.location = .success(atValley5)
        await viewModel.load()

        #expect(ids(viewModel.list).first == 5, "distances from where the user is now")
        #expect(viewModel.offlineAsOf == mockTime)
    }

    @Test func failureAtLaunchShowsTheSavedValleysWithItsTime() async throws {
        await cache.saveAllValleys(try await MockValleyRepository().valleys(matching: nil))
        let server = FakeServer()
        server.isDown = true
        let viewModel = NearbyViewModel(permission: allowed(at: atValley5),
                                        repository: server.repository, cache: cache)

        await viewModel.load()

        #expect(ids(viewModel.list).first == 5)
        #expect(viewModel.offlineAsOf == mockTime)
    }

    @Test func failureWithNothingSavedIsTheErrorScreen() async {
        let server = FakeServer()
        server.isDown = true
        let viewModel = NearbyViewModel(permission: allowed(at: atValley1),
                                        repository: server.repository, cache: cache)

        await viewModel.load()

        #expect(viewModel.list == .failed(message: "연결할 수 없어요"))
        #expect(viewModel.offlineAsOf == nil)
    }

    @Test func serverErrorCodeDoesNotUseTheSavedValleys() async throws {
        await cache.saveAllValleys(try await MockValleyRepository().valleys(matching: nil))
        let failing = StubRepository(list: { _ in
            throw APIError(code: "INTERNAL", message: "잠시 후 다시 시도해 주세요")
        })
        let viewModel = NearbyViewModel(permission: allowed(at: atValley1), repository: failing, cache: cache)

        await viewModel.load()

        #expect(viewModel.list == .failed(message: "잠시 후 다시 시도해 주세요"))
    }

    @Test func successAfterBeingOfflineRemovesTheBanner() async {
        let server = FakeServer()
        let viewModel = NearbyViewModel(permission: allowed(at: atValley1),
                                        repository: server.repository, cache: cache)
        await viewModel.load()
        server.isDown = true
        await viewModel.load()
        #expect(viewModel.offlineAsOf != nil)

        server.isDown = false
        await viewModel.load()

        #expect(viewModel.offlineAsOf == nil)
    }
}

/// `GET /valleys` that can be switched off.
private final class FakeServer: @unchecked Sendable {
    private let lock = NSLock()
    private var down = false
    var isDown: Bool {
        get { lock.withLock { down } }
        set { lock.withLock { down = newValue } }
    }

    var repository: StubRepository {
        StubRepository(list: { [self] query in
            if isDown { throw URLError(.notConnectedToInternet) }
            return try await MockValleyRepository().valleys(matching: query)
        })
    }
}
