//
//  VideoTrimmerView.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI
import CoreMedia

struct VideoTrimmerView: View {
    @State var viewModel: VideoTrimmerViewModel
    @StateObject var playerController: PlayerController

    let start = Date()
    let trackThumbnailImages: [UIImage]

    init(videoModel: VideoModel) {
        self._playerController = StateObject(wrappedValue: PlayerController(videoModel: videoModel))
        self.viewModel = VideoTrimmerViewModel(aspectRatio: videoModel.aspectRatio)
        self.trackThumbnailImages = videoModel.images
    }

    var body: some View {
        VStack(spacing: 10) {
            VideoPlayerView(player: playerController.player)
                .aspectRatio(viewModel.aspectRatio, contentMode: .fit)


            TrimTrackView(
                trackView: ThumbnailTrackView(images: trackThumbnailImages),
                viewModel: TrimTrackViewModel(
                    trimValues: $playerController.trimValues,
                    minSize: 2,
                    playerController: playerController
                ),
                playerController: playerController
            )
            .frame(height: 50)

            HStack {
                Text("L: \(playerController.trimValues.lowerBound.seconds, specifier: "%.2f")")
                    .padding(.leading, 10)
                Spacer()
                Text("\(playerController.currentTime, specifier: "%.2f")")
                    .foregroundStyle(.red)
                    .fontWeight(.semibold)
                Spacer()
                Text("R: \(playerController.trimValues.upperBound.seconds, specifier: "%.2f")")
                    .padding(.trailing, 10)
            }
            .opacity(0.6)

            Spacer()
            
            HStack {
                Button(action: {}) {
                    Image(systemName: "crop")
                        .font(.system(size: 30))
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.bordered)
                
                Button(action: { @MainActor in playerController.isPlaying ? playerController.pause() : playerController.play() }) {
                    Image(systemName: playerController.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                        .fontWeight(.black)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
