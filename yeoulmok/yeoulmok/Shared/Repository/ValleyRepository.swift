import Foundation

/// Everything the screens need about valleys, without saying where it comes from.
/// Screens and view models depend on this protocol only, so the mock and the
/// real server implementation can be swapped without touching them.
///
/// Errors: server errors are thrown as `APIError`.
nonisolated protocol ValleyRepository: Sendable {
    /// `GET /valleys`. `query` matches name or region; `nil` or empty returns every valley.
    func valleys(matching query: String?) async throws -> ValleyListResponse

    /// `GET /valleys` one page at a time, for the search list (APP-SRCH-04, #96):
    /// valleys matching the text and the filter, by name. `total` says how many there
    /// are in all; a server without pages ignores the extras and sends everything.
    func valleyPage(_ request: ValleyPageRequest) async throws -> ValleyListResponse

    /// `GET /regions` (#96): provinces and cities with their valley counts.
    func regions() async throws -> ValleyRegions

    /// `GET /me/valleys`. Subscribed valleys, oldest subscription first.
    func subscribedValleys() async throws -> ValleyListResponse

    /// `GET /valleys/{id}`.
    func valleyDetail(id: Int) async throws -> ValleyDetail

    /// `PUT /me/subscriptions/{id}`. Subscribing twice is not an error.
    func subscribe(valleyID: Int) async throws

    /// `DELETE /me/subscriptions/{id}`. Unsubscribing twice is not an error.
    func unsubscribe(valleyID: Int) async throws

    /// "AI에게 물어보기" (APP-DTL-08): sends the question only, returns the server's answer.
    func ask(valleyID: Int, question: String) async throws -> AskAnswer

    /// `GET /valleys/{id}/history?hours=` (APP-DTL-09): one row every 10 minutes, for the
    /// detail's "최근 3시간" card.
    func history(valleyID: Int, hours: Int) async throws -> ValleyHistory

    /// Forget saved answers, so the next requests go to the server (#103): pull to
    /// refresh and pushes call this. Repositories without a cache do nothing.
    func invalidateCache() async

    /// A hint that `valleyDetail(id:)` will likely be asked soon (#103): a repository
    /// with a cache starts that request now, so the later call joins it. Others do
    /// nothing, so a hint never changes what a mock counts.
    func prefetchDetail(id: Int) async
}

extension ValleyRepository {
    nonisolated func invalidateCache() async {}
    nonisolated func prefetchDetail(id: Int) async {}
}
