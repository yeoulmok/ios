import SwiftUI

/// "No results" in the search tab (Figma 02a). Without a filter there is no button: the
/// user just edits the search text. With a filter on (APP-SRCH-04, #96) the wording
/// names the place and "전체 지역에서 찾기" searches the same text everywhere.
/// Temporary wording for the filter case until QA (not in Figma).
struct SearchEmptyView: View {
    /// Trimmed search text; empty when the full list itself came back empty.
    let query: String
    let source: String
    /// The chosen province or city, e.g. "횡성군"; `nil` without a filter.
    var place: String? = nil
    /// "전체 지역에서 찾기". Shown only with `place`.
    var clearFilter: (() async -> Void)? = nil

    static let clearFilterTitle = "전체 지역에서 찾기"

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(Theme.Text.primary)
                .frame(width: 64, height: 64)
                .glassCard(cornerRadius: Theme.Radius.large)
                .accessibilityHidden(true)
            Text(Self.title(for: query, in: place))
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.Text.primary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            Text(Self.message(in: place))
                .font(.subheadline)
                .foregroundStyle(Theme.Text.body)
                .multilineTextAlignment(.center)
            if place != nil, let clearFilter {
                Button {
                    Task { await clearFilter() }
                } label: {
                    Text(Self.clearFilterTitle).secondaryButtonLabel()
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
                .padding(.horizontal, 40)
                .accessibilityIdentifier("search.clearFilter")
            }
            Spacer()
            SourceFooter(source: source)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }

    /// Figma 02a: "'{검색어}'에 해당하는 계곡이 없어요".
    /// Without a query (the server has no valleys at all) the quotes are dropped.
    static func title(for query: String) -> String {
        query.isEmpty ? "해당하는 계곡이 없어요" : "'\(query)'에 해당하는 계곡이 없어요"
    }

    /// With a filter: "횡성군에는 '설악' 계곡이 없어요" / "횡성군에는 계곡이 없어요".
    static func title(for query: String, in place: String?) -> String {
        guard let place else { return title(for: query) }
        return query.isEmpty ? "\(place)에는 계곡이 없어요" : "\(place)에는 '\(query)' 계곡이 없어요"
    }

    static func message(in place: String?) -> String {
        place == nil ? "계곡 이름을 다시 확인해 주세요." : "다른 지역에서 찾아보거나 이름을 다시 확인해 주세요."
    }
}

#Preview {
    SearchEmptyView(query: "설악", source: "자료: 한강홍수통제소, 기상청")
}

#Preview("With filter") {
    SearchEmptyView(query: "설악", source: "자료: 한강홍수통제소, 기상청", place: "횡성군") {}
        .background(Theme.night)
}
