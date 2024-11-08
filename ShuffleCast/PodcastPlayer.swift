import Foundation
import AVFoundation
import SwiftUI
import MediaPlayer

class PodcastPlayer: ObservableObject {
    @Published var selectedFeed: PodcastFeed?
    @Published var currentEpisode: PodcastEpisode?
    @Published var isPlaying: Bool = false
    @Published var playbackProgress: Double = 0.0
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    


    func configureAudioSession() {
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            setupRemoteTransportControls()
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    
    func playEpisode(_ episode: PodcastEpisode, fromFeed feed: PodcastFeed) {
        configureAudioSession()
        stopPlayback() // Ensure no overlap by stopping any current playback
        
        self.selectedFeed = feed
        self.currentEpisode = episode
        let playerItem = AVPlayerItem(url: episode.audioURL)
        self.player = AVPlayer(playerItem: playerItem)
        
        guard player != nil else {
            print("Failed to initialize player")
            return
        }
        
        addPeriodicTimeObserver()
        addEndObserver()
        self.player?.play()
        self.isPlaying = true
    }
    
    func togglePlayPause() {
        guard let player = player else {
            print("Player is unavailable")
            return
        }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    func skipToNext() {
        guard let currentFeed = selectedFeed else {
            print("No feed selected")
            return
        }
        
        stopPlayback() // Stop current playback before selecting a new random episode
        
        if let randomEpisode = currentFeed.episodes.randomElement() {
            playEpisode(randomEpisode, fromFeed: currentFeed)
        } else {
            print("No episodes available in the selected feed")
        }
    }

    func stopPlayback() {
        player?.pause()
        cleanupPlayer()
        isPlaying = false
        playbackProgress = 0.0
        currentEpisode = nil
    }
    
    private func addPeriodicTimeObserver() {
        guard let player = player else { return }
        let interval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let duration = player.currentItem?.duration else { return }
            let currentSeconds = CMTimeGetSeconds(time)
            let totalSeconds = CMTimeGetSeconds(duration)
            if totalSeconds > 0 {
                self.playbackProgress = currentSeconds / totalSeconds
            }
        }
    }
    
    private func addEndObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(playNextEpisode), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    private func removeEndObserver() {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    @objc private func playNextEpisode() {
           skipToNext()
       }
    
    func seek(to progress: Double) {
        guard let player = player else { return }
        let duration = player.currentItem?.duration.seconds ?? 0
        let newTime = duration * progress
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    
    private func cleanupPlayer() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        player = nil
    }
    
    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    
    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.player?.play()
                self.isPlaying = true
                return .success
            }
            return .commandFailed
        }

        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.player?.pause()
                self.isPlaying = false
                return .success
            }
            return .commandFailed
        }

        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.skipToNext()
            return .success
        }
    }

    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Audio session has been interrupted
            player?.pause()
            isPlaying = false
        case .ended:
            // Interruption ended, optionally resume playback
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    player?.play()
                    isPlaying = true
                }
            }
        default:
            break
        }
    }

    
    deinit {
        cleanupPlayer()
        print("PodcastPlayer deinitialized, resources cleaned up")
    }
}
