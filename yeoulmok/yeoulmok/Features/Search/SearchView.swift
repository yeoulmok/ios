import SwiftUI

/// "검색" tab. Placeholder until #21 (APP-SRCH-02).
/// The text field is temporary: it gives the tab some state, so the UI test
/// can check that switching tabs keeps it. #21 decides the real search UI.
struct SearchView: View {
    @State private var query = ""

    var body: some View {
        VStack(spacing: 16) {
            TextField("계곡 이름 검색", text: $query)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("search.queryField")
            Spacer()
            Text(AppTab.search.title)
                .font(.title)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
