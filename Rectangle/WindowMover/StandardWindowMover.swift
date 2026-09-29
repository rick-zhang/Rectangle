/// StandardWindowMover.swift

import Foundation

class StandardWindowMover: WindowMover {
    func moveWindow(toRect rect: CGRect, resultParameters: ResultParameters) {
        let windowElement = resultParameters.windowElement
        if windowElement.frame.isNull { return }
        windowElement.setFrame(rect.screenFlipped,
                               adjustSizeFirst: shouldAdjustSizeFirst(resultParameters.action)) { adjustedSize in
            let adjustedOrigin = WindowFrameApplyStrategy.adjustedOriginAfterInitialSize(
                targetWindowRect: rect.screenFlipped,
                targetNormalizedRect: rect,
                sourceScreenFrame: resultParameters.usableScreens.frameOfCurrentScreen,
                destinationVisibleFrame: resultParameters.visibleFrameOfScreen,
                adjustedSize: adjustedSize)
            if let adjustedOrigin {
                Logger.diagnostic("跨屏初次调整尺寸后修正位置：\(adjustedOrigin)，实际尺寸：\(adjustedSize)")
            }
            return adjustedOrigin
        }
    }
    
    private func shouldAdjustSizeFirst(_ action: WindowAction) -> Bool {
        switch (action, Defaults.cornerCycleExpansionAxis.value) {
        case (.topRight, .horizontal),
             (.bottomRight, .horizontal),
             (.bottomLeft, .vertical),
             (.bottomRight, .vertical):
            return false
        default:
            return true
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
