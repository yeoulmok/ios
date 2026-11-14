import SwiftUI

/// "근처" tab. Placeholder until #15 (APP-NEAR-02).
struct NearbyView: View {
    var body: some View {
        VStack {
            Spacer()
            Text(AppTab.nearby.title)
                .font(.title)
            Spacer()
            // Required on this screen (APP-COM-03). #15 passes the response's `source`.
            SourceFooter(source: nil)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        NearbyView()
    }
}
