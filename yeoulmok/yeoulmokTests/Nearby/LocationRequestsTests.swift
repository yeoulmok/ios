import CoreLocation
import Testing
@testable import yeoulmok

@MainActor
struct LocationRequestsTests {
    private struct Failure: Error {}
    private let here = CLLocationCoordinate2D(latitude: 37.3, longitude: 127.9)

    /// Lets started tasks reach `wait` before the test answers.
    private func waitUntil(_ requests: LocationRequests, has count: Int) async {
        for _ in 0..<1_000 where requests.waitingCount < count {
            await Task.yield()
        }
    }

    @Test func oneCallerGetsTheLocation() async throws {
        let requests = LocationRequests()
        var starts = 0
        let task = Task { try await requests.wait { starts += 1 } }
        await waitUntil(requests, has: 1)

        requests.finish(.success(here))

        let location = try await task.value
        #expect(location.latitude == here.latitude && location.longitude == here.longitude)
        #expect(starts == 1)
    }

    @Test func callersAtTheSameTimeShareOneRequest() async throws {
        let requests = LocationRequests()
        var starts = 0
        let first = Task { try await requests.wait { starts += 1 } }
        let second = Task { try await requests.wait { starts += 1 } }
        await waitUntil(requests, has: 2)

        requests.finish(.success(here))

        #expect(try await first.value.latitude == here.latitude)
        #expect(try await second.value.latitude == here.latitude)
        #expect(starts == 1)
    }

    @Test func failureReachesEveryCaller() async {
        let requests = LocationRequests()
        let first = Task { try await requests.wait {} }
        let second = Task { try await requests.wait {} }
        await waitUntil(requests, has: 2)

        requests.finish(.failure(Failure()))

        await #expect(throws: Failure.self) { try await first.value }
        await #expect(throws: Failure.self) { try await second.value }
    }

    @Test func askingAgainAfterAnAnswerStartsAgain() async throws {
        let requests = LocationRequests()
        var starts = 0
        let first = Task { try await requests.wait { starts += 1 } }
        await waitUntil(requests, has: 1)
        requests.finish(.success(here))
        _ = try await first.value

        let second = Task { try await requests.wait { starts += 1 } }
        await waitUntil(requests, has: 1)
        requests.finish(.success(here))
        _ = try await second.value

        #expect(starts == 2)
    }
}
