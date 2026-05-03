//
//  StandardWindowMover.swift
//  Rectangle, Ported from Spectacle
//
//  Created by Ryan Hanson on 6/13/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class StandardWindowMover: WindowMover {
    func moveWindowRect(_ windowRect: CGRect, frameOfScreen: CGRect, visibleFrameOfScreen: CGRect, frontmostWindowElement: AccessibilityElement?, action: WindowAction?) {
        let previousWindowRect: CGRect? = frontmostWindowElement?.frame
        if previousWindowRect?.isNull == true {
            return
        }
        let targetNormalizedRect = windowRect.screenFlipped
        frontmostWindowElement?.setFrame(windowRect) { adjustedSize in
            let adjustedOrigin = WindowFrameApplyStrategy.adjustedOriginAfterInitialSize(
                targetWindowRect: windowRect,
                targetNormalizedRect: targetNormalizedRect,
                sourceScreenFrame: frameOfScreen,
                destinationVisibleFrame: visibleFrameOfScreen,
                adjustedSize: adjustedSize)

            if let adjustedOrigin {
                Logger.diagnostic([
                    "apply.positionAfterInitialSize",
                    "action: \(action?.name ?? "nil")",
                    "targetRect: \(windowRect.debugDescription)",
                    "targetNormalizedRect: \(targetNormalizedRect.debugDescription)",
                    "adjustedSize: \(adjustedSize.debugDescription)",
                    "adjustedOrigin: \(adjustedOrigin.debugDescription)",
                    "sourceScreenFrame: \(frameOfScreen.debugDescription)",
                    "destinationVisibleFrame: \(visibleFrameOfScreen.debugDescription)"
                ].joined(separator: ", "))
            }

            return adjustedOrigin
        }
    }
}

struct WindowFrameApplyStrategy {
    static let tolerance: CGFloat = 1.0

    static func adjustedOriginAfterInitialSize(targetWindowRect: CGRect,
                                               targetNormalizedRect: CGRect,
                                               sourceScreenFrame: CGRect,
                                               destinationVisibleFrame: CGRect,
                                               adjustedSize: CGSize) -> CGPoint? {
        guard shouldAdjustPositionAfterInitialSize(targetNormalizedRect: targetNormalizedRect,
                                                   sourceScreenFrame: sourceScreenFrame,
                                                   destinationVisibleFrame: destinationVisibleFrame)
        else {
            return nil
        }

        var adjustedOrigin = targetWindowRect.origin

        let widthDelta = adjustedSize.width - targetWindowRect.width
        if widthDelta > tolerance,
           approximatelyEqual(targetNormalizedRect.maxX, destinationVisibleFrame.maxX) {
            adjustedOrigin.x -= widthDelta
        }

        let heightDelta = adjustedSize.height - targetWindowRect.height
        if heightDelta > tolerance,
           approximatelyEqual(targetNormalizedRect.minY, destinationVisibleFrame.minY) {
            adjustedOrigin.y -= heightDelta
        }

        return adjustedOrigin == targetWindowRect.origin ? nil : adjustedOrigin
    }

    private static func shouldAdjustPositionAfterInitialSize(targetNormalizedRect: CGRect,
                                                             sourceScreenFrame: CGRect,
                                                             destinationVisibleFrame: CGRect) -> Bool {
        guard !targetNormalizedRect.isNull,
              !sourceScreenFrame.isNull,
              !destinationVisibleFrame.isNull,
              targetNormalizedRect.intersects(destinationVisibleFrame)
        else {
            return false
        }

        return !sourceScreenFrame.contains(destinationVisibleFrame.centerPoint)
    }

    private static func approximatelyEqual(_ lhs: CGFloat, _ rhs: CGFloat) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
}
