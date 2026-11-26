import SwiftUI

/// "AI에게 물어보기" card on the alert detail (APP-DTL-08, #64), between the actions
/// and the disclaimer. Not in Figma:
///
///     ✦ AI에게 물어보기
///     (여기 들어가도 돼요?) (왜 지금 이 단계예요?) (지금 비 많이 와요?)
///     [계곡에 대해 물어보세요            ↑]
///     Q. 여기 들어가도 돼요?
///     지금 금대리 계곡은 '주의' 단계예요. …
///     관측 21:50
///     판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.
struct AskSection: View {
    /// Temporary wording until QA.
    static let title = "AI에게 물어보기"
    static let placeholder = "계곡에 대해 물어보세요"
    static let loadingText = "답을 만들고 있어요"
    static let sendTitle = "보내기"
    /// Always under the field (#100). Temporary wording until QA.
    static let notice = "질문은 AI에 전달돼요 · 개인정보는 적지 마세요"
    /// Before the first question (#100, decided 2026-11-26).
    static let consentTitle = "AI에 질문을 보낼까요?"
    static let consentMessage = "질문은 답을 만들기 위해 외부 AI 서비스(Anthropic Claude)로 전달돼요. 이름 · 전화번호 같은 개인정보는 적지 마세요. 질문은 서버에 저장하지 않아요."
    static let consentAgree = "동의하고 보내기"
    static let consentCancel = "취소"

    @Bindable var model: AskViewModel
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(Self.title, systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(Theme.Text.primary)
                .accessibilityAddTraits(.isHeader)
            suggestions
            field
            result
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassCard()
        .alert(Self.consentTitle, isPresented: consentShown) {
            Button(Self.consentCancel, role: .cancel) { model.cancelConsent() }
            Button(Self.consentAgree) { Task { await model.agreeAndSend() } }
        } message: {
            Text(Self.consentMessage)
        }
    }

    /// Only the buttons decide: SwiftUI sets this to `false` when the popup closes, and
    /// "동의하고 보내기" sends in a `Task` that runs after that, so cancelling here would
    /// drop the question before it is sent.
    private var consentShown: Binding<Bool> {
        Binding(get: { model.pendingQuestion != nil }, set: { _ in })
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(AskViewModel.suggestions.enumerated()), id: \.offset) { index, question in
                    Button {
                        fieldFocused = false
                        Task { await model.ask(question) }
                    } label: {
                        Text(question)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.Text.primary)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 36)
                            .background(Color.white.opacity(0.12), in: Capsule())
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.2)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("ask.suggestion.\(index)")
                }
            }
        }
        .disabled(model.isAsking)
    }

    private var field: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                TextField(Self.placeholder, text: $model.draft)
                    .focused($fieldFocused)
                    .submitLabel(.send)
                    .foregroundStyle(Theme.Text.primary)
                    .onSubmit(send)
                    .accessibilityIdentifier("ask.field")
                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(model.canSendDraft ? Color.white : Theme.Text.source)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .disabled(!model.canSendDraft)
                .accessibilityLabel(Self.sendTitle)
                .accessibilityIdentifier("ask.send")
            }
            .padding(.leading, 14)
            .padding(.trailing, 2)
            .listRowSurface()
            HStack(alignment: .firstTextBaseline) {
                Text(Self.notice)
                    .font(.caption)
                    .foregroundStyle(Theme.Text.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("ask.notice")
                if !model.draft.isEmpty {
                    // Shows the 200-character limit before the server has to say it.
                    let count = AskViewModel.trimmed(model.draft).count
                    Text("\(count)/\(AskViewModel.maxLength)")
                        .font(.caption)
                        .foregroundStyle(count > AskViewModel.maxLength ? Theme.stale : Theme.Text.label)
                }
            }
        }
    }

    @ViewBuilder
    private var result: some View {
        switch model.state {
        case .idle:
            EmptyView()
        case let .asking(question):
            VStack(alignment: .leading, spacing: 8) {
                questionLine(question)
                HStack(spacing: 8) {
                    ProgressView().tint(.white)
                    Text(Self.loadingText)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Text.body)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("ask.loading")
            }
        case let .answered(answer):
            AnswerView(answer: answer, questionLine: questionLine(answer.question))
        case let .failed(question, message):
            VStack(alignment: .leading, spacing: 6) {
                questionLine(question)
                Text(message)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.stale)
                    .accessibilityIdentifier("ask.error")
            }
        }
    }

    private func questionLine(_ question: String) -> some View {
        Text("Q. \(question)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Theme.Text.label)
    }

    private func send() {
        fieldFocused = false
        Task { await model.sendDraft() }
    }
}

/// The server's answer, always with the disclaimer (#64 completion rule).
private struct AnswerView<QuestionLine: View>: View {
    let answer: AskAnswer
    let questionLine: QuestionLine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            questionLine
            Text(answer.answer)
                .font(.body)
                .foregroundStyle(Theme.Text.summary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ask.answer")
            if answer.isAIFallback {
                Text(AIExplanationBox.fallbackNote)
                    .font(.caption)
                    .foregroundStyle(Theme.Text.label)
                    .accessibilityIdentifier("ask.fallback")
            }
            Text("관측 \(ValleyFormat.observedTime(answer.observedAt))")
                .font(.caption)
                .foregroundStyle(Theme.Text.label)
            Text(DisclaimerText.display(answer.disclaimer))
                .font(.caption)
                .foregroundStyle(Theme.Text.source)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("ask.disclaimer")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .listRowSurface()
    }
}

// Previews use the bundled mock data, which Release builds leave out (#102).
#if DEBUG
#Preview {
    ScrollView {
        AskSection(model: AskViewModel(valleyID: 1, repository: try! MockValleyRepository(), consent: .fresh()))
            .padding()
    }
    .background(Theme.night)
}
#endif
