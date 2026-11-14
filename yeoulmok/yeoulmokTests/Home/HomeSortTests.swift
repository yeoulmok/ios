import Foundation
import Testing
@testable import yeoulmok

struct HomeSortTests {
    private func valley(_ id: Int, _ name: String, _ level: ValleyLevel) -> ValleySummary {
        ValleySummary(
            id: id, name: name, region: "지역", latitude: 37, longitude: 128, level: level,
            rainLastHourMM: nil, waterRise30MinM: nil, observedAt: nil,
            isStale: false, isSubscribed: true
        )
    }

    @Test func mostUrgentFirstAndUnknownAboveSafe() {
        let sorted = [
            valley(1, "가", .safe),
            valley(2, "나", .unknown),
            valley(3, "다", .caution),
            valley(4, "라", .evacuate),
            valley(5, "마", .danger),
        ].sortedForHome()

        #expect(sorted.map(\.level) == [.evacuate, .danger, .caution, .unknown, .safe])
    }

    @Test func sameLevelIsSortedByKoreanName() {
        let sorted = [
            valley(1, "횡성 갑천 계곡", .caution),
            valley(2, "금대리 계곡", .caution),
            valley(3, "가리왕산 계곡", .caution),
        ].sortedForHome()

        #expect(sorted.map(\.name) == ["가리왕산 계곡", "금대리 계곡", "횡성 갑천 계곡"])
    }

    @Test func sameNameKeepsStableOrderById() {
        let sorted = [valley(9, "계곡", .safe), valley(3, "계곡", .safe)].sortedForHome()
        #expect(sorted.map(\.id) == [3, 9])
    }

    @Test func mockListOrder() throws {
        // Mock: 5 대피, 4 위험, 1 주의, 2 판정 불가, 3 안전
        let sorted = try MockData.valleyList().valleys.sortedForHome()
        #expect(sorted.map(\.id) == [5, 4, 1, 2, 3])
    }
}
