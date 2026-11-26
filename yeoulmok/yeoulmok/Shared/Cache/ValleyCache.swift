import Foundation

/// The last responses the app received, saved on the device (APP-COM-07, #16).
/// When the server cannot be reached, screens show these with "○월 ○일 ○○:○○ 기준"
/// instead of an error, also after the app was restarted (e.g. no signal in a valley).
///
/// Files live in Caches: iOS may delete them when storage is low, which is fine for
/// a cache. Reading or writing never throws: a missing or broken file is just "no cache".
actor ValleyCache {
    private let directory: URL
    /// What each file holds, as last written by this run (#103). Screens save every
    /// answer they get, and within the 60 s of `CachingValleyRepository` that is the
    /// same answer again: then the file is left alone.
    private var written: [String: Data] = [:]

    /// Tests pass their own folder.
    init(directory: URL) {
        self.directory = directory
    }

    /// The app's cache folder.
    static func standard() -> ValleyCache {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return ValleyCache(directory: caches.appending(path: "ValleyCache", directoryHint: .isDirectory))
    }

    /// `GET /me/valleys` (home).
    func subscribedValleys() -> ValleyListResponse? {
        read(ValleyListResponse.self, from: "subscribed.json")
    }

    func saveSubscribedValleys(_ response: ValleyListResponse) {
        write(response, to: "subscribed.json")
    }

    /// `GET /valleys` without a search word (nearby, #15). Every valley with its
    /// coordinates, so the nearby list can be rebuilt for wherever the user is now.
    func allValleys() -> ValleyListResponse? {
        read(ValleyListResponse.self, from: "valleys.json")
    }

    func saveAllValleys(_ response: ValleyListResponse) {
        write(response, to: "valleys.json")
    }

    /// `GET /valleys/{id}` (alert detail).
    func detail(id: Int) -> ValleyDetail? {
        read(ValleyDetail.self, from: "detail-\(id).json")
    }

    func saveDetail(_ detail: ValleyDetail) {
        write(detail, to: "detail-\(detail.id).json")
    }

    private func read<Value: Decodable>(_ type: Value.Type, from name: String) -> Value? {
        guard let data = try? Data(contentsOf: directory.appending(path: name)) else { return nil }
        return try? JSONDecoder.yeoulmok().decode(type, from: data)
    }

    /// Compares the whole content, not `updated_at`: subscribing changes a detail
    /// without changing its time. Writes again if iOS removed the file meanwhile.
    private func write(_ value: some Encodable, to name: String) {
        guard let data = try? JSONEncoder.yeoulmok().encode(value) else { return }
        let file = directory.appending(path: name)
        if written[name] == data, FileManager.default.fileExists(atPath: file.path(percentEncoded: false)) {
            return
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            try data.write(to: file, options: .atomic)
            written[name] = data
        } catch {
            written[name] = nil
        }
    }
}
