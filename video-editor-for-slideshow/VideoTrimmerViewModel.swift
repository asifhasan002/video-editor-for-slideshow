//
//  VideoTrimmerViewModel.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI

struct VideoTrimmerViewModel {
    @State var isExporting = false
    @State var alertMessage: String = ""
    @State var presentAlert = false

    let aspectRatio: CGFloat

    init(aspectRatio: CGFloat) {
        self.aspectRatio = aspectRatio
    }
}
