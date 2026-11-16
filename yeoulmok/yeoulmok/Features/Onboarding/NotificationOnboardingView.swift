import SwiftUI

/// First-launch notification screen (APP-ONB-02, Figma 05b). Shown instead of the tabs
/// until one of the buttons is pressed; never shown again after that.
struct NotificationOnboardingView: View {
    static let title = "경보를 알림으로 받을까요?"
    static let message = "구독한 계곡이 위험해지면 바로 알려드려요.\n알림을 꺼도 앱은 그대로 쓸 수 있어요."
    static let allowTitle = "알림 허용"
    static let laterTitle = "나중에 하기"

    @State private var viewModel: NotificationOnboardingViewModel

    init(permission: any NotificationPermission, store: NotificationOnboardingStore,
         onFinish: @escaping () -> Void) {
        _viewModel = State(initialValue: NotificationOnboardingViewModel(
            permission: permission, store: store, onFinish: onFinish))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Spacer()
                .frame(maxHeight: 72)
            Image(systemName: "bell")
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 56, height: 56)
                .background(Color(.systemGray6), in: Circle())
                .accessibilityHidden(true)
            Text(Self.title)
                .font(.title2.weight(.bold))
                .padding(.top, 16)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("onboarding.notification.title")
            Text(Self.message)
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
            VStack(spacing: 12) {
                Button {
                    Task { await viewModel.allow() }
                } label: {
                    Text(Self.allowTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity, minHeight: 50)
                        // Figma 05b: black button; flips to white in dark mode.
                        .background(Color.primary, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("onboarding.notification.allow")
                Button(action: viewModel.later) {
                    Text(Self.laterTitle)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityIdentifier("onboarding.notification.later")
            }
            .buttonStyle(.plain)
            // While iOS's question is up, a second tap does nothing anyway; make it visible.
            .disabled(viewModel.isRequesting)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NotificationOnboardingView(permission: SystemNotificationPermission(),
                               store: NotificationOnboardingStore(defaults: UserDefaults(suiteName: "preview")!),
                               onFinish: {})
}
