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

    init(bundle: Bundle = .main, failsSubscriptionChanges: Bool = false, failsFirstLoad: Bool = false) throws {
        self.failsSubscriptionChanges = failsSubscriptionChanges
        self.failsNextLoad = failsFirstLoad
        list = try MockData.valleyList(bundle: bundle)
        details = Dictionary(uniqueKeysWithValues: try MockData.valleyDetails(bundle: bundle).map { ($0.id, $0) })
        subscriptionOrder = list.valleys.filter(\.isSubscribed).map(\.id)
    }

    func valleys(matching query: String?) async throws -> ValleyListResponse {
        try failLoadIfAsked()
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
        try failLoadIfAsked()
        let byID = Dictionary(uniqueKeysWithValues: list.valleys.map { ($0.id, $0) })
        let valleys = subscriptionOrder.compactMap { byID[$0] }.map(withCurrentSubscription)
        return ValleyListResponse(updatedAt: list.updatedAt, source: list.source, valleys: valleys)
    }

    func valleyDetail(id: Int) async throws -> ValleyDetail {
        try failLoadIfAsked()
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

    private func failLoadIfAsked() throws {
        if failsNextLoad {
            failsNextLoad = false
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
