//
//  NextPrevDisplayCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 8/19/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

class NextPrevDisplayCalculation: WindowCalculation {
    
    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        let usableScreens = params.usableScreens
        
        guard usableScreens.numScreens > 1 else { return nil }

        var screen: NSScreen?
        
        if params.action == .nextDisplay {
            screen = usableScreens.adjacentScreens?.next
        } else if params.action == .previousDisplay {
            screen = usableScreens.adjacentScreens?.prev
        }

        if let screen = screen {
            let rectParams = params.asRectParams(visibleFrame: screen.adjustedVisibleFrame(params.ignoreTodo))
            let maximizeDecision = displayMoveMaximizeDecision(params)
            logDisplayMoveDecision(params: params, targetScreen: screen, decision: maximizeDecision)
            if maximizeDecision.shouldMaximize {
                let rectResult = WindowCalculationFactory.maximizeCalculation.calculateRect(rectParams)
                return WindowCalculationResult(rect: rectResult.rect, screen: screen, resultingAction: .maximize)
            }
            
            if DisplayMoveLayoutMatchResolver.shouldMatch(lastAction: params.lastAction,
                                                          attemptMatchUserDisabled: Defaults.attemptMatchOnNextPrevDisplay.userDisabled) {
                if let lastAction = params.lastAction,
                   let calculation = WindowCalculationFactory.calculationsByAction[lastAction.action] {
                    
                    AppDelegate.windowHistory.lastRectangleActions.removeValue(forKey: params.window.id)
                    
                    let newCalculationParams = RectCalculationParameters(
                        window: rectParams.window,
                        visibleFrameOfScreen: rectParams.visibleFrameOfScreen,
                        action: lastAction.action,
                        lastAction: nil)
                    let rectResult = calculation.calculateRect(newCalculationParams)
                    
                    return WindowCalculationResult(rect: rectResult.rect, screen: screen, resultingAction: lastAction.action)
                }
            }
            
            let rectResult = calculateRect(rectParams)
            let resultingAction: WindowAction = rectResult.resultingAction ?? params.action
            return WindowCalculationResult(rect: rectResult.rect, screen: screen, resultingAction: resultingAction)
        }
        
        return nil
    }
    
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        if params.lastAction?.action == .maximize && !Defaults.autoMaximize.userDisabled {
            let rectResult = WindowCalculationFactory.maximizeCalculation.calculateRect(params)
            return RectResult(rectResult.rect, resultingAction: .maximize)
        }
        
        return WindowCalculationFactory.centerCalculation.calculateRect(params)
    }

    func shouldMaximizeOnDisplayMove(_ params: WindowCalculationParameters) -> Bool {
        displayMoveMaximizeDecision(params).shouldMaximize
    }

    private func displayMoveMaximizeDecision(_ params: WindowCalculationParameters) -> DisplayMoveMaximizeDecision {
        DisplayMoveMaximizeResolver.decision(
            lastAction: params.lastAction,
            currentWindowRect: params.window.rect,
            sourceVisibleFrame: params.usableScreens.currentScreen.adjustedVisibleFrame(params.ignoreTodo),
            visibleFrames: params.usableScreens.screensOrdered.map { $0.adjustedVisibleFrame(params.ignoreTodo) },
            autoMaximizeUserDisabled: Defaults.autoMaximize.userDisabled
        )
    }

    private func logDisplayMoveDecision(params: WindowCalculationParameters,
                                        targetScreen: NSScreen,
                                        decision: DisplayMoveMaximizeDecision) {
        let sourceVisibleFrame = params.usableScreens.currentScreen.adjustedVisibleFrame(params.ignoreTodo)
        let allVisibleFrames = params.usableScreens.screensOrdered.map { $0.adjustedVisibleFrame(params.ignoreTodo).debugDescription }
        let logItems = [
            "displayMove.calculate",
            "action: \(params.action.name)",
            "windowId: \(params.window.id)",
            "currentWindowRect: \(params.window.rect.debugDescription)",
            "sourceVisibleFrame: \(sourceVisibleFrame.debugDescription)",
            "allVisibleFrames: \(allVisibleFrames.joined(separator: " | "))",
            "sourceScreen: \(params.usableScreens.currentScreen.localizedName)",
            "targetScreen: \(targetScreen.localizedName)",
            "lastAction: \(params.lastAction?.action.name ?? "nil")",
            "lastActionRect: \(params.lastAction?.rect.debugDescription ?? "nil")",
            "lastActionScreenIdentity: \(params.lastAction?.screenIdentity?.debugDescription ?? "nil")",
            "shouldMaximize: \(decision.shouldMaximize)",
            "reason: \(decision.reason)",
            "attemptMatchOnNextPrevDisplay: \(!Defaults.attemptMatchOnNextPrevDisplay.userDisabled)"
        ]
        Logger.diagnostic(logItems.joined(separator: ", "))
    }
}

struct DisplayMoveLayoutMatchResolver {
    static func shouldMatch(lastAction: RectangleAction?, attemptMatchUserDisabled: Bool) -> Bool {
        guard !attemptMatchUserDisabled,
              let lastAction,
              lastAction.action != .maximize
        else {
            return false
        }

        return WindowCalculationFactory.calculationsByAction[lastAction.action] != nil
    }
}

struct DisplayMoveMaximizeDecision {
    let shouldMaximize: Bool
    let reason: String
}

struct DisplayMoveMaximizeResolver {
    static func shouldMaximize(lastAction: RectangleAction?,
                               currentWindowRect: CGRect,
                               sourceVisibleFrame: CGRect,
                               visibleFrames: [CGRect]? = nil,
                               autoMaximizeUserDisabled: Bool) -> Bool {
        decision(lastAction: lastAction,
                 currentWindowRect: currentWindowRect,
                 sourceVisibleFrame: sourceVisibleFrame,
                 visibleFrames: visibleFrames,
                 autoMaximizeUserDisabled: autoMaximizeUserDisabled).shouldMaximize
    }

    static func decision(lastAction: RectangleAction?,
                         currentWindowRect: CGRect,
                         sourceVisibleFrame: CGRect,
                         visibleFrames: [CGRect]? = nil,
                         autoMaximizeUserDisabled: Bool) -> DisplayMoveMaximizeDecision {
        guard !autoMaximizeUserDisabled else {
            return DisplayMoveMaximizeDecision(shouldMaximize: false, reason: "auto maximize disabled")
        }

        if lastAction?.action == .maximize {
            return DisplayMoveMaximizeDecision(shouldMaximize: true, reason: "last action was maximize")
        }

        if currentWindowRect.isApproximatelyEqual(to: sourceVisibleFrame, tolerance: 8.0) {
            return DisplayMoveMaximizeDecision(shouldMaximize: true, reason: "window matches normalized source visible frame")
        }

        if let visibleFrames,
           let matchingVisibleFrame = visibleFrames.first(where: { currentWindowRect.isApproximatelyEqual(to: $0, tolerance: 8.0) }) {
            return DisplayMoveMaximizeDecision(shouldMaximize: true, reason: "window matches a normalized visible frame: \(matchingVisibleFrame.debugDescription)")
        }

        return DisplayMoveMaximizeDecision(shouldMaximize: false, reason: "window does not match normalized source visible frame")
    }
}
