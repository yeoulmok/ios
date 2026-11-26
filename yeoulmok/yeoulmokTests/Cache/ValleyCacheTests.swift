import Foundation
import Testing
@testable import yeoulmok

struct ValleyCacheTests {
    /// Each test gets its own empty folder.
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "ValleyCacheTests-\(UUID().uuidString)", directoryHint: .isDirectory)
    private let cache: ValleyCache

    init() {
        cache = ValleyCache(directory: directory)
    }

    @Test func nothingSavedIsNil() async {
        #expect(await cache.subscribedValleys() == nil)
        #expect(await cache.detail(id: 1) == nil)
    }

    @Test func savedListReadsBackUnchanged() async throws {
        let list = try MockData.valleyList()

        await cache.saveSubscribedValleys(list)

        // Same values, including Korean times, missing values (nil) and unknown levels.
        #expect(await cache.subscribedValleys() == list)
    }

    @Test func savedDetailsAreKeptPerValley() async throws {
        let details = try MockData.valleyDetails()
        for detail in details {
            await cache.saveDetail(detail)
        }

        for detail in details {
            #expect(await cache.detail(id: detail.id) == detail)
        }
        #expect(await cache.detail(id: 99) == nil)
    }

    @Test func savingAgainReplacesTheOldCopy() async throws {
        let list = try MockData.valleyList()
        await cache.saveSubscribedValleys(list)
        let newer = ValleyListResponse(updatedAt: list.updatedAt.addingTimeInterval(600),
                                       source: list.source, valleys: [])

        await cache.saveSubscribedValleys(newer)

        #expect(await cache.subscribedValleys() == newer)
    }

    // MARK: Writing only what changed (#103)

    private func modified(_ name: String) throws -> Date {
        let attributes = try FileManager.default.attributesOfItem(
            atPath: directory.appending(path: name).path(percentEncoded: false))
        return try #require(attributes[.modificationDate] as? Date)
    }

    @Test func sameContentIsNotWrittenAgain() async throws {
        let detail = try #require(try MockData.valleyDetails().first)
        await cache.saveDetail(detail)
        let first = try modified("detail-\(detail.id).json")
        try await Task.sleep(for: .milliseconds(50))

        await cache.saveDetail(detail)

        #expect(try modified("detail-\(detail.id).json") == first)
    }

    /// Subscribing changes the detail but not its `updated_at`: still written.
    @Test func changedSubscriptionIsWritten() async throws {
        var detail = try #require(try MockData.valleyDetails().first)
        await cache.saveDetail(detail)
        let first = try modified("detail-\(detail.id).json")
        try await Task.sleep(for: .milliseconds(50))

        detail.isSubscribed.toggle()
        await cache.saveDetail(detail)

        #expect(try modified("detail-\(detail.id).json") > first)
        #expect(await cache.detail(id: detail.id)?.isSubscribed == detail.isSubscribed)
    }

    /// iOS may empty Caches while the app runs: the same answer is written again.
    @Test func removedFileIsWrittenAgain() async throws {
        let list = try MockData.valleyList()
        await cache.saveSubscribedValleys(list)
        try FileManager.default.removeItem(at: directory.appending(path: "subscribed.json"))

        await cache.saveSubscribedValleys(list)

        #expect(await cache.subscribedValleys() == list)
    }

    @Test func timesAreSavedInTheServerFormat() throws {
        let date = try #require(ServerDate.parse("2026-11-07T22:00"))
        #expect(ServerDate.string(from: date) == "2026-11-07T22:00:00")
        #expect(ServerDate.parse(ServerDate.string(from: date)) == date)
    }
}
