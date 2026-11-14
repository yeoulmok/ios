import Foundation
import Testing
@testable import yeoulmok

struct MockDataTests {
    @Test func listCoversEveryLevel() throws {
        let levels = Set(try MockData.valleyList().valleys.map(\.level))
        #expect(levels == Set(ValleyLevel.allCases))
    }

    @Test func listCoversScreenStates() throws {
        let valleys = try MockData.valleyList().valleys

        // Stale but still judged (15–30 min old): "자료 지연" is shown.
        #expect(valleys.contains { $0.isStale && $0.level != .unknown })
        // No data at all: "-" is shown, never 0.
        #expect(valleys.contains { $0.rainLastHourMM == nil && $0.observedAt == nil })
        // Real zero rainfall, to tell apart from nil.
        #expect(valleys.contains { $0.rainLastHourMM == 0 })
        // Both subscribed and not subscribed, for the home list and the toggle.
        #expect(valleys.contains { $0.isSubscribed })
        #expect(valleys.contains { !$0.isSubscribed })
    }

    @Test func unknownValleysAreAlwaysStale() throws {
        // Mirrors the server: an unknown level always comes with stale: true.
        let valleys = try MockData.valleyList().valleys
        for valley in valleys where valley.level == .unknown {
            #expect(valley.isStale, "valley \(valley.id)")
        }
    }

    @Test func everyListedValleyHasMatchingDetail() throws {
        let valleys = try MockData.valleyList().valleys
        let details = Dictionary(uniqueKeysWithValues: try MockData.valleyDetails().map { ($0.id, $0) })

        #expect(details.count == valleys.count)
        for valley in valleys {
            let detail = try #require(details[valley.id], "no detail for valley \(valley.id)")
            #expect(detail.name == valley.name)
            #expect(detail.level == valley.level)
            #expect(detail.isStale == valley.isStale)
            #expect(detail.isSubscribed == valley.isSubscribed)
        }
    }

    @Test func detailsCoverMissingAIExplanationAndMissingValue() throws {
        let details = try MockData.valleyDetails()
        #expect(details.contains { $0.aiExplanation == nil })
        #expect(details.contains { $0.aiExplanation != nil })
        #expect(details.contains { detail in
            detail.observations.contains { $0.value == nil && $0.note != nil }
        })
    }

    @Test func missingFileThrows() {
        #expect(throws: MockData.LoadError.fileNotFound("nope")) {
            try MockData.load(ValleyListResponse.self, from: "nope")
        }
    }
}
