import SwiftUI

/// "근처" tab (APP-NEAR-01 · 02 · 03, Figma 03 · 03b). Asks for location permission the
/// first time, then shows the closest valleys on a map (#58) and as a list.
/// The location never leaves the phone.
struct NearbyView: View {
    /// Temporary wording until QA (not in Figma): the server has no valleys at all.
    static let emptyText = "주변에 계곡이 없어요"

    @State private var viewModel: NearbyViewModel

    init(repository: any ValleyRepository, cache: ValleyCache? = nil,
         permission: any LocationPermission = SystemLocationPermission()) {
        _viewModel = State(initialValue: NearbyViewModel(permission: permission, repository: repository, cache: cache))
    }

    var body: some View {
        content
            .navigationTitle("근처 계곡")
            .onAppear { viewModel.onAppear() }
            // Each time the tab appears (a fresh location), and right after "허용".
            .task(id: viewModel.state) { await viewModel.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .askingPermission:
            // iOS's question is on screen; nothing to show until it is answered.
            VStack {
                Spacer()
                SourceFooter(source: nil)
            }
            .padding()
            .frame(maxWidth: .infinity)
        case .denied:
            VStack {
                LocationDeniedView()
                SourceFooter(source: nil)
            }
            .padding()
        case .allowed:
            list
        }
    }

    @ViewBuilder
    private var list: some View {
        switch viewModel.list {
        case .loading:
            // Feature spec 3-1: keep the screen frame, show a spinner.
            VStack(alignment: .leading) {
                header
                Spacer()
                ProgressView()
                    .frame(maxWidth: .infinity)
                Spacer()
                SourceFooter(source: nil)
            }
            .padding()
        case let .loaded(valleys, source):
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    offlineBanner
                    // #58: the same valleys on a map, above the list.
                    if let user = viewModel.userLocation {
                        NearbyMapView(user: user, valleys: valleys)
                    }
                    header
                    ForEach(valleys) { nearby in
                        NavigationLink(value: ValleyRoute(valleyID: nearby.id)) {
                            NearbyRow(nearby: nearby)
                        }
                        .buttonStyle(.plain)
                    }
                    // Figma 03: the source line sits at the end of the list.
                    SourceFooter(source: source)
                        .padding(.top, 4)
                }
                .padding()
            }
            .refreshable { await viewModel.load() }
        case let .empty(source):
            pullable {
                VStack(alignment: .leading) {
                    offlineBanner
                    header
                    Spacer()
                    Text(Self.emptyText)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                    SourceFooter(source: source)
                }
            }
        case let .failed(message):
            pullable {
                VStack {
                    Spacer()
                    ErrorStateView(message: message) { await viewModel.load() }
                    Spacer()
                    SourceFooter(source: nil)
                }
            }
        }
    }

    /// Figma 03: "내 위치 기준" above the list.
    private var header: some View {
        Text("내 위치 기준")
            .font(.headline)
            .accessibilityIdentifier("nearby.allowed")
    }

    /// Above the last received data when the latest request failed (APP-COM-07).
    @ViewBuilder
    private var offlineBanner: some View {
        if let asOf = viewModel.offlineAsOf {
            OfflineBanner(asOf: asOf)
        }
    }

    /// A full-screen view in a scroll view, so it can be pulled to refresh too (#9).
    private func pullable(@ViewBuilder _ content: () -> some View) -> some View {
        ScrollView {
            content()
                .padding()
                .containerRelativeFrame([.horizontal, .vertical])
        }
        .refreshable { await viewModel.load() }
    }
}

/// One valley on the nearby list (Figma 03).
///
///     금대리 계곡                 [주의]
///     11.3km  🕘 자료 지연   (only when stale)
struct NearbyRow: View {
    let nearby: NearbyValley
    /// The map's card (#58) reuses this row with its own identifier.
    var identifier: String?

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(nearby.valley.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(NearbyValleys.distanceText(meters: nearby.distanceMeters))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    // Same rule as home (#9): the judgment uses late data.
                    if nearby.valley.isStale {
                        StaleLabel()
                    }
                }
            }
            Spacer()
            StatusBadge(level: nearby.valley.level)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.separator)))
        // VoiceOver reads the whole row at once: "금대리 계곡, 11.3km, 주의".
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier ?? "nearby.row.\(nearby.id)")
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

#Preview("목록") {
    NavigationStack {
        NearbyView(repository: try! MockValleyRepository(),
                   permission: SystemLocationPermission(fixedLocation: SystemLocationPermission.mockLocation))
    }
}

#Preview("거부") {
    NavigationStack {
        LocationDeniedView().padding()
    }
}
