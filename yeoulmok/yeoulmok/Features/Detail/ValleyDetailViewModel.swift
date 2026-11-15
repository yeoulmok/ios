import Foundation
import Observation

/// State of the alert detail screen (APP-04). This issue (#10, APP-DTL-01) sets the
/// loading / error rules for the whole screen; #11–#13 only add content to `.loaded`.
@Observable
final class ValleyDetailViewModel {
    /// The screen is in exactly one of these at a time (feature spec 3-1).
    enum State: Equatable {
        /// First load. The screen frame (back button) stays and a spinner is shown.
        case loading
        case loaded(ValleyDetail)
        /// Request failed and nothing was loaded before. The message is the
        /// server's `error.message` for an error code (e.g. `VALLEY_NOT_FOUND`),
        /// otherwise "연결할 수 없어요". Screen: #17.
        case failed(message: String)
    }

    let valleyID: Int
    private(set) var state: State = .loading

    private let repository: any ValleyRepository

    init(valleyID: Int, repository: any ValleyRepository) {
        self.valleyID = valleyID
        self.repository = repository
    }

    /// Loads the detail. Never goes back to `.loading`, and a failure after a
    /// successful load keeps the shown detail (feature spec 3-1: keep the screen;
    /// the "○시 ○분 기준" marker is #16).
    func load() async {
        do {
            state = .loaded(try await repository.valleyDetail(id: valleyID))
        } catch {
            if case .loaded = state { return }
            state = .failed(message: ErrorMessage.text(for: error))
        }
    }
}
