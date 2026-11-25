import Foundation

/// `ValleyRepository` backed by the bundled mock JSON.
/// Behaves like the server: same search rule, same subscription order,
/// same `VALLEY_NOT_FOUND` error. Subscriptions live in memory only.
actor MockValleyRepository: ValleyRepository {
    private let list: ValleyListResponse
    private let details: [Int: ValleyDetail]
    private let histories: [Int: ValleyHistory]
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
    /// Wait before each search page, so the loading circles show (`-mockManyValleys`).
    private let pageDelay: Duration

    init(bundle: Bundle = .main, failsSubscriptionChanges: Bool = false, failsFirstLoad: Bool = false,
         failsRepeatedLoads: Bool = false, failsQuestions: Bool = false,
         manyValleys: Bool = false, pageDelay: Duration = .zero) throws {
        self.pageDelay = pageDelay
        self.failsQuestions = failsQuestions
        self.failsSubscriptionChanges = failsSubscriptionChanges
        self.failsNextLoad = failsFirstLoad
        self.failsRepeatedLoads = failsRepeatedLoads
        list = manyValleys ? try MockData.manyValleys(bundle: bundle) : try MockData.valleyList(bundle: bundle)
        details = Dictionary(uniqueKeysWithValues: try MockData.valleyDetails(bundle: bundle).map { ($0.id, $0) })
        histories = Dictionary(uniqueKeysWithValues: try MockData.valleyHistories(bundle: bundle).map { ($0.valleyID, $0) })
        subscriptionOrder = list.valleys.filter(\.isSubscribed).map(\.id)
    }

    func valleys(matching query: String?) async throws -> ValleyListResponse {
        try failLoadIfAsked(key: "valleys-\(query ?? "")")
        let valleys = matching(query, in: list.valleys.map(withCurrentSubscription))
        return ValleyListResponse(updatedAt: list.updatedAt, source: list.source, valleys: valleys)
    }

    /// Like the requested server (#96): text and filter together, `limit` rows from
    /// `offset`, and `total` for all matches. Keeps the list order (by id): the server
    /// may sort by name, the app only needs the order to stay the same between pages.
    func valleyPage(_ request: ValleyPageRequest) async throws -> ValleyListResponse {
        try failLoadIfAsked(key: "page-\(request.query ?? "")-\(request.filter)-\(request.offset)")
        // The server takes `limit` 1~100 and `offset` 0 or more, else 422 (server PR #83).
        guard (1...100).contains(request.limit), request.offset >= 0 else {
            throw APIError(code: "VALIDATION_ERROR", message: "limit 1~100, offset 0 이상")
        }
        if pageDelay > .zero { try await Task.sleep(for: pageDelay) }
        let matches = matching(request.query, in: list.valleys.map(withCurrentSubscription))
            .filter { valley in
                (request.filter.province.map { $0 == valley.province } ?? true)
                    && (request.filter.city.map { $0 == valley.city } ?? true)
            }
        let page = matches.dropFirst(request.offset).prefix(request.limit)
        return ValleyListResponse(updatedAt: list.updatedAt, source: list.source, valleys: Array(page),
                                  total: matches.count)
    }

    /// Never fails: the failure options are about the list, and a failed `regions` only
    /// hides the chips, which would take the first failure away from the list.
    func regions() async throws -> ValleyRegions {
        ValleyRegions.counting(list.valleys)
    }

    /// The server's search rule: the text is in the name or the region.
    private func matching(_ query: String?, in valleys: [ValleySummary]) -> [ValleySummary] {
        guard let query, !query.isEmpty else { return valleys }
        return valleys.filter {
            $0.name.range(of: query, options: .caseInsensitive) != nil
                || $0.region.range(of: query, options: .caseInsensitive) != nil
        }
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

    /// The bundled 3-hour history (API spec v0.6 example shape). Valleys without one
    /// fail like the server before it had this endpoint, so the card stays hidden.
    func history(valleyID: Int, hours: Int) async throws -> ValleyHistory {
        try failLoadIfAsked(key: "history-\(valleyID)")
        guard let history = histories[valleyID] else { throw APIError.valleyNotFound }
        return history
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
