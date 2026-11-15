import SwiftUI

/// "근처" tab (APP-NEAR-01, Figma 03 · 03b). Asks for location permission the first
/// time; the nearby list itself is #15 (APP-NEAR-02). The location never leaves the phone.
struct NearbyView: View {
    @State private var viewModel: NearbyViewModel

    init(permission: any LocationPermission = SystemLocationPermission()) {
        _viewModel = State(initialValue: NearbyViewModel(permission: permission))
    }

    var body: some View {
        VStack {
            switch viewModel.state {
            case .askingPermission:
                // iOS's question is on screen; nothing to show until it is answered.
                Spacer()
            case .allowed:
                allowed
            case .denied:
                LocationDeniedView()
            }
            // Required on this screen (APP-COM-03). #15 passes the response's `source`.
            SourceFooter(source: nil)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .navigationTitle("근처 계곡")
        .onAppear { viewModel.onAppear() }
    }

    /// Placeholder until the nearby list (#15).
    private var allowed: some View {
        VStack(alignment: .leading) {
            Text("내 위치 기준")
                .font(.headline)
            Spacer()
            Text("주변 계곡을 불러오는 중이에요")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("nearby.allowed")
            Spacer()
        }
    }
}

/// Figma 03b: location permission denied. "설정 열기" opens this app's page in Settings,
/// the only place the permission can be changed after a denial.
struct LocationDeniedView: View {
    static let title = "위치 권한이 필요해요"
    static let message = "내 주변 계곡을 보려면 위치 권한을 켜주세요.\n위치는 휴대폰 안에서만 사용되고 서버로 보내지 않아요."
    static let buttonTitle = "설정 열기"

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "location.slash")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 56, height: 56)
                .background(Color(.systemGray6), in: Circle())
                .accessibilityHidden(true)
            Text(Self.title)
                .font(.headline)
                .padding(.top, 8)
            Text(Self.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text(Self.buttonTitle)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity, minHeight: 50)
                    // Same look as "계곡 추가하기" (Figma: black button, white in dark mode).
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            .accessibilityIdentifier("nearby.openSettings")
            Spacer()
        }
    }
}

#Preview("거부") {
    NavigationStack {
        LocationDeniedView().padding()
    }
}
