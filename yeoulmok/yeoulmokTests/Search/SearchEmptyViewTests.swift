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

    /// #96: with a filter the title names the place, and the message says to look elsewhere.
    @Test func titleWithFilterNamesThePlace() {
        #expect(SearchEmptyView.title(for: "설악", in: "횡성군") == "횡성군에는 '설악' 계곡이 없어요")
        #expect(SearchEmptyView.title(for: "", in: "제주") == "제주에는 계곡이 없어요")
        #expect(SearchEmptyView.title(for: "설악", in: nil) == SearchEmptyView.title(for: "설악"))
        #expect(SearchEmptyView.message(in: nil) == "계곡 이름을 다시 확인해 주세요.")
    }

    @Test func allShownCountsTheRows() {
        #expect(SearchListEnd.allShown(126) == "126곳 모두 봤어요")
    }
}
