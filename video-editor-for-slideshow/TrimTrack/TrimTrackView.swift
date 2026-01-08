//
//  TrimTrackView.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI
import AVKit

struct TrimTrackView<TrackView: View>: View {
    var trackView: TrackView
    @State var viewModel: TrimTrackViewModel

    @ObservedObject var playerController: PlayerController

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.secondary)
                trackView
                    .mask {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: viewModel.lowerWidth)
                            Rectangle().opacity(1)
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: viewModel.upperWidth)
                        }
                    }
                    .padding(.horizontal, viewModel.draggerWidth / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { viewModel.currentChanged(xPosition: $0.location.x) }
                            .onEnded { _ in playerController.finishTrimming() }
                    )

                Rectangle()
                    .frame(width: 5, height: geometry.size.height)
                    .position(
                        x: viewModel.currentTimePosition(playerController.currentTime),
                        y: geometry.size.height / 2
                    )
                    .foregroundColor(.white)

                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: viewModel.draggerWidth)
                    .overlay {
                        Image(systemName: "chevron.compact.left")
                    }
                    .position(
                        CGPoint(
                            x: viewModel.lowerWidth,
                            y: geometry.size.height / 2
                        )
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { viewModel.lowerChanged(xPosition: $0.location.x) }
                            .onEnded { _ in playerController.finishTrimming() }
                    )


                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: viewModel.draggerWidth)
                    .overlay {
                        Image(systemName: "chevron.compact.right")
                    }
                    .position(
                        CGPoint(
                            x: viewModel.upperX,
                            y: geometry.size.height / 2
                        )
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { viewModel.upperChanged(xPosition: $0.location.x) }
                            .onEnded { _ in playerController.finishTrimming() }
                    )
            }
            .onAppear {
                self.viewModel.leadingEdge  = geometry.frame(in: .local).minX + viewModel.draggerWidth
                self.viewModel.trailingEdge = geometry.frame(in: .local).maxX - viewModel.draggerWidth
            }
        }
    }
}
