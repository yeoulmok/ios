import SwiftUI

/// "데이터 출처" in settings (APP-SET-02): where the numbers come from, and the disclaimer.
/// Temporary wording until QA (not in Figma).
struct DataSourceView: View {
    /// (what, from whom). The organizations are the ones in "자료: 한강홍수통제소, 기상청".
    static let sources: [(data: String, provider: String)] = [
        ("하천 수위", "한강홍수통제소"),
        ("강수량", "기상청"),
    ]

    var body: some View {
        List {
            Section {
                ForEach(Self.sources, id: \.data) { source in
                    LabeledContent(source.data, value: source.provider)
                }
                .listRowBackground(Color.white.opacity(0.06))
            } footer: {
                Text(DisclaimerText.fallback)
                    .padding(.top, 4)
            }
        }
        .scrollContentBackground(.hidden)
        .background { PhotoBackdrop(style: .plain) }
        .navigationTitle("데이터 출처")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }
}

#Preview {
    NavigationStack {
        DataSourceView()
    }
}
