import CoreLocation
import Foundation
import Testing
@testable import yeoulmok

/// APP-HOME-05 (#59): the home view model picks the featured valley and loads its detail.
/// Mock subscriptions: 1 금대리 (주의), 2 갑천 (판정 불가), 4 위험 예시 (위험).
@MainActor
struct HomeFeaturedTests {
    private let date = ServerDate.parse("2026-11-07T22:00")!

    private func summary(_ id: Int, _ level: ValleyLevel, kmNorth: Double) -> ValleySummary {
        ValleySummary(id: id, name: "계곡 \(id)", region: "지역", latitude: 37 + kmNorth / 111.0,
                      longitude: 128, level: level, rainLastHourMM: 1, waterRise30MinM: 0.01,
                      observedAt: date, isStale: false, isSubscribed: true)
    }

    @Test func mostUrgentMockValleyWithItsDetail() async throws {
        let viewModel = HomeViewModel(repository: try MockValleyRepository())

        await viewModel.load()

        #expect(viewModel.featured?.valley.id == 4)
        #expect(viewModel.featured?.reason == .mostUrgent)
        #expect(viewModel.featuredDetail?.id == 4)
        #expect(viewModel.featuredDetail?.observations.isEmpty == false)
    }

    @Test func failedDetailKeepsTheCardWithoutGauges() async {
        // StubRepository's list is every mock valley; home gets only the subscribed ones.
        let viewModel = HomeViewModel(repository: StubRepository(
            list: { _ in try await MockValleyRepository().subscribedValleys() },
            detail: { _ in throw URLError(.notConnectedToInternet) }))

        await viewModel.load()

        #expect(viewModel.featured?.valley.id == 4)
        #expect(viewModel.featuredDetail == nil)
    }

    @Test func noSubscriptionsNoCard() async {
        let empty = ValleyListResponse(updatedAt: date, source: "자료", valleys: [])
        let viewModel = HomeViewModel(repository: StubRepository(list: { _ in empty }))

        await viewModel.load()

        #expect(viewModel.featured == nil)
        #expect(viewModel.featuredDetail == nil)
    }

    @Test func homeNeverAsksForLocation() async throws {
        let permission = FakeLocationPermission(.notDetermined)
        let viewModel = HomeViewModel(repository: try MockValleyRepository(), location: permission)

        await viewModel.load()

        #expect(permission.requestCount == 0)
        #expect(permission.locationCount == 0)
        #expect(viewModel.featured?.distanceMeters == nil)
    }

    @Test func allowedLocationPicksTheClosestSafeValley() async {
        let list = ValleyListResponse(updatedAt: date, source: "자료",
                                      valleys: [summary(1, .safe, kmNorth: 30), summary(3, .safe, kmNorth: 2)])
        let permission = FakeLocationPermission(.allowed)
        permission.location = .success(.init(latitude: 37, longitude: 128))
        let viewModel = HomeViewModel(repository: StubRepository(list: { _ in list }), location: permission)

        await viewModel.load()

        #expect(viewModel.featured?.valley.id == 3)
        #expect(viewModel.featured?.reason == .closest)
        #expect(viewModel.featured?.distanceMeters != nil)
    }

    @Test func locationErrorFallsBackToHomeOrder() async {
        let list = ValleyListResponse(updatedAt: date, source: "자료",
                                      valleys: [summary(1, .safe, kmNorth: 30), summary(3, .safe, kmNorth: 2)])
        let permission = FakeLocationPermission(.allowed)
        permission.location = .failure(URLError(.timedOut))
        let viewModel = HomeViewModel(repository: StubRepository(list: { _ in list }), location: permission)

        await viewModel.load()

        #expect(viewModel.featured?.reason == .firstInList)
    }
}
