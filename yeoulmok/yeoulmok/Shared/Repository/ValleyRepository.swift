import Foundation

/// Everything the screens need about valleys, without saying where it comes from.
/// Screens and view models depend on this protocol only, so the mock and the
/// real server implementation can be swapped without touching them.
///
/// Errors: server errors are thrown as `APIError`.
nonisolated protocol ValleyRepository: Sendable {
    /// `GET /valleys`. `query` matches name or region; `nil` or empty returns every valley.
    func valleys(matching query: String?) async throws -> ValleyListResponse

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
}
