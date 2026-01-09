import SwiftUI
import CoreMedia

struct VideoTrimmerView: View {
    @State var viewModel: VideoTrimmerViewModel
    @StateObject var playerController: PlayerController
    @State private var cropRect = CGRect(x: 0, y: 0, width: 1, height: 1) // normalized coordinates - full bounds
    @State private var isFlipped = false
    @State private var rotationAngle: Angle = .zero // rotation angle for video

    let start = Date()
    let trackThumbnailImages: [UIImage]

    init(videoModel: VideoModel) {
        self._playerController = StateObject(wrappedValue: PlayerController(videoModel: videoModel))
        self.viewModel = VideoTrimmerViewModel(aspectRatio: videoModel.aspectRatio)
        self.trackThumbnailImages = videoModel.images
    }

    var body: some View {
        VStack(spacing: 10) {
            // Outer GeometryReader to get available space and compute fitting sizes
            GeometryReader { outerGeo in
                let availSize = outerGeo.size
                let degrees = rotationAngle.degrees.truncatingRemainder(dividingBy: 360)
                let absDegrees = abs(degrees)
                let isSwapped = (absDegrees == 90 || absDegrees == 270)
                let contentAR = viewModel.aspectRatio
                let effectiveAR = isSwapped ? 1 / contentAR : contentAR
                let fitW = min(availSize.width, availSize.height * effectiveAR)
                let fitH = min(availSize.height, availSize.width / effectiveAR)
                let innerW = isSwapped ? fitH : fitW
                let innerH = isSwapped ? fitW : fitH

                ZStack {
                    VideoPlayerView(player: playerController.player)
                        .scaleEffect(x: isFlipped ? -1 : 1, y: 1)
                        // Removed .aspectRatio here; the frame will handle sizing

                    // Free form cropping overlay - constrained to video bounds
                    GeometryReader { geometry in
                        ZStack {
                            // Calculate video display bounds
                            let videoWidth = min(geometry.size.width, geometry.size.height * viewModel.aspectRatio)
                            let videoHeight = min(geometry.size.height, geometry.size.width / viewModel.aspectRatio)
                            let videoX = (geometry.size.width - videoWidth) / 2
                            let videoY = (geometry.size.height - videoHeight) / 2

                            // Semi-transparent overlay only within video bounds
                            Color.black.opacity(0.3)
                                .frame(width: videoWidth, height: videoHeight)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                            // Crop rectangle within video bounds
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow, lineWidth: 2)
                                .frame(width: videoWidth * cropRect.width,
                                       height: videoHeight * cropRect.height)
                                .position(x: videoX + videoWidth * (cropRect.minX + cropRect.width/2),
                                         y: videoY + videoHeight * (cropRect.minY + cropRect.height/2))

                            // Corner handles with drag gestures
                            Group {
                                // Top-left handle
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 24, height: 24)
                                    .position(x: videoX + videoWidth * cropRect.minX,
                                             y: videoY + videoHeight * cropRect.minY)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let localX = (value.location.x - videoX) / videoWidth
                                                let localY = (value.location.y - videoY) / videoHeight
                                                let newX = min(max(localX, 0), cropRect.maxX - 0.1)
                                                let newY = min(max(localY, 0), cropRect.maxY - 0.1)
                                                cropRect = CGRect(x: newX, y: newY,
                                                                width: cropRect.maxX - newX,
                                                                height: cropRect.maxY - newY)
                                            }
                                    )

                                // Top-right handle
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 24, height: 24)
                                    .position(x: videoX + videoWidth * cropRect.maxX,
                                             y: videoY + videoHeight * cropRect.minY)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let localX = (value.location.x - videoX) / videoWidth
                                                let localY = (value.location.y - videoY) / videoHeight
                                                let newX = min(max(localX, cropRect.minX + 0.1), 1)
                                                let newY = min(max(localY, 0), cropRect.maxY - 0.1)
                                                cropRect = CGRect(x: cropRect.minX, y: newY,
                                                                width: newX - cropRect.minX,
                                                                height: cropRect.maxY - newY)
                                            }
                                    )

                                // Bottom-left handle
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 24, height: 24)
                                    .position(x: videoX + videoWidth * cropRect.minX,
                                             y: videoY + videoHeight * cropRect.maxY)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let localX = (value.location.x - videoX) / videoWidth
                                                let localY = (value.location.y - videoY) / videoHeight
                                                let newX = min(max(localX, 0), cropRect.maxX - 0.1)
                                                let newY = min(max(localY, cropRect.minY + 0.1), 1)
                                                cropRect = CGRect(x: newX, y: cropRect.minY,
                                                                width: cropRect.maxX - newX,
                                                                height: newY - cropRect.minY)
                                            }
                                    )

                                // Bottom-right handle
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 24, height: 24)
                                    .position(x: videoX + videoWidth * cropRect.maxX,
                                             y: videoY + videoHeight * cropRect.maxY)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { value in
                                                let localX = (value.location.x - videoX) / videoWidth
                                                let localY = (value.location.y - videoY) / videoHeight
                                                let newX = min(max(localX, cropRect.minX + 0.1), 1)
                                                let newY = min(max(localY, cropRect.minY + 0.1), 1)
                                                cropRect = CGRect(x: cropRect.minX, y: cropRect.minY,
                                                                width: newX - cropRect.minX,
                                                                height: newY - cropRect.minY)
                                            }
                                    )
                            }
                        }
                    }
                }
                .frame(width: innerW, height: innerH)
                .rotationEffect(rotationAngle)
                .position(x: availSize.width / 2, y: availSize.height / 2)
            }

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

            HStack(spacing: 30) {
                Button(action: {
                    // Rotate 90 degrees clockwise
                    rotationAngle += .degrees(90)
                    // Normalize the angle to prevent potential floating-point or rendering issues with large values
                    var normalizedDegrees = rotationAngle.degrees.truncatingRemainder(dividingBy: 360)
                    if normalizedDegrees < 0 {
                        normalizedDegrees += 360
                    }
                    rotationAngle = .degrees(normalizedDegrees)
                    // Optionally, transform cropRect here if needed to maintain relative crop area
                }) {
                    Image(systemName: "rotate.right")
                        .font(.system(size: 30))
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.bordered)

            HStack {
                Button(action: { @MainActor in playerController.isPlaying ? playerController.pause() : playerController.play() }) {
                    Image(systemName: playerController.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)
                        .fontWeight(.black)
                }
                .buttonStyle(.bordered)

                Button(action: { isFlipped.toggle() }) {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                        .font(.system(size: 30))
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.bordered)
            }
            }
        }
    }
}
