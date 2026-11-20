import SwiftUI

/// "문의하기" in settings (APP-SET-02, #92): the app's own email first, then the public
/// agencies whose data the app shows, kept apart so app problems are not sent to them.
/// Temporary wording until QA (not in Figma).
///
///     여울목 앱 문의
///       이메일                 help@example.com    ›
///     관측 자료 문의 (공식 기관)
///       기상청 · 강수량          홈페이지 ›   131 ›
///       한강홍수통제소 · 하천 수위  홈페이지 ›
struct ContactView: View {
    /// A public agency the app's data comes from (same as `DataSourceView`).
    struct Agency: Equatable {
        let id: String
        let name: String
        /// What to ask them about.
        let topic: String
        let website: URL
        /// Phone shown with its note, or `nil` to show only the website (a number that
        /// could not be confirmed is left out, so it never goes stale in the app).
        let phone: String?
        let phoneNote: String?
    }

    static let appSection = "여울목 앱 문의"
    static let appFooter = "앱 오류, 알림, 계곡 추가 요청은 여울목으로 보내 주세요."
    static let agencySection = "관측 자료 문의 (공식 기관)"
    static let agencyFooter = "관측값 자체나 공식 예보 · 특보는 해당 기관에 문의해 주세요. 기관에서는 여울목 앱 문의를 받지 않아요."
    static let emailMissing = "준비 중"

    /// Checked on 2026-11-20: KMA weather call center 131 (24 hours, charged); for the
    /// Han River Flood Control Office only the website is listed.
    static let agencies: [Agency] = [
        Agency(id: "kma", name: "기상청", topic: "강수량 · 날씨",
               website: URL(string: "https://www.weather.go.kr")!,
               phone: "131", phoneNote: "기상콜센터 · 24시간 · 유료"),
        Agency(id: "hrfco", name: "한강홍수통제소", topic: "하천 수위 · 홍수 예보",
               website: URL(string: "https://www.hrfco.go.kr")!,
               phone: nil, phoneNote: nil),
    ]

    let info: AppInfo

    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            Section {
                row(title: "이메일", value: info.contactEmail ?? Self.emailMissing,
                    url: info.contactURL, id: "contact.email")
            } header: {
                Text(Self.appSection)
            } footer: {
                Text(Self.appFooter)
            }
            .listRowBackground(Self.rowBackground)

            Section {
                ForEach(Self.agencies, id: \.id) { agency in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(agency.name).font(.body.weight(.semibold))
                        Text(agency.topic).font(.footnote).foregroundStyle(Theme.Text.label)
                    }
                    .accessibilityElement(children: .combine)
                    row(title: "홈페이지", value: agency.website.host() ?? "", url: agency.website,
                        id: "contact.\(agency.id).web")
                    if let phone = agency.phone {
                        row(title: "전화 \(phone)", value: agency.phoneNote ?? "",
                            url: URL(string: "tel:\(phone)"), id: "contact.\(agency.id).phone")
                    }
                }
            } header: {
                Text(Self.agencySection)
            } footer: {
                Text(Self.agencyFooter)
            }
            .listRowBackground(Self.rowBackground)
        }
        .scrollContentBackground(.hidden)
        .background { PhotoBackdrop(style: .plain) }
        .navigationTitle("문의하기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    private static let rowBackground = Color.white.opacity(0.06)

    /// A tappable row that opens `url` outside the app; disabled when it is `nil`.
    private func row(title: String, value: String, url: URL?, id: String) -> some View {
        Button {
            if let url { openURL(url) }
        } label: {
            HStack {
                Text(title).foregroundStyle(url == nil ? Theme.Text.source : Theme.Text.primary)
                Spacer()
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(Theme.Text.label)
                    .lineLimit(1)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Text.source)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .disabled(url == nil)
        .accessibilityIdentifier(id)
    }
}

#Preview {
    NavigationStack {
        ContactView(info: AppInfo(info: ["ContactEmail": "help@example.com"]))
    }
}
