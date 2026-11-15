import Testing
@testable import yeoulmok

@MainActor
struct SearchEmptyViewTests {
    @Test func titleQuotesTheQuery() {
        #expect(SearchEmptyView.title(for: "설악") == "'설악'에 해당하는 계곡이 없어요")
    }

    @Test func titleWithoutQueryHasNoEmptyQuotes() {
        #expect(SearchEmptyView.title(for: "") == "해당하는 계곡이 없어요")
    }
}
