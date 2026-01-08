//
//  ThumbnailTrackView.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI

struct ThumbnailTrackView: View {
    let images: [UIImage]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(images, id: \.self) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}
