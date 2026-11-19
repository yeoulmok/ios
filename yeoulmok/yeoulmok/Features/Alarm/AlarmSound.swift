import AVFoundation

/// Plays `alarm.caf` in a loop while the full-screen alarm is open (#60), for at most
/// `maxDuration`. Uses the `.playback` category, so it sounds even with the silent
/// switch on (decided on 2026-11-19: a flood alarm must not be missed).
/// Only for 위험 · 대피 pushes that arrive while the app is open; a tapped push was
/// already sounded by iOS.
final class AlarmSound {
    /// Temporary sound until a person picks the final one: a synthesized two-tone siren.
    static let fileName = "alarm"
    static let maxDuration: Duration = .seconds(30)

    private var player: AVAudioPlayer?
    private var stopTask: Task<Void, Never>?

    func start() {
        guard player == nil,
              let url = Bundle.main.url(forResource: Self.fileName, withExtension: "caf") else { return }
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
