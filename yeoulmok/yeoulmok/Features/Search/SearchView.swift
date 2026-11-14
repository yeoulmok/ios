import SwiftUI

/// "검색" tab. Placeholder until #21 (APP-SRCH-02).
struct SearchView: View {
    var body: some View {
        Text(AppTab.search.title)
            .font(.title)
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
