//
//  WindowManager.swift
//  Rectangle, Ported from Spectacle
//
//  Created by Ryan Hanson on 6/12/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

class WindowManager {
    
    private let screenDetection = ScreenDetection()
    private let standardWindowMoverChain: [WindowMover]
    private let fixedSizeWindowMoverChain: [WindowMover]
    
    init() {
        standardWindowMoverChain = [
            StandardWindowMover(),
            BestEffortWindowMover()
        ]
        
        fixedSizeWindowMoverChain = [
            CenteringFixedSizedWindowMover(),
            BestEffortWindowMover()
        ]
    }
    
    private func recordAction(windowId: CGWindowID, resultingRect: CGRect, action: WindowAction, subAction: SubWindowAction?, screenIdentity: DisplayIdentity?, executedAction: WindowAction) {
        let newCount: Int
        if let lastRectangleAction = AppDelegate.windowHistory.lastRectangleActions[windowId], lastRectangleAction.action == action {
            newCount = lastRectangleAction.count + 1
        } else {
            newCount = 1
        }
        
        AppDelegate.windowHistory.lastRectangleActions[windowId] = RectangleAction(
            action: action,
            subAction: subAction,
            rect: resultingRect,
            count: newCount,
            screenIdentity: DisplayScreenContextResolver.recordedScreenIdentity(executedAction: executedAction,
                                                                                destinationScreenIdentity: screenIdentity)
        )
    }
    
    func execute(_ parameters: ExecutionParameters) {
        guard let frontmostWindowElement = parameters.windowElement ?? AccessibilityElement.getFrontWindowElement(),
              let windowId = parameters.windowId ?? frontmostWindowElement.getWindowId()
        else {
            NSSound.beep()
            return
        }
        
        let action = parameters.action
        
        if action == .restore {
            if let restoreRect = AppDelegate.windowHistory.restoreRects[windowId] {
                frontmostWindowElement.setFrame(restoreRect)
            }
            AppDelegate.windowHistory.lastRectangleActions.removeValue(forKey: windowId)
            return
        }
        
        let currentWindowRect: CGRect = frontmostWindowElement.frame
        let ignoreTodo = TodoManager.isTodoWindow(windowId)
        
        var lastRectangleAction = AppDelegate.windowHistory.lastRectangleActions[windowId]
        
        let windowMovedExternally = !WindowHistoryRectMatcher.matches(lastAction: lastRectangleAction,
                                                                      currentWindowRect: currentWindowRect)

        let historyDetails = DisplayScreenContextResolver.diagnostics(lastAction: lastRectangleAction,
                                                                      currentWindowRect: currentWindowRect,
                                                                      availableScreenIdentities: NSScreen.screens.map { $0.displayIdentity })
        let executeLogItems = [
            "execute",
            "action: \(action.name)",
            "windowId: \(windowId)",
            "currentWindowRect: \(currentWindowRect.debugDescription)",
            "currentNormalizedRect: \(currentWindowRect.screenFlipped.debugDescription)",
            "lastAction: \(lastRectangleAction?.action.name ?? "nil")",
            "lastActionRect: \(lastRectangleAction?.rect.debugDescription ?? "nil")",
            "lastActionScreenIdentity: \(lastRectangleAction?.screenIdentity?.debugDescription ?? "nil")",
            "windowMovedExternally: \(windowMovedExternally)",
            "preservedScreenMatch: \(historyDetails.matchedScreenIdentity?.debugDescription ?? "nil")",
            "preservedScreenReason: \(historyDetails.reason)",
            "availableScreenIdentities: \(NSScreen.screens.map { $0.displayIdentity.debugDescription }.joined(separator: " | "))"
        ]
        Logger.diagnostic(executeLogItems.joined(separator: ", "))
        
        if windowMovedExternally {
            lastRectangleAction = nil
            AppDelegate.windowHistory.lastRectangleActions.removeValue(forKey: windowId)
        }
        
        if parameters.updateRestoreRect {
            if AppDelegate.windowHistory.restoreRects[windowId] == nil
                || windowMovedExternally {
                AppDelegate.windowHistory.restoreRects[windowId] = currentWindowRect
            }
        }
        
        var screens: UsableScreens?
        var screenSelectionSource = "screenDetection"
        if let screen = parameters.screen {
            screens = UsableScreens(currentScreen: screen, numScreens: 1)
            screenSelectionSource = "parameters.screen"
        } else if let screen = preservedScreen(from: lastRectangleAction, currentWindowRect: currentWindowRect) {
            screens = usableScreens(for: screen)
            screenSelectionSource = "preservedScreen"
        } else {
            screens = Defaults.useCursorScreenDetection.enabled
            ? screenDetection.detectScreensAtCursor()
            : screenDetection.detectScreens(using: frontmostWindowElement)
            screenSelectionSource = Defaults.useCursorScreenDetection.enabled ? "cursorDetection" : "windowDetection"
        }

        guard let usableScreens = screens else {
            NSSound.beep()
            Logger.log("Unable to obtain usable screens")
            return
        }

        let screensLogItems = [
            "execute.screens",
            "action: \(action.name)",
            "windowId: \(windowId)",
            "source: \(screenSelectionSource)",
            "currentScreen: \(usableScreens.currentScreen.localizedName)",
            "currentScreenFrame: \(usableScreens.currentScreen.frame.debugDescription)",
            "currentVisibleFrame: \(usableScreens.currentScreen.adjustedVisibleFrame(TodoManager.isTodoWindow(windowId)).debugDescription)",
            "adjacentPrev: \(usableScreens.adjacentScreens?.prev.localizedName ?? "nil")",
            "adjacentNext: \(usableScreens.adjacentScreens?.next.localizedName ?? "nil")"
        ]
        Logger.diagnostic(screensLogItems.joined(separator: ", "))

        if frontmostWindowElement.isSheet == true
            || currentWindowRect.isNull
            || usableScreens.frameOfCurrentScreen.isNull
            || usableScreens.currentScreen.adjustedVisibleFrame(ignoreTodo).isNull {
            NSSound.beep()
            Logger.log("Window is not snappable or usable screen is not valid")
            return
        }
        
        let currentNormalizedRect = currentWindowRect.screenFlipped
        let currentWindow = Window(id: windowId, rect: currentNormalizedRect)
        
        let windowCalculation = WindowCalculationFactory.calculationsByAction[action]
        
        let calculationParams = WindowCalculationParameters(window: currentWindow, usableScreens: usableScreens, action: action, lastAction: lastRectangleAction, ignoreTodo: ignoreTodo)
        guard var calcResult = windowCalculation?.calculate(calculationParams) else {
            NSSound.beep()
            Logger.log("Nil calculation result")
            return
        }
        
        let gapsApplicable = calcResult.resultingAction.gapsApplicable
        
        if Defaults.gapSize.value > 0, gapsApplicable != .none {
            let gapSharedEdges = calcResult.resultingSubAction?.gapSharedEdge ?? calcResult.resultingAction.gapSharedEdge
            
            calcResult.rect = GapCalculation.applyGaps(calcResult.rect, dimension: gapsApplicable, sharedEdges: gapSharedEdges, gapSize: Defaults.gapSize.value)
        }

        if currentNormalizedRect.equalTo(calcResult.rect) {
            Logger.log("Current frame is equal to new frame")
            
            recordAction(windowId: windowId,
                         resultingRect: currentWindowRect,
                         action: calcResult.resultingAction,
                         subAction: calcResult.resultingSubAction,
                         screenIdentity: calcResult.screen.displayIdentity,
                         executedAction: action)
            
            return
        }
        
        let visibleFrameOfDestinationScreen = calcResult.resultingScreenFrame ?? calcResult.screen.adjustedVisibleFrame(ignoreTodo)
        let isFixedSize = (!frontmostWindowElement.isResizable() && action.resizes) || frontmostWindowElement.isSystemDialog == true
        let resultParameters = ResultParameters(windowId: windowId,
                                                action: action,
                                                windowElement: frontmostWindowElement,
                                                calcResult: calcResult,
                                                usableScreens: usableScreens,
                                                visibleFrameOfScreen: visibleFrameOfDestinationScreen,
                                                source: parameters.source,
                                                isFixedSize: isFixedSize)
        
        var resultingRect = apply(result: resultParameters)
        
        let isMovedAcrossDisplays = usableScreens.currentScreen != calcResult.screen
        if isMovedAcrossDisplays {
            if !WindowApplyResultMatcher.matches(calculatedRect: calcResult.rect, resultingRect: resultingRect) {
                Logger.log("Window frame wasn't applied perfectly across displays. Trying again.")
                Logger.diagnostic(applyRetryLogItems(action: action,
                                                     windowId: windowId,
                                                     attempt: 1,
                                                     calculatedRect: calcResult.rect,
                                                     resultingRect: resultingRect).joined(separator: ", "))
                resultingRect = apply(result: resultParameters)
                
                if !WindowApplyResultMatcher.matches(calculatedRect: calcResult.rect, resultingRect: resultingRect) {
                    Logger.log("Final attempt to adjust across displays.")
                    Logger.diagnostic(applyRetryLogItems(action: action,
                                                         windowId: windowId,
                                                         attempt: 2,
                                                         calculatedRect: calcResult.rect,
                                                         resultingRect: resultingRect).joined(separator: ", "))
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(25)) { [weak self] in
                        guard let self else { return }
                        let finalRect = self.apply(result: resultParameters)
                        Logger.diagnostic(self.applyRetryLogItems(action: action,
                                                                  windowId: windowId,
                                                                  attempt: 3,
                                                                  calculatedRect: calcResult.rect,
                                                                  resultingRect: finalRect).joined(separator: ", "))
                        self.windowMovedAcrossDisplays(windowElement: frontmostWindowElement, resultingRect: finalRect)
                        self.postProcess(result: resultParameters, resultingRect: finalRect)
                    }
                    return
                }
            }
            windowMovedAcrossDisplays(windowElement: frontmostWindowElement, resultingRect: resultingRect)
        }
        
        postProcess(result: resultParameters, resultingRect: resultingRect)
    }

    private func applyRetryLogItems(action: WindowAction,
                                    windowId: CGWindowID,
                                    attempt: Int,
                                    calculatedRect: CGRect,
                                    resultingRect: CGRect) -> [String] {
        [
            "apply.retry",
            "action: \(action.name)",
            "windowId: \(windowId)",
            "attempt: \(attempt)",
            "calculatedNormalizedRect: \(calculatedRect.debugDescription)",
            "resultNormalizedRect: \(resultingRect.screenFlipped.debugDescription)",
            "resultRect: \(resultingRect.debugDescription)",
            "matches: \(WindowApplyResultMatcher.matches(calculatedRect: calculatedRect, resultingRect: resultingRect))"
        ]
    }
    
    /// Move/resize a window based on the calculation results.
    /// - Returns: The rect of the window after applying the window action
    func apply(result: ResultParameters) -> CGRect {
        let windowMoverChain = result.isFixedSize
        ? fixedSizeWindowMoverChain
        : standardWindowMoverChain
        
        let newRect = result.calcResult.rect.screenFlipped
        
        for windowMover in windowMoverChain {
            windowMover.moveWindowRect(newRect,
                                       frameOfScreen: result.usableScreens.frameOfCurrentScreen,
                                       visibleFrameOfScreen: result.visibleFrameOfScreen,
                                       frontmostWindowElement: result.windowElement,
                                       action: result.action)
        }
        
        return result.windowElement.frame
    }

    private func preservedScreen(from lastRectangleAction: RectangleAction?, currentWindowRect: CGRect) -> NSScreen? {
        let screens = NSScreen.screens
        guard let screenIdentity = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastRectangleAction,
                                                                                      currentWindowRect: currentWindowRect,
                                                                                      availableScreenIdentities: screens.map { $0.displayIdentity })
        else {
            return nil
        }

        if let screenNumber = screenIdentity.screenNumber,
           let screen = screens.first(where: { $0.displayIdentity.screenNumber == screenNumber }) {
            return screen
        }

        return screens.first { $0.frame.equalTo(screenIdentity.frame) }
    }

    private func usableScreens(for screen: NSScreen) -> UsableScreens {
        let screens = NSScreen.screens
        let screensOrdered = screenDetection.order(screens: screens)
        let adjacentScreens = screenDetection.adjacent(toFrameOfScreen: screen.frame, screens: screensOrdered)
        return UsableScreens(currentScreen: screen,
                             adjacentScreens: adjacentScreens,
                             numScreens: screens.count,
                             screensOrdered: screensOrdered)
    }

    func windowMovedAcrossDisplays(windowElement: AccessibilityElement, resultingRect: CGRect) {
        windowElement.bringToFront(force: true)
        
        if Defaults.moveCursorAcrossDisplays.userEnabled {
            CGWarpMouseCursorPosition(resultingRect.centerPoint)
        }
    }
    
    func postProcess(result: ResultParameters, resultingRect: CGRect) {
        let calcResult = result.calcResult
        
        if Defaults.moveCursor.userEnabled, result.source == .keyboardShortcut {
            CGWarpMouseCursorPosition(resultingRect.centerPoint)
        }
        
        recordAction(windowId: result.windowId,
                     resultingRect: resultingRect,
                     action: calcResult.resultingAction,
                     subAction: calcResult.resultingSubAction,
                     screenIdentity: calcResult.screen.displayIdentity,
                     executedAction: result.action)
        
        var logItems = ["postProcess",
                        "action: \(result.action.name)",
                        "display: \(result.visibleFrameOfScreen.debugDescription)",
                        "calculatedRect: \(result.calcResult.rect.screenFlipped.debugDescription)",
                        "resultRect: \(resultingRect.debugDescription)",
                        "srcScreen: \(result.usableScreens.currentScreen.localizedName)",
                        "destScreen: \(calcResult.screen.localizedName)",
                        "resultingAction: \(calcResult.resultingAction.name)"]
        if let resultScreens = screenDetection.detectScreens(using: result.windowElement) {
            logItems.append("resultScreen: \(resultScreens.currentScreen.localizedName)")
            logItems.append("resultScreenFrame: \(resultScreens.currentScreen.frame.debugDescription)")
        }
        Logger.diagnostic(logItems.joined(separator: ", "))
    }

    struct ResultParameters {
        let windowId: CGWindowID
        let action: WindowAction
        let windowElement: AccessibilityElement
        let calcResult: WindowCalculationResult
        let usableScreens: UsableScreens
        let visibleFrameOfScreen: CGRect
        let source: ExecutionSource
        let isFixedSize: Bool
    }
}

struct RectangleAction {
    let action: WindowAction
    let subAction: SubWindowAction?
    let rect: CGRect
    let count: Int
    let screenIdentity: DisplayIdentity?

    init(action: WindowAction, subAction: SubWindowAction?, rect: CGRect, count: Int, screenIdentity: DisplayIdentity? = nil) {
        self.action = action
        self.subAction = subAction
        self.rect = rect
        self.count = count
        self.screenIdentity = screenIdentity
    }
}

struct ExecutionParameters {
    let action: WindowAction
    let updateRestoreRect: Bool
    let screen: NSScreen?
    let windowElement: AccessibilityElement?
    let windowId: CGWindowID?
    let source: ExecutionSource

    init(_ action: WindowAction, updateRestoreRect: Bool = true, screen: NSScreen? = nil, windowElement: AccessibilityElement? = nil, windowId: CGWindowID? = nil, source: ExecutionSource = .keyboardShortcut) {
        self.action = action
        self.updateRestoreRect = updateRestoreRect
        self.screen = screen
        self.windowElement = windowElement
        self.windowId = windowId
        self.source = source
    }
}

enum ExecutionSource {
    case keyboardShortcut, dragToSnap, menuItem, url, titleBar
}
