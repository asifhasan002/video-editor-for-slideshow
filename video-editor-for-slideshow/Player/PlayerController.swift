//
//  PlayerController.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import AVKit
import SwiftUI
import Combine

protocol PlayerProtocol: ObservableObject {
    var isPlaying: Bool { get }

    var currentTime: CGFloat { get set }
    var trimValues: TrimValues { get set }

    func handleTrimming(_ newPosition: CMTime)

    func finishTrimming()
}

class PlayerController: PlayerProtocol, ObservableObject {
    let player: AVPlayer
    let duration: CMTime

    private var timeObserver: Any?

    @Published var currentTime: CGFloat = 0
    @Published var isPlaying = false

    @Published var trimValues: TrimValues

    private var wasPlaying = false

    init(videoModel: VideoModel) {
        self.duration = videoModel.duration

        let playerItem = AVPlayerItem(asset: videoModel.asset)
        player         = AVPlayer(playerItem: playerItem)

        self.trimValues = TrimValues(upperBound: duration)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd(notification:)),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )

        addPeriodicTimeObserver()
    }

    deinit {
        removePeriodicTimeObserver()
    }

    @objc func playerItemDidReachEnd(notification: Notification) {
        player.seek(to: trimValues.lowerBound) { [weak self] _ in
            self?.player.play()
        }
    }

    func play() {
        player.play()
        isPlaying = true
        wasPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
        wasPlaying = false
    }

    func handleTrimming(_ newPosition: CMTime) {
        defer {
            stopPlayingAndSeekSmoothlyToTime(newChaseTime: newPosition)
        }

        guard isPlaying else { return }

        pause()
        wasPlaying = true
    }

    func finishTrimming() {
        guard wasPlaying else { return }

        play()
    }

    var chaseTime: CMTime = .zero
    var isSeekInProgress = false
    func stopPlayingAndSeekSmoothlyToTime(newChaseTime: CMTime) {
        player.pause()

        guard CMTimeCompare(newChaseTime, chaseTime) != 0 else {
            return
        }
        chaseTime = newChaseTime;

        if !isSeekInProgress {
            trySeekToChaseTime()
        }
    }

    func trySeekToChaseTime() {
        guard player.currentItem?.status == .readyToPlay else {
            return
        }
        actuallySeekToTime()
    }

    func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        player.seek(
            to: seekTimeInProgress,
            toleranceBefore: .zero,
            toleranceAfter: .zero,
        ) { _ in
            if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                self.isSeekInProgress = false
            } else {
                self.trySeekToChaseTime()
            }
        }
    }
}

private extension PlayerController {
    func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.01, preferredTimescale: 6000)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            guard let self else { return }

            self.currentTime = time.seconds

            if CMTimeCompare(time, self.trimValues.upperBound) == 1 {
                self.chaseTime = trimValues.lowerBound
                self.actuallySeekToTime()
            }
        }
    }

    func removePeriodicTimeObserver() {
        guard let timeObserver else { return }
        player.removeTimeObserver(timeObserver)
        self.timeObserver = nil
    }
}
