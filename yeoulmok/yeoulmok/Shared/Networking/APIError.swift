import Foundation

/// An error the server sent as `{ "error": { "code": ..., "message": ... } }`.
/// `message` is written for users and may be shown on screen as is.
nonisolated struct APIError: Error, Decodable, Equatable {
    let code: String
    let message: String

    static let valleyNotFound = APIError(code: "VALLEY_NOT_FOUND", message: "계곡 정보를 찾을 수 없어요")
}
