import Foundation

/// Flood-risk level the server assigns to a valley.
///
/// Any value the app does not recognize is treated as `.unknown`,
/// so an unexpected server value can never be shown as `.safe`.
nonisolated enum ValleyLevel: String, Decodable, CaseIterable {
    case safe
    case caution
    case danger
    case evacuate
    case unknown

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = ValleyLevel(rawValue: rawValue) ?? .unknown
    }
}
