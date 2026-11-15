import Foundation
import Testing
@testable import yeoulmok

struct ErrorMessageTests {
    @Test func serverErrorUsesServerMessage() {
        let error = APIError(code: "VALLEY_NOT_FOUND", message: "계곡을 찾을 수 없어요")
        #expect(ErrorMessage.text(for: error) == "계곡을 찾을 수 없어요")
    }

    @Test(arguments: [URLError(.notConnectedToInternet), URLError(.timedOut)])
    func otherErrorsUseConnectionMessage(error: URLError) {
        #expect(ErrorMessage.text(for: error) == "연결할 수 없어요")
    }
}
