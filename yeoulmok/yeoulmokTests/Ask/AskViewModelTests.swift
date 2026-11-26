import Foundation
import Testing
@testable import yeoulmok

@MainActor
struct AskViewModelTests {
    /// These tests are about sending once allowed; the consent itself (#100) is in
    /// `AskConsentTests`, each with a store of its own.
    init() {
        AskConsentStore.shared.isGiven = true
    }
    nonisolated private static func answer(to question: String, fallback: Bool = false) -> AskAnswer {
        AskAnswer(updatedAt: Date(timeIntervalSince1970: 1_795_000_000), valleyID: 1, question: question, answer: "답: \(question)",
                  isAIFallback: fallback, level: .caution, observedAt: nil,
                  disclaimer: "판단 보조 정보이며 공식 재난경보를 대체하지 않습니다.",
                  source: "자료: 한강홍수통제소, 기상청")
    }

    @Test func sendsTrimmedQuestionAndShowsAnswer() async {
        let asked = Recorder()
        let model = AskViewModel(valleyID: 1, repository: StubRepository(ask: { id, question in
            await asked.add("\(id):\(question)")
            return Self.answer(to: question)
        }))
        model.draft = "  여기 들어가도 돼요?  "

        await model.sendDraft()

        #expect(await asked.values == ["1:여기 들어가도 돼요?"])
        #expect(model.state == .answered(Self.answer(to: "여기 들어가도 돼요?")))
        #expect(model.draft.isEmpty, "the field is cleared once sent")
    }

    @Test func emptyOrTooLongQuestionsAreNotSent() async {
        let asked = Recorder()
        let model = AskViewModel(valleyID: 1, repository: StubRepository(ask: { _, question in
            await asked.add(question)
            return Self.answer(to: question)
        }))

        model.draft = "   "
        #expect(!model.canSendDraft)
        await model.sendDraft()
        await model.ask(String(repeating: "가", count: 201))
        await model.ask(String(repeating: "가", count: 200))

        #expect(await asked.values == [String(repeating: "가", count: 200)])
    }

    @Test func secondQuestionWhileAskingIsIgnored() async {
        let gate = Gate()
        let asked = Recorder()
        let model = AskViewModel(valleyID: 1, repository: StubRepository(ask: { _, question in
            await asked.add(question)
            await gate.wait()
            return Self.answer(to: question)
        }))

        let first = Task { await model.ask("여기 들어가도 돼요?") }
        while await asked.values.isEmpty { await Task.yield() }
        #expect(model.isAsking)
        #expect(!model.canSendDraft)
        await model.ask("지금 비 많이 와요?")
        await gate.open()
        await first.value

        #expect(await asked.values == ["여기 들어가도 돼요?"])
        #expect(model.state == .answered(Self.answer(to: "여기 들어가도 돼요?")))
    }

    @Test func serverErrorShowsServerMessage() async {
        let model = AskViewModel(valleyID: 1, repository: StubRepository(ask: { _, _ in
            throw APIError.tooManyQuestions
        }))

        await model.ask("왜 지금 이 단계예요?")

        #expect(model.state == .failed(question: "왜 지금 이 단계예요?", message: APIError.tooManyQuestions.message))
    }

    @Test func connectionErrorShowsCommonMessage() async {
        let model = AskViewModel(valleyID: 1, repository: StubRepository(ask: { _, _ in
            throw URLError(.notConnectedToInternet)
        }))

        await model.ask("지금 비 많이 와요?")

        #expect(model.state == .failed(question: "지금 비 많이 와요?", message: ErrorMessage.connection))
    }
}

/// Collects values from concurrent closures.
private actor Recorder {
    private(set) var values: [String] = []
    func add(_ value: String) { values.append(value) }
}

/// Holds a request until the test opens it.
private actor Gate {
    private var isOpen = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        if isOpen { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters = []
    }
}
