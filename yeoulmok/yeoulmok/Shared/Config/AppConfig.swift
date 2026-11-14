import Foundation

/// Values that differ per environment. They come from Config.xcconfig through Info.plist,
/// so nothing like the server URL is hardcoded in Swift.
enum AppConfig {
    static let apiBaseURL: URL = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "APIBaseURL") as? String,
              let url = URL(string: value), url.scheme == "https" else {
            fatalError("APIBaseURL is missing or invalid. Check Config.xcconfig.")
        }
        return url
    }()
}
