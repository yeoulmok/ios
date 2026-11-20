import SwiftUI

/// What the common error screen says for a failure message (feature spec 3-1).
nonisolated struct ErrorContent: Equatable {
    let title: String
    /// Second line. Only for connection errors (Figma 공통 · 에러).
    let detail: String?
    /// Network / server trouble, as opposed to an error code the server sent.
    let isConnection: Bool

    static let connectionDetail = "인터넷 연결을 확인해 주세요."

    /// `message` is a view model's `.failed(message:)`, made by `ErrorMessage.text(for:)`:
    /// either `ErrorMessage.connection` or the server's own `error.message`.
    init(message: String) {
        title = message
        isConnection = message == ErrorMessage.connection
        detail = isConnection ? Self.connectionDetail : nil
    }
}

/// Common error screen (APP-COM-06, Figma 공통 · 에러): shown when a request
/// failed and nothing was received before. "다시 시도" sends the same request again.
struct ErrorStateView: View {
    static let retryTitle = "다시 시도"

    let content: ErrorContent
    /// Sends the same request again. The button is disabled until it returns.
    let onRetry: () async -> Void

    @State private var isRetrying = false

    init(message: String, onRetry: @escaping () async -> Void) {
        content = ErrorContent(message: message)
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: content.isConnection ? "wifi.exclamationmark" : "exclamationmark.circle")
                .font(.title2)
                .foregroundStyle(Theme.Text.primary)
                .frame(width: 64, height: 64)
                .glassCard(cornerRadius: Theme.Radius.large)
                .accessibilityHidden(true)
            Text(content.title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.Text.primary)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .accessibilityIdentifier("error.title")
            if let detail = content.detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.Text.body)
                    .multilineTextAlignment(.center)
            }
            Button {
                Task {
                    isRetrying = true
                    await onRetry()
                    isRetrying = false
                }
            } label: {
                ZStack {
                    Text(Self.retryTitle)
                        .opacity(isRetrying ? 0 : 1)
                    if isRetrying {
                        ProgressView()
                            .tint(Color(hex: 0x101828))
                    }
                }
                .primaryButtonLabel()
            }
            .buttonStyle(.plain)
            // One request at a time: a second tap while retrying does nothing.
            .disabled(isRetrying)
            .padding(.top, 16)
            .accessibilityLabel(Self.retryTitle)
            .accessibilityIdentifier("error.retry")
        }
    }
}

#Preview("연결 · 서버 코드") {
    VStack(spacing: 60) {
        ErrorStateView(message: ErrorMessage.connection) { try? await Task.sleep(for: .seconds(2)) }
        ErrorStateView(message: "계곡 정보를 찾을 수 없어요") {}
    }
    .padding()
}
