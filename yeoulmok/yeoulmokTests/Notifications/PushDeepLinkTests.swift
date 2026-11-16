import Foundation
import Testing
@testable import yeoulmok

struct PushPayloadTests {
    @Test func readsTheValleyID() {
        // API spec 4.
        let userInfo: [AnyHashable: Any] = [
            "aps": ["alert": ["title": "금대리 계곡 · 주의", "body": "상류에 비가 많이 오고 있어요"]],
            "valley_id": 1, "level": "caution",
        ]
        #expect(PushPayload.valleyID(from: userInfo) == 1)
    }

    @Test func numberFromJSONWorks() throws {
        // What iOS actually hands over: JSON numbers arrive as NSNumber.
        let json = Data(#"{"aps":{},"valley_id":2}"#.utf8)
        let userInfo = try #require(try JSONSerialization.jsonObject(with: json) as? [AnyHashable: Any])
        #expect(PushPayload.valleyID(from: userInfo) == 2)
    }

    @Test func numberAsTextWorks() {
        #expect(PushPayload.valleyID(from: ["valley_id": "3"]) == 3)
        #expect(PushPayload.valleyID(from: ["valley_id": " 3 "]) == 3)
    }

    @Test(arguments: [
        [:] as [AnyHashable: Any],
        ["valley_id": "abc"],
        ["valley_id": ""],
        ["valley_id": 0],
        ["valley_id": -1],
        ["valley_id": 1.5],
        ["valley_id": NSNull()],
        ["valleyId": 1],
    ] as [[AnyHashable: Any]])
    func noValleyMeansNil(userInfo: [AnyHashable: Any]) {
        #expect(PushPayload.valleyID(from: userInfo) == nil)
    }
}

@MainActor
struct PushRouterTests {
    @Test func nothingWaitingAtFirst() {
        #expect(PushRouter().take() == nil)
    }

    @Test func takeReturnsOnce() {
        let router = PushRouter()
        router.open(valleyID: 1)
        #expect(router.pendingValleyID == 1)
        #expect(router.take() == 1)
        #expect(router.take() == nil)
    }

    @Test func latestTapWins() {
        // Two taps before RootView takes one: open the last one tapped.
        let router = PushRouter()
        router.open(valleyID: 1)
        router.open(valleyID: 2)
        #expect(router.take() == 2)
    }
}
