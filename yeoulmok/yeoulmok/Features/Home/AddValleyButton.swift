import SwiftUI

/// "+ 계곡 추가" link next to the "구독한 계곡" header (APP-HOME-02; moved up in #71).
/// It only reports the tap; the caller decides where to go.
struct AddValleyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+ 계곡 추가")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.link)
                // At least 44pt high to tap, though the text is small.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // Read as "계곡 추가" without the "+".
        .accessibilityLabel("계곡 추가")
    }
}

#Preview {
    AddValleyButton {}
        .padding()
        .background(Theme.night)
}
