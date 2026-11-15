import Foundation
import Observation

/// State of the home screen (APP-HOME-01). The view only reads `state`;
/// all loading and sorting happens here, so it can be tested without UI.
@Observable
final class HomeViewModel {
    /// The screen is in exactly one of these at a time (feature spec 3-1).
    enum State: Equatable {
        /// First load. The screen frame stays and a spinner is shown.
        case loading
        /// Subscribed valleys, already in home order.
        case loaded(valleys: [ValleySummary], source: String)
        /// Request succeeded but there are no subscriptions. Screen: #18.
        case empty(source: String)
        /// Request failed and nothing was loaded before. Screen: #17.
        case failed(message: String)
    }

    private(set) var state: State = .loading

    private let repository: any ValleyRepository

    init(repository: any ValleyRepository) {
        self.repository = repository
    }

    /// Loads subscribed valleys. Does not reset `state` to `.loading` first,
    /// so a later refresh (#9) keeps the current list on screen while it waits.
    func load() async {
        do {
            let response = try await repository.subscribedValleys()
            if response.valleys.isEmpty {
                state = .empty(source: response.source)
            } else {
                state = .loaded(valleys: response.valleys.sortedForHome(), source: response.source)
            }
        } catch {
            state = .failed(message: ErrorMessage.text(for: error))
        }
    }
}
