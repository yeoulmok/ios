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
                .foregroundStyle(.secondary)
                .frame(width: 56, height: 56)
                .background(Color(.systemGray6), in: Circle())
                .accessibilityHidden(true)
            Text(Self.title(for: query))
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("계곡 이름을 다시 확인해 주세요.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
