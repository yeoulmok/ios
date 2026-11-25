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
            // No photo here: the map is the picture (#72).
            .background { PhotoBackdrop(style: isFailed ? .offline : .plain) }
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
                LazyVStack(alignment: .leading, spacing: 8) {
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
            .refreshable { await viewModel.refresh() }
        case let .empty(source):
            pullable {
                VStack(alignment: .leading) {
                    offlineBanner
                    header
                    Spacer()
                    Text(Self.emptyText)
                        .foregroundStyle(Theme.Text.body)
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
    private var isFailed: Bool {
        if case .allowed = viewModel.state, case .failed = viewModel.list { true } else { false }
    }

    private var header: some View {
        Text("내 위치 기준")
            .font(.title3.weight(.bold))
            .foregroundStyle(Theme.Text.primary)
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
        .refreshable { await viewModel.refresh() }
    }
}

/// One valley on the nearby list (Figma 03; design #72), the same row look as home.
///
///     [주의]  금대리 계곡
///             11.3km  🕘 자료 지연   (only when stale)
struct NearbyRow: View {
    let nearby: NearbyValley
    /// The map's card (#58) reuses this row with its own identifier.
    var identifier: String?
    /// The map's card sits on the map, so it is glass instead of the faint row surface.
    var onMap = false

    var body: some View {
        HStack(spacing: 12) {
            StatusBadge(level: nearby.valley.level)
            VStack(alignment: .leading, spacing: 2) {
                Text(nearby.valley.name)
                    .font(.headline)
                    .foregroundStyle(Theme.Text.primary)
                HStack(spacing: 8) {
                    Text(NearbyValleys.distanceText(meters: nearby.distanceMeters))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Text.body)
                    // Same rule as home (#9): the judgment uses late data.
                    if nearby.valley.isStale {
                        StaleLabel()
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.Text.source)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(RowSurface(onMap: onMap))
        // VoiceOver reads the whole row at once, name first: "금대리 계곡, 11.3km, 주의".
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityIdentifier(identifier ?? "nearby.row.\(nearby.id)")
    }

    private var accessibilityText: String {
        var parts = [nearby.valley.name, NearbyValleys.distanceText(meters: nearby.distanceMeters),
                     nearby.valley.level.title]
        if nearby.valley.isStale { parts.append(StaleLabel.text) }
        return parts.joined(separator: ", ")
    }
}

private struct RowSurface: ViewModifier {
    let onMap: Bool

    func body(content: Content) -> some View {
        if onMap {
            content.glassCard(cornerRadius: Theme.Radius.row)
        } else {
            content.listRowSurface()
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
                .foregroundStyle(Theme.Text.primary)
                .frame(width: 64, height: 64)
                .glassCard(cornerRadius: Theme.Radius.large)
                .accessibilityHidden(true)
            Text(Self.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.Text.primary)
                .padding(.top, 12)
            Text(Self.message)
                .font(.subheadline)
                .foregroundStyle(Theme.Text.body)
                .multilineTextAlignment(.center)
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text(Self.buttonTitle)
                    .primaryButtonLabel()
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
        LocationDeniedView().padding().background(Theme.night)
    }
}
