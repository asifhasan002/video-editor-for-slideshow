////
////  VideoTrimmerView.swift
////  video-editor-for-slideshow
////
////  Created by Md Asif Hasan on 8/1/26.
////
//
//import SwiftUI
//import CoreMedia
//
//struct VideoTrimmerView: View {
//    @State var viewModel: VideoTrimmerViewModel
//    @StateObject var playerController: PlayerController
//    @State private var isCropping = false
//    @State private var cropRect = CGRect(x: 0.1, y: 0.2, width: 0.8, height: 0.6) // normalized coordinates
//
//    let start = Date()
//    let trackThumbnailImages: [UIImage]
//
//    init(videoModel: VideoModel) {
//        self._playerController = StateObject(wrappedValue: PlayerController(videoModel: videoModel))
//        self.viewModel = VideoTrimmerViewModel(aspectRatio: videoModel.aspectRatio)
//        self.trackThumbnailImages = videoModel.images
//    }
//
//    var body: some View {
//        VStack(spacing: 10) {
//            ZStack {
//                VideoPlayerView(player: playerController.player)
//                    .aspectRatio(viewModel.aspectRatio, contentMode: .fit)
//
//                if isCropping {
//                    // Free form cropping overlay
//                    GeometryReader { geometry in
//                        ZStack {
//                            // Semi-transparent overlay
//                            Color.black.opacity(0.3)
//
//                            // Crop rectangle
//                            RoundedRectangle(cornerRadius: 8)
//                                .stroke(Color.yellow, lineWidth: 2)
//                                .frame(width: geometry.size.width * cropRect.width,
//                                       height: geometry.size.height * cropRect.height)
//                                .position(x: geometry.size.width * (cropRect.minX + cropRect.width/2),
//                                         y: geometry.size.height * (cropRect.minY + cropRect.height/2))
//
//                            // Corner handles with drag gestures
//                            Group {
//                                // Top-left handle
//                                Circle()
//                                    .fill(Color.yellow)
//                                    .frame(width: 24, height: 24)
//                                    .position(x: geometry.size.width * cropRect.minX,
//                                             y: geometry.size.height * cropRect.minY)
//                                    .gesture(
//                                        DragGesture()
//                                            .onChanged { value in
//                                                let newX = min(max(value.location.x / geometry.size.width, 0), cropRect.maxX - 0.1)
//                                                let newY = min(max(value.location.y / geometry.size.height, 0), cropRect.maxY - 0.1)
//                                                cropRect = CGRect(x: newX, y: newY,
//                                                                width: cropRect.maxX - newX,
//                                                                height: cropRect.maxY - newY)
//                                            }
//                                    )
//
//                                // Top-right handle
//                                Circle()
//                                    .fill(Color.yellow)
//                                    .frame(width: 24, height: 24)
//                                    .position(x: geometry.size.width * cropRect.maxX,
//                                             y: geometry.size.height * cropRect.minY)
//                                    .gesture(
//                                        DragGesture()
//                                            .onChanged { value in
//                                                let newX = min(max(value.location.x / geometry.size.width, cropRect.minX + 0.1), 1)
//                                                let newY = min(max(value.location.y / geometry.size.height, 0), cropRect.maxY - 0.1)
//                                                cropRect = CGRect(x: cropRect.minX, y: newY,
//                                                                width: newX - cropRect.minX,
//                                                                height: cropRect.maxY - newY)
//                                            }
//                                    )
//
//                                // Bottom-left handle
//                                Circle()
//                                    .fill(Color.yellow)
//                                    .frame(width: 24, height: 24)
//                                    .position(x: geometry.size.width * cropRect.minX,
//                                             y: geometry.size.height * cropRect.maxY)
//                                    .gesture(
//                                        DragGesture()
//                                            .onChanged { value in
//                                                let newX = min(max(value.location.x / geometry.size.width, 0), cropRect.maxX - 0.1)
//                                                let newY = min(max(value.location.y / geometry.size.height, cropRect.minY + 0.1), 1)
//                                                cropRect = CGRect(x: newX, y: cropRect.minY,
//                                                                width: cropRect.maxX - newX,
//                                                                height: newY - cropRect.minY)
//                                            }
//                                    )
//
//                                // Bottom-right handle
//                                Circle()
//                                    .fill(Color.yellow)
//                                    .frame(width: 24, height: 24)
//                                    .position(x: geometry.size.width * cropRect.maxX,
//                                             y: geometry.size.height * cropRect.maxY)
//                                    .gesture(
//                                        DragGesture()
//                                            .onChanged { value in
//                                                let newX = min(max(value.location.x / geometry.size.width, cropRect.minX + 0.1), 1)
//                                                let newY = min(max(value.location.y / geometry.size.height, cropRect.minY + 0.1), 1)
//                                                cropRect = CGRect(x: cropRect.minX, y: cropRect.minY,
//                                                                width: newX - cropRect.minX,
//                                                                height: newY - cropRect.minY)
//                                            }
//                                    )
//                            }
//                        }
//                    }
//                }
//            }
//
//
//            TrimTrackView(
//                trackView: ThumbnailTrackView(images: trackThumbnailImages),
//                viewModel: TrimTrackViewModel(
//                    trimValues: $playerController.trimValues,
//                    minSize: 2,
//                    playerController: playerController
//                ),
//                playerController: playerController
//            )
//            .frame(height: 50)
//
//            HStack {
//                Text("L: \(playerController.trimValues.lowerBound.seconds, specifier: "%.2f")")
//                    .padding(.leading, 10)
//                Spacer()
//                Text("\(playerController.currentTime, specifier: "%.2f")")
//                    .foregroundStyle(.red)
//                    .fontWeight(.semibold)
//                Spacer()
//                Text("R: \(playerController.trimValues.upperBound.seconds, specifier: "%.2f")")
//                    .padding(.trailing, 10)
//            }
//            .opacity(0.6)
//
//            Spacer()
//            
//            HStack {
//                Button(action: { isCropping.toggle() }) {
//                    Image(systemName: "crop")
//                        .font(.system(size: 30))
//                        .foregroundStyle(.yellow)
//                }
//                .buttonStyle(.bordered)
//                
//                Button(action: { @MainActor in playerController.isPlaying ? playerController.pause() : playerController.play() }) {
//                    Image(systemName: playerController.isPlaying ? "pause.fill" : "play.fill")
//                        .font(.system(size: 60))
//                        .foregroundStyle(.yellow)
//                        .fontWeight(.black)
//                }
//                .buttonStyle(.bordered)
//            }
//        }
//    }
//}
