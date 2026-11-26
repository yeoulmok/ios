import Foundation
import Observation

/// "AI에게 물어보기" on the alert detail (APP-DTL-08, #64).
/// Sends the question only; the answer is the server's, shown as it is.
@MainActor
@Observable
final class AskViewModel {
    enum State: Equatable {
        /// Nothing asked yet.
        case idle
        /// Waiting for the server (it takes a few seconds).
        case asking(question: String)
        /// The latest answer; a new question replaces it.
        case answered(AskAnswer)
        /// The request failed: the server's message, or "연결할 수 없어요".
        case failed(question: String, message: String)
    }

    /// Suggested questions (decided 2026-11-20). Same for every level, so they never
    /// read oddly (e.g. "왜 판정 불가예요?").
    static let suggestions = ["여기 들어가도 돼요?", "왜 지금 이 단계예요?", "지금 비 많이 와요?"]
    /// The server accepts 1 to 200 characters (API spec v0.5 #11).
    static let maxLength = 200

    private(set) var state: State = .idle
    /// Text in the field.
    var draft = ""
    /// A question waiting for the user's consent (#100): the consent popup is on
    /// screen while this is set. Nothing has been sent.
    private(set) var pendingQuestion: String?

    private let valleyID: Int
    private let repository: any ValleyRepository
    private let consent: AskConsentStore

    /// - Parameter consent: `nil` is the app's own (`AskConsentStore.shared`).
    init(valleyID: Int, repository: any ValleyRepository, consent: AskConsentStore? = nil) {
        self.valleyID = valleyID
        self.repository = repository
        self.consent = consent ?? .shared
    }

    var isAsking: Bool {
        if case .asking = state { true } else { false }
    }

    /// The field's text can be sent: 1 to 200 characters after trimming, and not while asking.
    var canSendDraft: Bool {
        !isAsking && Self.isValid(draft)
    }

    /// Sends the field's text; the field is cleared once sent. Before the first
    /// consent the text stays in the field, so cancelling loses nothing.
    func sendDraft() async {
        guard canSendDraft else { return }
        guard consent.isGiven else {
            pendingQuestion = Self.trimmed(draft)
            return
        }
        let question = draft
        draft = ""
        await ask(question)
    }

    /// Sends a question (from the field or a suggestion). Does nothing while another
    /// question is on its way, or for an empty or too long question. Without consent
    /// it only asks for it (#100).
    func ask(_ question: String) async {
        let trimmed = Self.trimmed(question)
        guard !isAsking, Self.isValid(trimmed) else { return }
        guard consent.isGiven else {
            pendingQuestion = trimmed
            return
        }
        await send(trimmed)
    }

    /// "동의하고 보내기": remembered on this device, then the waiting question is sent.
    func agreeAndSend() async {
        guard let question = pendingQuestion else { return }
        pendingQuestion = nil
        consent.isGiven = true
        if Self.trimmed(draft) == question { draft = "" }
        await send(question)
    }

    /// "취소": nothing is sent and nothing is remembered.
    func cancelConsent() {
        pendingQuestion = nil
    }

    private func send(_ trimmed: String) async {
        state = .asking(question: trimmed)
        do {
            state = .answered(try await repository.ask(valleyID: valleyID, question: trimmed))
        } catch {
            state = .failed(question: trimmed, message: ErrorMessage.text(for: error))
        }
    }

    nonisolated static func isValid(_ question: String) -> Bool {
        (1...maxLength).contains(trimmed(question).count)
    }

    nonisolated static func trimmed(_ question: String) -> String {
        question.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
