import Foundation

/// Reads the sample server responses bundled in this folder.
/// Used for previews and tests until the app talks to the real server,
/// and to show every screen state (all 5 levels, stale, missing values) on demand.
nonisolated enum MockData {
    enum LoadError: Error, Equatable {
        case fileNotFound(String)
    }

    /// Same shape as `GET /valleys`. Valleys with `subscribed: true` act as `GET /me/valleys`.
    static func valleyList(bundle: Bundle = .main) throws -> ValleyListResponse {
        try load(ValleyListResponse.self, from: "valleys", bundle: bundle)
    }

    /// The 126 valleys of the real server on 2026-11-25, as `GET /valleys` with `province`
    /// and `city` (#96). Only for trying the search filter and pages
    /// (`-mockManyValleys`): these ids (1001+) have no detail.
    static func manyValleys(bundle: Bundle = .main) throws -> ValleyListResponse {
        try load(ValleyListResponse.self, from: "valleys_many", bundle: bundle)
    }

    /// One `GET /valleys/{id}` response per mock valley.
    static func valleyDetails(bundle: Bundle = .main) throws -> [ValleyDetail] {
        try load([ValleyDetail].self, from: "valley_details", bundle: bundle)
    }

    /// One `GET /valleys/{id}/history?hours=3` response per mock valley that has one.
    static func valleyHistories(bundle: Bundle = .main) throws -> [ValleyHistory] {
        try load([ValleyHistory].self, from: "valley_histories", bundle: bundle)
    }

    /// Finds `<fileName>.json` in the app bundle and decodes it with the same decoder as real responses.
    static func load<T: Decodable>(_ type: T.Type, from fileName: String, bundle: Bundle = .main) throws -> T {
        guard let url = bundle.url(forResource: fileName, withExtension: "json") else {
            throw LoadError.fileNotFound(fileName)
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder.yeoulmok().decode(T.self, from: data)
    }
}
