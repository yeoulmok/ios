import SwiftUI
import Testing
import UIKit
@testable import yeoulmok

@MainActor
struct ValleyLevelDisplayTests {
    @Test func titlesMatchFeatureSpec() {
        #expect(ValleyLevel.allCases.map(\.title) == ["안전", "주의", "위험", "대피", "판정 불가"])
    }

    @Test func everyLevelHasItsOwnColor() {
        let colors = ValleyLevel.allCases.map(\.badgeBackground)
        #expect(Set(colors).count == ValleyLevel.allCases.count)
    }

    @Test func unknownNeverLooksSafe() {
        #expect(ValleyLevel.unknown.title != ValleyLevel.safe.title)
        #expect(ValleyLevel.unknown.badgeBackground != ValleyLevel.safe.badgeBackground)
        // An icon makes unknown recognizable even without color.
        #expect(ValleyLevel.unknown.badgeSymbol != nil)
        #expect(ValleyLevel.safe.badgeSymbol == nil)
    }

    @Test func unknownIconExistsInSFSymbols() throws {
        let symbol = try #require(ValleyLevel.unknown.badgeSymbol)
        #expect(UIImage(systemName: symbol) != nil)
    }
}
