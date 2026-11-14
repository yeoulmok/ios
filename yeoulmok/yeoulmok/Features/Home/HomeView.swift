import SwiftUI

/// "홈" tab. Placeholder until #4 (APP-HOME-01).
struct HomeView: View {
    var body: some View {
        Text(AppTab.home.title)
            .font(.title)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
