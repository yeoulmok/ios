import Foundation

/// Sends one request to the server and decodes the answer. Every server call goes
/// through here, so URL building, headers, and error handling live in one place.
///
/// Errors it throws:
/// - `APIError`: the server answered `{ "error": { "code", "message" } }`.
/// - `HTTPStatusError`: any other non-2xx answer (e.g. 502 from a proxy).
/// - `URLError`: no connection, timeout, ... (from URLSession, passed through).
/// - `DecodingError`: a 2xx answer that does not match the model.
nonisolated struct APIClient: Sendable {
    enum Method: String, Sendable {
        case get = "GET", post = "POST", patch = "PATCH", put = "PUT", delete = "DELETE"
    }

    let baseURL: URL
    let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// - Parameters:
    ///   - path: Relative to `baseURL`, e.g. `"valleys"` or `"me/subscriptions/3"`.
    ///   - body: Sent as JSON when given.
    func send<Response: Decodable>(
        _ method: Method,
        _ path: String,
        query: [URLQueryItem] = [],
        body: (any Encodable & Sendable)? = nil,
        headers: [String: String] = [:],
        as type: Response.Type = Response.self
    ) async throws -> Response {
        var url = baseURL.appending(path: path)
        if !query.isEmpty {
            url.append(queryItems: query)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard (200..<300).contains(status) else {
            if let envelope = try? JSONDecoder().decode(ErrorEnvelope.self, from: data) {
                throw envelope.error
            }
            throw HTTPStatusError(statusCode: status)
        }
        return try JSONDecoder.yeoulmok().decode(Response.self, from: data)
    }

    /// `{ "error": { "code": ..., "message": ... } }`
    private struct ErrorEnvelope: Decodable {
        let error: APIError
    }
}

/// A non-2xx answer without the server's error body (e.g. a proxy's 502 page).
nonisolated struct HTTPStatusError: Error, Equatable {
    let statusCode: Int
}
