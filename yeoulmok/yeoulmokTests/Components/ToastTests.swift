import Testing
@testable import yeoulmok

@MainActor
struct ToastTests {
    /// Figma 02b memo: the toast stays 2~3 seconds.
    @Test func durationIsTwoToThreeSeconds() {
        #expect(Toast.duration >= .seconds(2))
        #expect(Toast.duration <= .seconds(3))
    }
}
