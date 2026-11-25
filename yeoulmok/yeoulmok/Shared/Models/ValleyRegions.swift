import Foundation

/// Which valleys the search list asks for (APP-SRCH-04, #96). `nil` means any.
nonisolated struct ValleyFilter: Equatable, Hashable, Sendable {
    var province: String?
    /// Only used together with `province`.
    var city: String?

    static let all = ValleyFilter(province: nil, city: nil)

    var isAll: Bool { province == nil && city == nil }

    /// The narrowest place chosen, for wording: "횡성군", "강원", or `nil`.
    var placeName: String? { city ?? province }
}

/// One page of `GET /valleys?q=&province=&city=&limit=&offset=` (#96).
nonisolated struct ValleyPageRequest: Equatable, Sendable {
    /// Trimmed search text; `nil` when there is none.
    var query: String?
    var filter: ValleyFilter
    var offset: Int
    var limit: Int
}

/// Body of `GET /regions` (#96): every province and city with its valley count,
/// for the filter chips. Counts ignore the search text.
nonisolated struct ValleyRegions: Codable, Equatable {
    let total: Int
    let provinces: [Province]

    nonisolated struct Province: Codable, Equatable, Identifiable {
        let province: String
        let count: Int
        let cities: [City]

        var id: String { province }
    }

    nonisolated struct City: Codable, Equatable, Identifiable {
        let city: String
        let count: Int

        var id: String { city }
    }

    /// Chip order: most valleys first, then by name, so it does not depend on the
    /// server's order. Cities inside each province are ordered the same way.
    var chipOrder: [Province] {
        provinces
            .map { Province(province: $0.province, count: $0.count, cities: Self.sorted($0.cities, \.count, \.city)) }
            .sorted { ($0.count, $1.province) > ($1.count, $0.province) }
    }

    private static func sorted<T>(_ items: [T], _ count: KeyPath<T, Int>, _ name: KeyPath<T, String>) -> [T] {
        items.sorted { ($0[keyPath: count], $1[keyPath: name]) > ($1[keyPath: count], $0[keyPath: name]) }
    }

    /// Counts the valleys of a full list the way the server does (used by the mock).
    static func counting(_ valleys: [ValleySummary]) -> ValleyRegions {
        var byProvince: [String: [String: Int]] = [:]
        for valley in valleys {
            guard let province = valley.province else { continue }
            byProvince[province, default: [:]][valley.city ?? "", default: 0] += 1
        }
        let provinces = byProvince.map { province, cities in
            Province(province: province, count: cities.values.reduce(0, +),
                     cities: cities.filter { !$0.key.isEmpty }.map { City(city: $0.key, count: $0.value) })
        }
        return ValleyRegions(total: valleys.count, provinces: provinces)
    }
}
