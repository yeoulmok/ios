import SwiftUI
import Testing
@testable import yeoulmok

@MainActor
struct TabNavigationTests {
    @Test func startsOnHomeWithNothingPushed() {
        let navigation = TabNavigation()
        #expect(navigation.selected == .home)
        for tab in AppTab.allCases {
            #expect(navigation.path(for: tab).isEmpty)
        }
    }

    @Test func pushOpensDetailOnHomeFromAnotherTab() {
        var navigation = TabNavigation()
        navigation.selected = .search

        navigation.openDetailFromPush(valleyID: 1)

        #expect(navigation.selected == .home)
        #expect(navigation.path(for: .home) == NavigationPath([ValleyRoute(valleyID: 1)]))
    }

    @Test func pushReplacesWhatHomeShowed() {
        // Not stacked on top: back from the new detail goes straight to the list.
        var navigation = TabNavigation()
        navigation.setPath(NavigationPath([ValleyRoute(valleyID: 2)]), for: .home)

        navigation.openDetailFromPush(valleyID: 1)

        #expect(navigation.path(for: .home).count == 1)
        #expect(navigation.path(for: .home) == NavigationPath([ValleyRoute(valleyID: 1)]))
    }

    @Test func otherTabsKeepTheirScreens() {
        var navigation = TabNavigation()
        let searchPath = NavigationPath([ValleyRoute(valleyID: 3)])
        navigation.setPath(searchPath, for: .search)

        navigation.openDetailFromPush(valleyID: 1)

        #expect(navigation.path(for: .search) == searchPath)
        #expect(navigation.path(for: .nearby).isEmpty)
    }
}
