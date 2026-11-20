import AVFoundation

/// Plays the level's sound in a loop while the full-screen alarm is open (#60), for at most
/// `maxDuration`. Uses the `.playback` category, so it sounds even with the silent
/// switch on (decided on 2026-11-19: a flood alarm must not be missed).
/// Only for 위험 · 대피 pushes that arrive while the app is open; a tapped push was
/// already sounded by iOS.
final class AlarmSound {
    /// Sound file (`.caf` in the bundle) for each level, picked by a person on 2026-11-20 (#85).
    /// The server sends the same names in the push `sound`, so a closed app sounds the same.
    /// `nil`: the level has no sound of its own.
    static func fileName(for level: ValleyLevel) -> String? {
        switch level {
        case .caution: "caution"
        case .danger: "danger"
        case .evacuate: "evacuate"
        case .safe, .unknown: nil
        }
    }
    static let maxDuration: Duration = .seconds(30)

    private var player: AVAudioPlayer?
    private var stopTask: Task<Void, Never>?

    func start(level: ValleyLevel) {
        guard player == nil,
              let name = Self.fileName(for: level),
              let url = Bundle.main.url(forResource: name, withExtension: "caf") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.play()
        stopTask = Task { [weak self] in
            try? await Task.sleep(for: Self.maxDuration)
            self?.stop()
        }
    }

    func stop() {
        stopTask?.cancel()
        stopTask = nil
        player?.stop()
        player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
