import SwiftUI

/// "연결할 수 없어 11월 15일 20:10 기준 정보를 보여드려요" (APP-COM-07, Figma 공통 ·
/// 컴포넌트 OfflineBanner). Shown above the last received data when a request failed.
struct OfflineBanner: View {
    /// `updated_at` of the response being shown.
    let asOf: Date

    static let hint = "아래로 당겨 다시 시도"

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Self.text(asOf: asOf))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.stale)
            Text(Self.hint)
                .font(.caption)
                .foregroundStyle(Theme.Text.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        // Amber, the same color as "자료 지연": old data (#72).
        .background(Theme.stale.opacity(0.16), in: RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
            .strokeBorder(Theme.stale.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("offlineBanner")
    }

    /// Korean time with the date, so old data never looks current.
    static func text(asOf date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = ServerDate.timeZone
        formatter.dateFormat = "M월 d일 HH:mm"
        return "연결할 수 없어 \(formatter.string(from: date)) 기준 정보를 보여드려요"
    }
}

#Preview {
    OfflineBanner(asOf: ServerDate.parse("2026-11-06T23:00")!)
        .padding()
}
