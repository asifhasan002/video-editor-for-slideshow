//
//  TrimValues.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import AVKit

struct TrimValues: Equatable {
    var lowerBound: CMTime = .zero
    var upperBound: CMTime
}
