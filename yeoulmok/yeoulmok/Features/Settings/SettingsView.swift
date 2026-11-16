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
            Section {
                LabeledContent("앱 버전", value: SettingsRows.versionText(for: info))
                    .accessibilityIdentifier("settings.version")
            } footer: {
                SourceFooter(source: nil)
                    .padding(.top, 4)
            }
        }
        .navigationTitle("설정")
        // Figma 06 has no tab bar, like the alert detail.
        .toolbar(.hidden, for: .tabBar)
    }

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
                        .foregroundStyle(row.isEnabled ? Color.primary : Color.secondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        // Not the button's tint: same gray arrow as the NavigationLink row.
                        .foregroundStyle(Color(.tertiaryLabel))
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
