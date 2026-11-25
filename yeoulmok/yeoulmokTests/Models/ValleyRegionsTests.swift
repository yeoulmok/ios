import Foundation
import Testing
@testable import yeoulmok

/// APP-SRCH-04 (#96): province · city on list rows, `total`, `GET /regions`, and the
/// mock answering like the requested server.
struct ValleyRegionsTests {
    /// The server before #96 sends none of the new values: the list still reads.
    @Test func olderListHasNoProvinceOrTotal() throws {
        let response = try JSONDecoder.yeoulmok().decode(ValleyListResponse.self, from: Data(#"""
        {"updated_at": "2026-11-25T10:00", "source": "자료", "valleys": [
          {"id": 1, "name": "금대리 계곡", "region": "원주시 판부면", "lat": 37.27, "lon": 128.01,
           "level": "safe", "rain_1h_mm": 0.0, "water_rise_30m_m": null,
           "observed_at": "2026-11-25T09:50", "stale": false, "subscribed": false}]}
        """#.utf8))

        #expect(response.total == nil)
        #expect(response.valleys.first?.province == nil)
        #expect(response.valleys.first?.city == nil)
    }

    /// Chips: most valleys first, ties by name; cities the same way.
    @Test func chipOrderIsByCountThenName() {
        let regions = ValleyRegions(total: 7, provinces: [
            .init(province: "서울", count: 1, cities: [.init(city: "관악구", count: 1)]),
            .init(province: "강원", count: 5, cities: [.init(city: "원주시", count: 2), .init(city: "횡성군", count: 3)]),
            .init(province: "경기", count: 1, cities: []),
        ])

        #expect(regions.chipOrder.map(\.province) == ["강원", "경기", "서울"])
        #expect(regions.chipOrder.first?.cities.map(\.city) == ["횡성군", "원주시"])
    }

    @Test func filterPlaceNameIsTheNarrowestChoice() {
        #expect(ValleyFilter.all.placeName == nil)
        #expect(ValleyFilter(province: "강원", city: nil).placeName == "강원")
        #expect(ValleyFilter(province: "강원", city: "횡성군").placeName == "횡성군")
    }

    // MARK: Mock

    @Test func mockPagesFollowEachOtherWithTotal() async throws {
        let repository = try MockValleyRepository(manyValleys: true)

        let first = try await repository.valleyPage(ValleyPageRequest(query: nil, filter: .all, offset: 0, limit: 20))
        let last = try await repository.valleyPage(ValleyPageRequest(query: nil, filter: .all, offset: 120, limit: 20))

        #expect(first.total == 126)
        #expect(first.valleys.count == 20)
        #expect(last.valleys.count == 6)
        #expect(Set(first.valleys.map(\.id)).isDisjoint(with: last.valleys.map(\.id)))
    }

    @Test func mockFiltersByProvinceCityAndText() async throws {
        let repository = try MockValleyRepository(manyValleys: true)

        let gangwon = try await repository.valleyPage(ValleyPageRequest(
            query: nil, filter: ValleyFilter(province: "강원", city: nil), offset: 0, limit: 100))
        let hoengseong = try await repository.valleyPage(ValleyPageRequest(
            query: nil, filter: ValleyFilter(province: "강원", city: "횡성군"), offset: 0, limit: 100))
        let none = try await repository.valleyPage(ValleyPageRequest(
            query: "설악", filter: ValleyFilter(province: "강원", city: "횡성군"), offset: 0, limit: 20))

        #expect(gangwon.total == 111)
        #expect(hoengseong.total == 14)
        #expect(hoengseong.valleys.allSatisfy { $0.city == "횡성군" })
        #expect(none.total == 0)
        #expect(none.valleys.isEmpty)
    }

    /// #98: like the server, `limit` must be 1~100.
    @Test func mockRejectsALimitOverAHundred() async throws {
        let repository = try MockValleyRepository(manyValleys: true)

        await #expect(throws: APIError.self) {
            try await repository.valleyPage(ValleyPageRequest(query: nil, filter: .all, offset: 0, limit: 101))
        }
        await #expect(throws: APIError.self) {
            try await repository.valleyPage(ValleyPageRequest(query: nil, filter: .all, offset: 0, limit: 0))
        }
    }

    @Test func mockRegionsCountTheList() async throws {
        let regions = try await MockValleyRepository(manyValleys: true).regions()

        #expect(regions.total == 126)
        #expect(regions.chipOrder.first?.province == "강원")
        #expect(regions.chipOrder.first?.count == 111)
        #expect(regions.chipOrder.first?.cities.first?.city == "횡성군")
        #expect(regions.provinces.count == 16)
    }
}
