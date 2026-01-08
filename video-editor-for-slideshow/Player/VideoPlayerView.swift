//
//  VideoPlayerView.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI
import AVKit

struct VideoPlayerView: View {
    let player: AVPlayer
    let start = Date()

    init(player: AVPlayer) {
        self.player = player
    }

    var body: some View {
            TimelineView(.animation) { timeline in
        ZStack {
            VideoPlayer(player: player)

            let time = start.distance(to: timeline.date)

            Text("VEED.IO")
                .font(.system(size: 60))
                .fontWeight(.black)
                .foregroundStyle(.white.opacity(0.5))
                .visualEffect { content, proxy in
                    content
                        .distortionEffect(
                            ShaderLibrary.ripple(
                                .float2(proxy.size),
                                .float(time)
                            ),
                            maxSampleOffset: .init(width: proxy.size.width * 1.1, height: .zero)
                        )
                        .colorEffect(
                            ShaderLibrary.glare(
                                .float2(proxy.size),
                                .float(time)
                            )
                        )
                }
        }
        }
    }
}
