//
//  VideoModel.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import AVKit
import Foundation

struct VideoModel {
    let asset: AVAsset
    let aspectRatio: CGFloat
    let duration: CMTime
    let playerItem: AVPlayerItem

    let images: [UIImage]

    init(url: URL, size: CGSize) async throws {
        let asset = AVURLAsset(url: url)

        self.asset = asset
        self.playerItem = AVPlayerItem(asset: asset)
        self.duration = try await asset.load(.duration)
        self.images = try await Self.generateImages(asset: asset, size: size)

        let track = try? await asset.loadTracks(withMediaType: .video).first

        guard let assetSize = try await track?.load(.naturalSize) else {
            fatalError("Failed")
        }

        self.aspectRatio = abs(assetSize.width / assetSize.height)
    }

    init(asset: AVAsset, aspectRatio: CGFloat, duration: CMTime, playerItem: AVPlayerItem, images: [UIImage]) {
        self.asset       = asset
        self.aspectRatio = aspectRatio
        self.duration    = duration
        self.playerItem  = playerItem
        self.images      = images
    }

    private static func generateImages(
        asset: AVAsset,
        size: CGSize
    ) async throws -> [UIImage] {
        var images: [UIImage] = []

        guard let track = try await asset.loadTracks(withMediaType: .video).first else {
            return images
        }
        let assetSize = try await track.load(.naturalSize)

        let height: CGFloat = 50
        let aspectRatio = abs(assetSize.width / assetSize.height)
        let width = height * aspectRatio
        let thumbnailSize = CGSize(width: width, height: height)

        let thumbnailCount = Int(ceil(size.width / width))
        let interval = try await asset.load(.duration).seconds / Double(thumbnailCount)

        for i in 0..<thumbnailCount {
            let time = CMTime(seconds: Double(i) * interval, preferredTimescale: 1000)
            guard let thumbnail = await getThumbnail(from: asset, at: time, maximumSize: thumbnailSize) else {
                return images
            }
            images.append(UIImage(cgImage: thumbnail))
        }

        return images
    }

    private static func getThumbnail(from asset: AVAsset?, at time: CMTime, maximumSize: CGSize? = nil) async -> CGImage? {
        do {
            guard let asset = asset else { return nil }
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            if let size = maximumSize {
                imgGenerator.maximumSize = size
            }
            return try await imgGenerator.image(at: time).image //.copyCGImage(at: time, actualTime: nil)
        } catch {
            return nil
        }
    }
}
