import Testing
import UIKit
@testable import yeoulmok

@MainActor
struct AppTabTests {
    @Test func tabsFollowFigmaOrder() {
        #expect(AppTab.allCases == [.home, .nearby, .search])
        #expect(AppTab.allCases.map(\.title) == ["홈", "근처", "검색"])
    }

    @Test(arguments: AppTab.allCases)
    func iconExistsInSFSymbols(tab: AppTab) {
        // A typo in a symbol name shows an empty icon instead of failing the build.
        #expect(UIImage(systemName: tab.systemImage) != nil)
    }
}
