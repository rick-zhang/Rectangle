//
//  DisplayScreenContextResolver.swift
//  Rectangle
//
//  Created by Rectangle contributors.
//

import Cocoa

struct DisplayIdentity: Equatable, CustomDebugStringConvertible {
    let screenNumber: CGDirectDisplayID?
    let frame: CGRect

    init(screenNumber: CGDirectDisplayID? = nil, frame: CGRect) {
        self.screenNumber = screenNumber
        self.frame = frame
    }

    init(screenNumber: NSNumber?, frame: CGRect) {
        self.init(screenNumber: screenNumber?.uint32Value, frame: frame)
    }

    var debugDescription: String {
        let screenNumberDescription = screenNumber.map { String($0) } ?? "nil"
        return "DisplayIdentity(screenNumber: \(screenNumberDescription), frame: \(frame.debugDescription))"
    }
}

extension NSScreen {
    var displayIdentity: DisplayIdentity {
        DisplayIdentity(screenNumber: deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
                        frame: frame)
    }
}

struct DisplayScreenContextResolver {
    struct Diagnostics {
        let matchedScreenIdentity: DisplayIdentity?
        let reason: String
    }

    static func recordedScreenIdentity(executedAction: WindowAction, destinationScreenIdentity: DisplayIdentity?) -> DisplayIdentity? {
        guard executedAction.classification == .display else {
            return nil
        }

        return destinationScreenIdentity
    }

    static func matchingScreenIdentity(lastAction: RectangleAction?,
                                       currentWindowRect: CGRect,
                                       availableScreenIdentities: [DisplayIdentity]) -> DisplayIdentity? {
        diagnostics(lastAction: lastAction,
                    currentWindowRect: currentWindowRect,
                    availableScreenIdentities: availableScreenIdentities).matchedScreenIdentity
    }

    static func diagnostics(lastAction: RectangleAction?,
                            currentWindowRect: CGRect,
                            availableScreenIdentities: [DisplayIdentity]) -> Diagnostics {
        guard let lastAction else {
            return Diagnostics(matchedScreenIdentity: nil, reason: "no last action")
        }

        guard WindowHistoryRectMatcher.matches(lastAction: lastAction, currentWindowRect: currentWindowRect) else {
            return Diagnostics(matchedScreenIdentity: nil, reason: "current window rect differs from last Rectangle result")
        }

        guard let screenIdentity = lastAction.screenIdentity else {
            return Diagnostics(matchedScreenIdentity: nil, reason: "last action did not record a destination screen")
        }

        if let screenNumber = screenIdentity.screenNumber,
           let matchedScreenIdentity = availableScreenIdentities.first(where: { $0.screenNumber == screenNumber }) {
            return Diagnostics(matchedScreenIdentity: matchedScreenIdentity, reason: "matched recorded destination screen number")
        }

        if let matchedScreenIdentity = availableScreenIdentities.first(where: { $0.frame.equalTo(screenIdentity.frame) }) {
            return Diagnostics(matchedScreenIdentity: matchedScreenIdentity, reason: "matched recorded destination frame")
        }

        return Diagnostics(matchedScreenIdentity: nil, reason: "recorded destination screen is no longer available")
    }
}

struct WindowApplyResultMatcher {
    static let tolerance: CGFloat = 8.0

    static func matches(calculatedRect: CGRect, resultingRect: CGRect) -> Bool {
        matches(calculatedRect: calculatedRect, resultingNormalizedRect: resultingRect.screenFlipped)
    }

    static func matches(calculatedRect: CGRect, resultingNormalizedRect: CGRect) -> Bool {
        calculatedRect.isApproximatelyEqual(to: resultingNormalizedRect, tolerance: tolerance)
    }
}

struct WindowHistoryRectMatcher {
    static let defaultTolerance: CGFloat = 1.0
    static let maximizedTolerance: CGFloat = 8.0

    static func matches(lastAction: RectangleAction?, currentWindowRect: CGRect) -> Bool {
        guard let lastAction else { return false }

        return matches(recordedRect: lastAction.rect,
                       currentWindowRect: currentWindowRect,
                       lastAction: lastAction.action)
    }

    static func matches(recordedRect: CGRect, currentWindowRect: CGRect, lastAction: WindowAction) -> Bool {
        currentWindowRect.isApproximatelyEqual(to: recordedRect,
                                               tolerance: tolerance(for: lastAction))
    }

    private static func tolerance(for action: WindowAction) -> CGFloat {
        action == .maximize ? maximizedTolerance : defaultTolerance
    }
}
