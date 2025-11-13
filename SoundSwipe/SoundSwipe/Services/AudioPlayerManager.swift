import Foundation
import AVFoundation

final class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0   // seconds
    @Published var duration: Double = 0      // seconds
    @Published var currentSongID: String?

    private var player: AVPlayer?
    private var timeObserver: Any?

    /// Cap preview at 30 seconds
    private let previewLimit: Double = 30

    private init() {}

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }

    // MARK: - Public API

    /// Play or toggle 30s preview for a song
    func playPreview(for song: Song) {
        guard let urlString = song.previewURL,
              let url = URL(string: urlString) else {
            print("❌ No preview URL for song \(song.name)")
            return
        }

        print("▶️ playPreview for \(song.name) — \(urlString)")

        // If it's already this song, just toggle play/pause
        if currentSongID == song.id, player != nil {
            togglePlayPause()
            return
        }

        currentSongID = song.id
        currentTime = 0

        // Use real duration if we have it, but still cap at 30s
        let fullDuration = song.durationMS.map { Double($0) / 1000 } ?? previewLimit
        duration = min(fullDuration, previewLimit)

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)

        addTimeObserver()

        player?.play()
        isPlaying = true
    }

    func togglePlayPause() {
        guard let player = player else {
            print("⚠️ togglePlayPause called but player is nil")
            return
        }

        if isPlaying {
            print("⏸ pause")
            player.pause()
        } else {
            print("▶️ resume")
            player.play()
        }
        isPlaying.toggle()
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func seek(by seconds: Double) {
        guard let player = player else { return }

        let newTime = max(0, min(duration, currentTime + seconds))
        let cmTime = CMTime(seconds: newTime, preferredTimescale: 600)
        player.seek(to: cmTime)
        currentTime = newTime
    }

    func restart() {
        seek(by: -currentTime)
        pause()
    }

    // MARK: - Time observer

    private func addTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        guard let player = player else { return }

        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval,
                                                      queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds

            if self.currentTime >= self.previewLimit {
                self.currentTime = self.previewLimit
                print("⏹ reached preview limit, pausing")
                self.pause()
            }
        }
    }
}
