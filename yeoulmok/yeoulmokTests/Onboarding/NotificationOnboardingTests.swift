import Foundation
import Testing
@testable import yeoulmok

@MainActor
struct NotificationOnboardingTests {
    /// A fresh, empty UserDefaults for each test.
    private let store = NotificationOnboardingStore(
        defaults: UserDefaults(suiteName: "NotificationOnboardingTests-\(UUID().uuidString)")!)

    private func makeViewModel(_ permission: FakeNotificationPermission,
                               onFinish: @escaping () -> Void = {}) -> NotificationOnboardingViewModel {
        NotificationOnboardingViewModel(permission: permission, store: store, onFinish: onFinish)
    }

    // MARK: Store

    @Test func notDoneOnFirstLaunch() {
        #expect(!store.isDone)
    }

    @Test func doneIsRemembered() {
        store.markDone()
        #expect(store.isDone)
        store.reset()
        #expect(!store.isDone)
    }

    // MARK: "알림 허용"

    @Test func allowAsksAndRegistersWhenAllowed() async {
        let permission = FakeNotificationPermission(allows: true)
        var finished = 0
        let viewModel = makeViewModel(permission) { finished += 1 }

        await viewModel.allow()

        #expect(permission.requestCount == 1)
        #expect(permission.registerCount == 1)
        #expect(finished == 1)
        #expect(store.isDone)
    }

    @Test func deniedStillGoesOnWithoutRegistering() async {
        // Feature: denying must not block the app.
        let permission = FakeNotificationPermission(allows: false)
        var finished = 0
        let viewModel = makeViewModel(permission) { finished += 1 }

        await viewModel.allow()

        #expect(permission.requestCount == 1)
        #expect(permission.registerCount == 0)
        #expect(finished == 1)
        #expect(store.isDone)
    }

    @Test func buttonsAreDisabledWhileAsking() async {
        let permission = FakeNotificationPermission(allows: true)
        var finished = 0
        let viewModel = makeViewModel(permission) { finished += 1 }
        var requestingWhileAsking = false
        permission.whileAsking = {
            requestingWhileAsking = viewModel.isRequesting
            // A second tap on either button while iOS's question is up does nothing.
            await viewModel.allow()
            viewModel.later()
        }

        await viewModel.allow()

        #expect(requestingWhileAsking)
        #expect(!viewModel.isRequesting)
        #expect(permission.requestCount == 1)
        #expect(finished == 1)
    }

    // MARK: "나중에 하기"

    @Test func laterGoesOnWithoutAsking() {
        let permission = FakeNotificationPermission(allows: true)
        var finished = 0
        let viewModel = makeViewModel(permission) { finished += 1 }

        viewModel.later()

        #expect(permission.requestCount == 0)
        #expect(permission.registerCount == 0)
        #expect(finished == 1)
        #expect(store.isDone)
    }
}
