import Foundation
import Testing
@testable import yeoulmok

/// #100 (App Store guideline 5.1.2(i)): nothing goes to the AI before the user agrees,
/// and the agreement is asked once.
@MainActor
struct AskConsentTests {
    private let consent = AskConsentStore.fresh()
    private let asked = SentQuestions()

    private func model() -> AskViewModel {
        let asked = asked
        return AskViewModel(valleyID: 1, repository: StubRepository(ask: { _, question in
            await asked.add(question)
            return try await MockValleyRepository().ask(valleyID: 1, question: question)
        }), consent: consent)
    }

    @Test func firstQuestionWaitsForConsent() async {
        let model = model()
        model.draft = " 여기 들어가도 돼요? "

        await model.sendDraft()

        #expect(model.pendingQuestion == "여기 들어가도 돼요?")
        #expect(await asked.values.isEmpty)
        #expect(model.state == .idle)
        #expect(model.draft == " 여기 들어가도 돼요? ", "the text stays until it is sent")
    }

    @Test func agreeingSendsAndIsRemembered() async {
        let model = model()
        await model.ask("왜 지금 이 단계예요?")

        await model.agreeAndSend()

        #expect(await asked.values == ["왜 지금 이 단계예요?"])
        #expect(model.pendingQuestion == nil)
        #expect(consent.isGiven)

        // Later questions go straight away, also from a new detail screen.
        await self.model().ask("지금 비 많이 와요?")
        #expect(await asked.values == ["왜 지금 이 단계예요?", "지금 비 많이 와요?"])
    }

    @Test func agreeingFromTheFieldClearsIt() async {
        let model = model()
        model.draft = "여기 들어가도 돼요?"
        await model.sendDraft()

        await model.agreeAndSend()

        #expect(model.draft.isEmpty)
        #expect(await asked.values == ["여기 들어가도 돼요?"])
    }

    @Test func cancellingSendsNothingAndAsksAgainNextTime() async {
        let model = model()
        await model.ask("여기 들어가도 돼요?")

        model.cancelConsent()

        #expect(model.pendingQuestion == nil)
        #expect(!consent.isGiven)
        #expect(await asked.values.isEmpty)
        await model.ask("여기 들어가도 돼요?")
        #expect(model.pendingQuestion == "여기 들어가도 돼요?")
    }

    @Test func consentIsKeptOnTheDevice() {
        let defaults = UserDefaults(suiteName: "AskConsentTests-\(UUID().uuidString)")!
        AskConsentStore(defaults: defaults).isGiven = true
        #expect(AskConsentStore(defaults: defaults).isGiven)
    }

    /// The popup names the outside AI and the "no personal data" rule.
    @Test func wordingSaysWhereTheQuestionGoes() {
        #expect(AskSection.consentMessage.contains("외부 AI"))
        #expect(AskSection.consentMessage.contains("개인정보"))
        #expect(AskSection.notice.contains("개인정보"))
    }
}

/// Questions that reached the repository, in order.
private actor SentQuestions {
    private(set) var values: [String] = []
    func add(_ question: String) { values.append(question) }
}
