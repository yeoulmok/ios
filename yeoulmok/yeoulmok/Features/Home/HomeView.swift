import SwiftUI

/// "홈" tab. Placeholder until #4 (APP-HOME-01).
struct HomeView: View {
    var body: some View {
        VStack {
            Spacer()
            Text(AppTab.home.title)
                .font(.title)
            Spacer()
            // Required on this screen (APP-COM-03). #4 passes the response's `source`.
            SourceFooter(source: nil)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
}
