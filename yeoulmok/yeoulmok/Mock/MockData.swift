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

    /// One `GET /valleys/{id}` response per mock valley.
    static func valleyDetails(bundle: Bundle = .main) throws -> [ValleyDetail] {
        try load([ValleyDetail].self, from: "valley_details", bundle: bundle)
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
