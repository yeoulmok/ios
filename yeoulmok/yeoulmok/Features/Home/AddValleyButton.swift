import SwiftUI

/// "+ 계곡 추가" box under the home cards (APP-HOME-02, Figma 01 v2).
/// It only reports the tap; the caller decides where to go.
struct AddValleyButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+ 계곡 추가")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
                )
                // The whole box is tappable, not only the text.
                .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        // Read as "계곡 추가" without the "+".
        .accessibilityLabel("계곡 추가")
    }
}

#Preview {
    AddValleyButton {}
        .padding()
}
