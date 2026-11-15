import Foundation
import Testing
@testable import yeoulmok

struct ValleyCacheTests {
    /// Each test gets its own empty folder.
    private let cache = ValleyCache(directory: FileManager.default.temporaryDirectory
        .appending(path: "ValleyCacheTests-\(UUID().uuidString)", directoryHint: .isDirectory))

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

    @Test func timesAreSavedInTheServerFormat() throws {
        let date = try #require(ServerDate.parse("2026-11-07T22:00"))
        #expect(ServerDate.string(from: date) == "2026-11-07T22:00:00")
        #expect(ServerDate.parse(ServerDate.string(from: date)) == date)
    }
}
