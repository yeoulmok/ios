import SwiftUI

/// "근처" tab. Placeholder until #15 (APP-NEAR-02).
struct NearbyView: View {
    var body: some View {
        Text(AppTab.nearby.title)
            .font(.title)
    }
}

#Preview {
    NavigationStack {
        NearbyView()
    }
}
