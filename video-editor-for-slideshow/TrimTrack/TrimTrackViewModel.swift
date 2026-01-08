//
//  TrimTrackViewModel.swift
//  video-editor-for-slideshow
//
//  Created by Md Asif Hasan on 8/1/26.
//

import SwiftUI
import AVKit

struct TrimTrackViewModel {
    var leadingEdge: CGFloat = 0 {
        didSet {
            self.lowerWidth = adjust(trimValues.lowerBound.seconds) + 12.5
        }
    }
    var trailingEdge: CGFloat = 0 {
        didSet {
            self.upperX = adjust(trimValues.upperBound.seconds) + 25 + 12.5
        }
    }

    var lowerWidth: CGFloat = 0
    var upperX: CGFloat = 0
    var upperWidth: CGFloat = 0

    @Binding private var trimValues: TrimValues

    private let minSize: CGFloat
    private let range: ClosedRange<CGFloat>
    let playerController: any PlayerProtocol

    let draggerWidth: CGFloat = 25

    init(
        trimValues: Binding<TrimValues>,
        minSize: CGFloat,
        playerController: any PlayerProtocol
    ) {
        self._trimValues       = trimValues
        self.minSize          = minSize
        self.range            = CGFloat(trimValues.wrappedValue.lowerBound.seconds)...CGFloat(trimValues.wrappedValue.upperBound.seconds)
        self.playerController = playerController
    }

    mutating func lowerChanged(xPosition: CGFloat) {
        let maxV = trimValues.upperBound.seconds
        let minV = transform(leadingEdge)

        let proposedValue = transform(xPosition + 12.5)
        let newValue = min(max(proposedValue, minV), maxV - minSize)

        self.trimValues.lowerBound = CMTime(
            value: CMTimeValue(newValue * 6000) ,
            timescale: 6000
        )

        self.lowerWidth = adjust(trimValues.lowerBound.seconds) + 12.5
        playerController.handleTrimming(trimValues.lowerBound)
    }

    mutating func upperChanged(xPosition: CGFloat) {
        let minV = trimValues.lowerBound.seconds + minSize
        let maxV = transform(trailingEdge)

        let proposedValue = transform(xPosition - 12.5)
        let newValue = min(max(proposedValue, minV), maxV)
        self.trimValues.upperBound = CMTime(
            value: CMTimeValue(newValue * 6000),
            timescale: 6000
        )

        self.upperX = adjust(trimValues.upperBound.seconds) + 25 + 12.5
        self.upperWidth = adjust(range.upperBound - trimValues.upperBound.seconds)
        playerController.handleTrimming(trimValues.upperBound)
    }

    mutating func currentChanged(xPosition: CGFloat) {
        let maxV = trimValues.upperBound.seconds
        let minV = trimValues.lowerBound.seconds

        let proposedValue = transform(xPosition + 5)
        let newValue = min(max(proposedValue, minV), maxV)

        let time = CMTime(
            value: CMTimeValue(newValue * 6000) ,
            timescale: 6000
        )
        playerController.handleTrimming(time)
    }

    func currentTimePosition(_ time: CGFloat) -> CGFloat {
        adjust(time) + draggerWidth
    }
}

private extension TrimTrackViewModel {
    func adjust(_ value: CGFloat) -> CGFloat {
        let width = trailingEdge - leadingEdge

        let valueRange = range.upperBound - range.lowerBound

        return (value / valueRange) * width
    }

    func transform(_ position: CGFloat) -> CGFloat {
        let width = trailingEdge - leadingEdge

        let valueRange = range.upperBound - range.lowerBound

        return ((position - 25) / width) * valueRange
    }
}
