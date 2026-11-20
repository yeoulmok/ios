import Foundation

/// Answer to "AI에게 물어보기" (APP-DTL-08, API spec v0.5 #11 `POST /valleys/{id}/ask`).
/// The server writes `answer` (Claude, or fixed wording when `isAIFallback`); the app
/// shows it as it is, always with the disclaimer.
nonisolated struct AskAnswer: Codable, Equatable, Sendable {
    let updatedAt: Date
    let valleyID: Int
    let question: String
    let answer: String
    /// True when the server used fixed wording instead of AI (판정 불가, AI check failed, outage).
    let isAIFallback: Bool
    let level: ValleyLevel
    /// When the values the answer is based on were observed; `nil` when unknown.
    let observedAt: Date?
    let disclaimer: String
    let source: String

    enum CodingKeys: String, CodingKey {
        case updatedAt = "updated_at"
        case valleyID = "valley_id"
        case question, answer
        case isAIFallback = "ai_fallback"
        case level
        case observedAt = "observed_at"
        case disclaimer, source
    }
}

/// Request body: the question only (no location or other personal data).
nonisolated struct AskRequest: Encodable, Equatable, Sendable {
    let question: String
}

extension APIError {
    /// 400: empty question or longer than 200 characters.
    static let questionInvalid = APIError(code: "QUESTION_INVALID", message: "질문을 1~200자로 입력해 주세요")
    /// 429: more than 10 questions an hour from this device.
    static let tooManyQuestions = APIError(code: "TOO_MANY_QUESTIONS", message: "질문이 많아요. 잠시 후 다시 물어봐 주세요")
}
