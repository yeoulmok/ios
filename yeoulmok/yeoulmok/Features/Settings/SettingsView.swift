import SwiftUI

/// Settings (APP-SET-02, Figma 06): terms, privacy policy, data source, contact, app version.
/// The "경보 알림" switch in Figma is APP-SET-01 (P1) and is not here yet.
struct SettingsView: View {
    var info: AppInfo = .current

    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section("정보") {
                ForEach(SettingsRows.rows(for: info)) { row in
                    rowView(row)
                }
            }
            .listRowBackground(Self.rowBackground)
            Section {
                LabeledContent("앱 버전", value: SettingsRows.versionText(for: info))
                    .accessibilityIdentifier("settings.version")
            } footer: {
                VStack(alignment: .leading, spacing: 2) {
                    SourceFooter(source: nil)
                    // The background photo's credit (#72): photographer and Unsplash, as Unsplash asks (#92).
                    Text(Self.photoCredit)
                        .font(.caption)
                        .foregroundStyle(Theme.Text.source)
                }
                .padding(.top, 4)
            }
            .listRowBackground(Self.rowBackground)
        }
        // No photo on settings (#72): night background, faint grouped rows.
        .scrollContentBackground(.hidden)
        .background { PhotoBackdrop(style: .plain) }
        .navigationTitle("설정")
        // Figma 06 has no tab bar, like the alert detail.
        .toolbar(.hidden, for: .tabBar)
    }

    static let photoCredit = "배경 사진: May Cloud, Unsplash"
    private static let rowBackground = Color.white.opacity(0.06)

    @ViewBuilder
    private func rowView(_ row: SettingsRow) -> some View {
        switch row.action {
        case .dataSource:
            NavigationLink(row.title) {
                DataSourceView()
            }
            .accessibilityIdentifier("settings.\(row.id)")
        case let .open(url):
            Button {
                if let url { openURL(url) }
            } label: {
                HStack {
                    Text(row.title)
                        .foregroundStyle(row.isEnabled ? Theme.Text.primary : Theme.Text.source)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        // Not the button's tint: same gray arrow as the NavigationLink row.
                        .foregroundStyle(Theme.Text.source)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .disabled(!row.isEnabled)
            .accessibilityIdentifier("settings.\(row.id)")
        }
    }
}

#Preview("링크 있음") {
    NavigationStack {
        SettingsView(info: AppInfo(info: [
            "CFBundleShortVersionString": "1.0",
            "TermsURL": "https://example.com/terms",
            "PrivacyURL": "https://example.com/privacy",
            "ContactEmail": "help@example.com",
        ]))
    }
}

#Preview("링크 없음") {
    NavigationStack {
        SettingsView(info: AppInfo(info: ["CFBundleShortVersionString": "1.0"]))
    }
}
