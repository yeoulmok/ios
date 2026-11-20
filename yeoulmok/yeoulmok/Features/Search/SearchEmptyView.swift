import SwiftUI

/// "No results" in the search tab (Figma 02a). No button: the user just edits the search text.
struct SearchEmptyView: View {
    /// Trimmed search text; empty when the full list itself came back empty.
    let query: String
    let source: String

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.title2)
                .foregroundStyle(Theme.Text.primary)
                .frame(width: 64, height: 64)
                .glassCard(cornerRadius: Theme.Radius.large)
                .accessibilityHidden(true)
            Text(Self.title(for: query))
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.Text.primary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            Text("계곡 이름을 다시 확인해 주세요.")
                .font(.subheadline)
                .foregroundStyle(Theme.Text.body)
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
}

#Preview {
    SearchEmptyView(query: "설악", source: "자료: 한강홍수통제소, 기상청")
}
