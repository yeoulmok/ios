import Foundation
import Testing
@testable import yeoulmok

/// What the common error screen says (APP-COM-06, feature spec 3-1).
struct ErrorContentTests {
    @Test(arguments: [URLError(.notConnectedToInternet), HTTPStatusError(statusCode: 502)] as [any Error])
    func connectionTroubleUsesFigmaWording(error: any Error) {
        let content = ErrorContent(message: ErrorMessage.text(for: error))

        #expect(content.title == "연결할 수 없어요")
        #expect(content.detail == "인터넷 연결을 확인해 주세요.")
        #expect(content.isConnection)
    }

    @Test func serverErrorCodeUsesOnlyTheServerMessage() {
        let content = ErrorContent(message: ErrorMessage.text(for: APIError.valleyNotFound))

        #expect(content.title == "계곡 정보를 찾을 수 없어요")
        #expect(content.detail == nil)
        #expect(!content.isConnection)
    }
}
