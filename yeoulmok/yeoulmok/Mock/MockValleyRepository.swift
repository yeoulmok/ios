import Foundation

/// `ValleyRepository` backed by the bundled mock JSON.
/// Behaves like the server: same search rule, same subscription order,
/// same `VALLEY_NOT_FOUND` error. Subscriptions live in memory only.
actor MockValleyRepository: ValleyRepository {
    private let list: ValleyListResponse
    private let details: [Int: ValleyDetail]
    /// Subscribed valley ids, oldest first (the server orders `/me/valleys` this way).
    private var subscriptionOrder: [Int]
    /// When true, every subscribe/unsubscribe fails like a lost connection.
    /// Lets tests and screenshots show the Figma 02b failure (toast + button flips back).
    private let failsSubscriptionChanges: Bool
    /// When true, the first list or detail request fails like a lost connection and
    /// later ones work. Lets tests show the common error screen and "다시 시도" (#17).
    private var failsNextLoad: Bool
    /// When true, each list or detail request works the first time and fails like a
    /// lost connection after that. Lets tests show the offline banner (#16).
    private let failsRepeatedLoads: Bool
    /// When true, every question fails with the server's `TOO_MANY_QUESTIONS` (#64).
    private let failsQuestions: Bool
    /// Requests already answered, e.g. "subscribed", "detail-1".
    private var answeredLoads: Set<String> = []

    init(bundle: Bundle = .main, failsSubscriptionChanges: Bool = false, failsFirstLoad: Bool = false,
         failsRepeatedLoads: Bool = false, failsQuestions: Bool = false) throws {
        self.failsQuestions = failsQuestions
        self.failsSubscriptionChanges = failsSubscriptionChanges
        self.failsNextLoad = failsFirstLoad
        self.failsRepeatedLoads = failsRepeatedLoads
        list = try MockData.valleyList(bundle: bundle)
        details = Dictionary(uniqueKeysWithValues: try MockData.valleyDetails(bundle: bundle).map { ($0.id, $0) })
        subscriptionOrder = list.valleys.filter(\.isSubscribed).map(\.id)
    }

    func valleys(matching query: String?) async throws -> ValleyListResponse {
        try failLoadIfAsked(key: "valleys-\(query ?? "")")
        var valleys = list.valleys.map(withCurrentSubscription)
        if let query, !query.isEmpty {
            valleys = valleys.filter {
                $0.name.range(of: query, options: .caseInsensitive) != nil
                    || $0.region.range(of: query, options: .caseInsensitive) != nil
            }
        }
        return ValleyListResponse(updatedAt: list.updatedAt, source: list.source, valleys: valleys)
    }

    func subscribedValleys() async throws -> ValleyListResponse {
        try failLoadIfAsked(key: "subscribed")
        let byID = Dictionary(uniqueKeysWithValues: list.valleys.map { ($0.id, $0) })
        let valleys = subscriptionOrder.compactMap { byID[$0] }.map(withCurrentSubscription)
        return ValleyListResponse(updatedAt: list.updatedAt, source: list.source, valleys: valleys)
    }

    func valleyDetail(id: Int) async throws -> ValleyDetail {
        try failLoadIfAsked(key: "detail-\(id)")
        guard var detail = details[id] else { throw APIError.valleyNotFound }
        detail.isSubscribed = subscriptionOrder.contains(id)
        return detail
    }

    func subscribe(valleyID: Int) async throws {
        try failIfAsked()
        try requireValley(valleyID)
        if !subscriptionOrder.contains(valleyID) {
            subscriptionOrder.append(valleyID)
        }
    }

    func unsubscribe(valleyID: Int) async throws {
        try failIfAsked()
        try requireValley(valleyID)
        subscriptionOrder.removeAll { $0 == valleyID }
    }

    /// A fixed answer built from the mock detail, like the server's fallback wording.
    func ask(valleyID: Int, question: String) async throws -> AskAnswer {
        if failsQuestions { throw APIError.tooManyQuestions }
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (1...200).contains(trimmed.count) else { throw APIError.questionInvalid }
        guard let detail = details[valleyID] else { throw APIError.valleyNotFound }
        // A short wait, so the loading state is visible as with the real server.
        try await Task.sleep(for: .milliseconds(600))
        return AskAnswer(
            updatedAt: detail.updatedAt, valleyID: valleyID, question: trimmed,
            answer: "지금 \(detail.name)은 '\(detail.level.title)' 단계예요. \(detail.summary). 현장 통제와 공식 안내를 먼저 따라 주세요.",
            isAIFallback: false, level: detail.level,
            observedAt: detail.observations.compactMap(\.observedAt).max(),
            disclaimer: detail.disclaimer, source: detail.source)
    }

    private func failLoadIfAsked(key: String) throws {
        if failsNextLoad {
            failsNextLoad = false
            throw URLError(.notConnectedToInternet)
        }
        if failsRepeatedLoads, !answeredLoads.insert(key).inserted {
            throw URLError(.notConnectedToInternet)
        }
    }

    private func failIfAsked() throws {
        if failsSubscriptionChanges { throw URLError(.notConnectedToInternet) }
    }

    private func requireValley(_ id: Int) throws {
        guard details[id] != nil else { throw APIError.valleyNotFound }
    }

    private func withCurrentSubscription(_ valley: ValleySummary) -> ValleySummary {
        var copy = valley
        copy.isSubscribed = subscriptionOrder.contains(valley.id)
        return copy
    }
}
