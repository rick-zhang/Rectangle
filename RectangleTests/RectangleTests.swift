//
//  RectangleTests.swift
//  RectangleTests
//
//  Created by Ryan Hanson on 6/11/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import XCTest
@testable import Rectangle

class RectangleTests: XCTestCase {

    private func displayIdentity(_ frame: CGRect, screenNumber: CGDirectDisplayID? = nil) -> DisplayIdentity {
        DisplayIdentity(screenNumber: screenNumber, frame: frame)
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testDisplayScreenContextResolverReturnsRecordedScreenWhenWindowUnchanged() {
        let windowRect = CGRect(x: 1920, y: 0, width: 800, height: 600)
        let destinationScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440), screenNumber: 22)
        let sourceScreen = displayIdentity(CGRect(x: 0, y: 0, width: 1920, height: 1080), screenNumber: 11)
        let lastAction = RectangleAction(action: .nextDisplay,
                                         subAction: nil,
                                         rect: windowRect,
                                         count: 1,
                                         screenIdentity: destinationScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: windowRect,
                                                                         availableScreenIdentities: [sourceScreen, destinationScreen])

        XCTAssertEqual(result, destinationScreen)
    }

    func testDisplayScreenContextResolverReturnsRecordedScreenForSmallFrameDrift() {
        let recordedRect = CGRect(x: 86, y: 1123, width: 1710, height: 1069)
        let currentRect = CGRect(x: 86.5, y: 1122.5, width: 1709.5, height: 1069)
        let destinationScreen = displayIdentity(CGRect(x: 0, y: -1112, width: 1710, height: 1112), screenNumber: 22)
        let sourceScreen = displayIdentity(CGRect(x: 0, y: 0, width: 1920, height: 1080), screenNumber: 11)
        let lastAction = RectangleAction(action: .nextDisplay,
                                         subAction: nil,
                                         rect: recordedRect,
                                         count: 1,
                                         screenIdentity: destinationScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: currentRect,
                                                                         availableScreenIdentities: [sourceScreen, destinationScreen])

        XCTAssertEqual(result, destinationScreen)
    }

    func testDisplayScreenContextResolverSupportsPreviousDisplayContext() {
        let windowRect = CGRect(x: 0, y: 0, width: 800, height: 600)
        let destinationScreen = displayIdentity(CGRect(x: 0, y: 0, width: 1920, height: 1080), screenNumber: 11)
        let sourceScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440), screenNumber: 22)
        let lastAction = RectangleAction(action: .previousDisplay,
                                         subAction: nil,
                                         rect: windowRect,
                                         count: 1,
                                         screenIdentity: destinationScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: windowRect,
                                                                         availableScreenIdentities: [destinationScreen, sourceScreen])

        XCTAssertEqual(result, destinationScreen)
    }

    func testDisplayScreenContextResolverReturnsNilWhenWindowMovedExternally() {
        let recordedRect = CGRect(x: 1920, y: 0, width: 800, height: 600)
        let currentRect = CGRect(x: 2000, y: 0, width: 800, height: 600)
        let destinationScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440), screenNumber: 22)
        let lastAction = RectangleAction(action: .nextDisplay,
                                         subAction: nil,
                                         rect: recordedRect,
                                         count: 1,
                                         screenIdentity: destinationScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: currentRect,
                                                                         availableScreenIdentities: [destinationScreen])

        XCTAssertNil(result)
    }

    func testDisplayScreenContextResolverReturnsNilWhenRecordedScreenUnavailable() {
        let windowRect = CGRect(x: 1920, y: 0, width: 800, height: 600)
        let recordedScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440), screenNumber: 22)
        let currentScreen = displayIdentity(CGRect(x: 0, y: 0, width: 1920, height: 1080), screenNumber: 11)
        let lastAction = RectangleAction(action: .nextDisplay,
                                         subAction: nil,
                                         rect: windowRect,
                                         count: 1,
                                         screenIdentity: recordedScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: windowRect,
                                                                         availableScreenIdentities: [currentScreen])

        XCTAssertNil(result)
    }

    func testDisplayScreenContextResolverMatchesScreenNumberBeforeFrame() {
        let windowRect = CGRect(x: 1920, y: 0, width: 800, height: 600)
        let recordedScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440), screenNumber: 22)
        let currentDestinationScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 3008, height: 1692), screenNumber: 22)
        let oldFrameDifferentScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440), screenNumber: 33)
        let lastAction = RectangleAction(action: .nextDisplay,
                                         subAction: nil,
                                         rect: windowRect,
                                         count: 1,
                                         screenIdentity: recordedScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: windowRect,
                                                                         availableScreenIdentities: [oldFrameDifferentScreen, currentDestinationScreen])

        XCTAssertEqual(result, currentDestinationScreen)
    }

    func testDisplayScreenContextResolverFallsBackToFrameWhenScreenNumberUnavailable() {
        let windowRect = CGRect(x: 1920, y: 0, width: 800, height: 600)
        let destinationScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440))
        let lastAction = RectangleAction(action: .nextDisplay,
                                         subAction: nil,
                                         rect: windowRect,
                                         count: 1,
                                         screenIdentity: destinationScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: windowRect,
                                                                         availableScreenIdentities: [destinationScreen])

        XCTAssertEqual(result, destinationScreen)
    }

    func testDisplayScreenContextResolverFallsBackToFrameWhenScreenNumberChanged() {
        let windowRect = CGRect(x: 1920, y: 0, width: 800, height: 600)
        let screenFrame = CGRect(x: 1920, y: 0, width: 2560, height: 1440)
        let recordedScreen = displayIdentity(screenFrame, screenNumber: 22)
        let currentDestinationScreen = displayIdentity(screenFrame, screenNumber: 33)
        let lastAction = RectangleAction(action: .nextDisplay,
                                         subAction: nil,
                                         rect: windowRect,
                                         count: 1,
                                         screenIdentity: recordedScreen)

        let result = DisplayScreenContextResolver.matchingScreenIdentity(lastAction: lastAction,
                                                                         currentWindowRect: windowRect,
                                                                         availableScreenIdentities: [currentDestinationScreen])

        XCTAssertEqual(result, currentDestinationScreen)
    }

    func testRecordedScreenIdentityOnlyPersistsForDisplayActions() {
        let destinationScreen = displayIdentity(CGRect(x: 1920, y: 0, width: 2560, height: 1440), screenNumber: 22)

        XCTAssertEqual(DisplayScreenContextResolver.recordedScreenIdentity(executedAction: .nextDisplay,
                                                                           destinationScreenIdentity: destinationScreen),
                       destinationScreen)
        XCTAssertNil(DisplayScreenContextResolver.recordedScreenIdentity(executedAction: .maximize,
                                                                         destinationScreenIdentity: destinationScreen))
    }

    func testDisplayMoveMaximizeResolverMaximizesWhenWindowAlreadyMatchesSourceVisibleFrame() {
        let sourceVisibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1055)
        let currentWindowRect = CGRect(x: 0, y: 0, width: 1920, height: 1055)

        XCTAssertTrue(DisplayMoveMaximizeResolver.shouldMaximize(lastAction: nil,
                                                                 currentWindowRect: currentWindowRect,
                                                                 sourceVisibleFrame: sourceVisibleFrame,
                                                                 autoMaximizeUserDisabled: false))
    }

    func testDisplayMoveMaximizeResolverMaximizesWhenSourceVisibleFrameHasNonZeroOrigin() {
        let sourceVisibleFrame = CGRect(x: 1920, y: 324, width: 1344, height: 731)
        let currentWindowRect = CGRect(x: 1920, y: 324, width: 1344, height: 731)

        XCTAssertTrue(DisplayMoveMaximizeResolver.shouldMaximize(lastAction: nil,
                                                                 currentWindowRect: currentWindowRect,
                                                                 sourceVisibleFrame: sourceVisibleFrame,
                                                                 autoMaximizeUserDisabled: false))
    }

    func testDisplayMoveMaximizeResolverAllowsSmallVisibleFrameDrift() {
        let sourceVisibleFrame = CGRect(x: 1920, y: 324, width: 1344, height: 731)
        let currentWindowRect = CGRect(x: 1922, y: 326, width: 1340, height: 727)

        XCTAssertTrue(DisplayMoveMaximizeResolver.shouldMaximize(lastAction: nil,
                                                                 currentWindowRect: currentWindowRect,
                                                                 sourceVisibleFrame: sourceVisibleFrame,
                                                                 autoMaximizeUserDisabled: false))
    }

    func testDisplayMoveMaximizeResolverMaximizesWhenWindowMatchesAnyVisibleFrame() {
        let detectedSourceVisibleFrame = CGRect(x: 0, y: 0, width: 1728, height: 1079)
        let actualWindowVisibleFrame = CGRect(x: -1728, y: 240, width: 1344, height: 731)
        let currentWindowRect = CGRect(x: -1728, y: 240, width: 1344, height: 731)

        XCTAssertTrue(DisplayMoveMaximizeResolver.shouldMaximize(lastAction: nil,
                                                                 currentWindowRect: currentWindowRect,
                                                                 sourceVisibleFrame: detectedSourceVisibleFrame,
                                                                 visibleFrames: [detectedSourceVisibleFrame, actualWindowVisibleFrame],
                                                                 autoMaximizeUserDisabled: false))
    }

    func testDisplayMoveMaximizeResolverDoesNotMaximizeWhenWindowIsNotMaximized() {
        let sourceVisibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1055)
        let currentWindowRect = CGRect(x: 100, y: 125, width: 1470, height: 855)

        XCTAssertFalse(DisplayMoveMaximizeResolver.shouldMaximize(lastAction: nil,
                                                                  currentWindowRect: currentWindowRect,
                                                                  sourceVisibleFrame: sourceVisibleFrame,
                                                                  autoMaximizeUserDisabled: false))
    }

    func testDisplayMoveMaximizeResolverRespectsAutoMaximizeDisabled() {
        let sourceVisibleFrame = CGRect(x: 0, y: 0, width: 1920, height: 1055)
        let currentWindowRect = CGRect(x: 0, y: 0, width: 1920, height: 1055)

        XCTAssertFalse(DisplayMoveMaximizeResolver.shouldMaximize(lastAction: nil,
                                                                  currentWindowRect: currentWindowRect,
                                                                  sourceVisibleFrame: sourceVisibleFrame,
                                                                  autoMaximizeUserDisabled: true))
    }

    func testDisplayMoveLayoutMatchResolverMatchesPreviousNonMaximizeLayoutByDefault() {
        let lastAction = RectangleAction(action: .leftHalf,
                                         subAction: nil,
                                         rect: CGRect(x: 0, y: 0, width: 934, height: 1050),
                                         count: 1)

        XCTAssertTrue(DisplayMoveLayoutMatchResolver.shouldMatch(lastAction: lastAction,
                                                                 attemptMatchUserDisabled: false))
    }

    func testDisplayMoveLayoutMatchResolverRespectsExplicitDisable() {
        let lastAction = RectangleAction(action: .leftHalf,
                                         subAction: nil,
                                         rect: CGRect(x: 0, y: 0, width: 934, height: 1050),
                                         count: 1)

        XCTAssertFalse(DisplayMoveLayoutMatchResolver.shouldMatch(lastAction: lastAction,
                                                                  attemptMatchUserDisabled: true))
    }

    func testDisplayMoveLayoutMatchResolverLeavesMaximizeToMaximizeResolver() {
        let lastAction = RectangleAction(action: .maximize,
                                         subAction: nil,
                                         rect: CGRect(x: 0, y: 0, width: 1868, height: 1050),
                                         count: 1)

        XCTAssertFalse(DisplayMoveLayoutMatchResolver.shouldMatch(lastAction: lastAction,
                                                                  attemptMatchUserDisabled: false))
    }

    func testWindowApplyResultMatcherRequiresWholeFrameMatch() {
        let calculatedRect = CGRect(x: 0, y: 0, width: 1728, height: 1079)
        let resultingNormalizedRect = CGRect(x: -1728, y: 240, width: 1344, height: 1079)

        XCTAssertFalse(WindowApplyResultMatcher.matches(calculatedRect: calculatedRect,
                                                        resultingNormalizedRect: resultingNormalizedRect))
    }

    func testWindowApplyResultMatcherAllowsSmallWholeFrameDrift() {
        let calculatedRect = CGRect(x: 0, y: 0, width: 1728, height: 1079)
        let resultingNormalizedRect = CGRect(x: 2, y: 2, width: 1724, height: 1075)

        XCTAssertTrue(WindowApplyResultMatcher.matches(calculatedRect: calculatedRect,
                                                       resultingNormalizedRect: resultingNormalizedRect))
    }

    func testWindowHistoryRectMatcherAllowsMaximizeFrameDrift() {
        let recordedRect = CGRect(x: 0, y: 25, width: 1728, height: 1054)
        let currentRect = CGRect(x: 2, y: 23, width: 1724, height: 1050)

        XCTAssertTrue(WindowHistoryRectMatcher.matches(recordedRect: recordedRect,
                                                       currentWindowRect: currentRect,
                                                       lastAction: .maximize))
    }

    func testWindowHistoryRectMatcherKeepsTightToleranceForNonMaximizeActions() {
        let recordedRect = CGRect(x: 0, y: 25, width: 864, height: 1054)
        let currentRect = CGRect(x: 2, y: 23, width: 860, height: 1050)

        XCTAssertFalse(WindowHistoryRectMatcher.matches(recordedRect: recordedRect,
                                                        currentWindowRect: currentRect,
                                                        lastAction: .leftHalf))
    }

    func testWindowFrameApplyStrategyAdjustsBottomAnchoredCrossDisplayForCoercedHeight() {
        let sourceScreenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let destinationVisibleFrame = CGRect(x: 0, y: -756, width: 1344, height: 726)
        let targetNormalizedRect = CGRect(x: 0, y: -756, width: 1344, height: 363)
        let targetWindowRect = CGRect(x: 0, y: 1473, width: 1344, height: 363)

        let result = WindowFrameApplyStrategy.adjustedOriginAfterInitialSize(
            targetWindowRect: targetWindowRect,
            targetNormalizedRect: targetNormalizedRect,
            sourceScreenFrame: sourceScreenFrame,
            destinationVisibleFrame: destinationVisibleFrame,
            adjustedSize: CGSize(width: 1344, height: 375))

        XCTAssertEqual(result, CGPoint(x: 0, y: 1461))
    }

    func testWindowFrameApplyStrategyDoesNotAdjustWhenTargetSizeWasApplied() {
        let sourceScreenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let destinationVisibleFrame = CGRect(x: 0, y: -756, width: 1344, height: 726)
        let targetNormalizedRect = CGRect(x: 0, y: -756, width: 1344, height: 363)
        let targetWindowRect = CGRect(x: 0, y: 1473, width: 1344, height: 363)

        let result = WindowFrameApplyStrategy.adjustedOriginAfterInitialSize(
            targetWindowRect: targetWindowRect,
            targetNormalizedRect: targetNormalizedRect,
            sourceScreenFrame: sourceScreenFrame,
            destinationVisibleFrame: destinationVisibleFrame,
            adjustedSize: CGSize(width: 1344, height: 363))

        XCTAssertNil(result)
    }

    func testWindowFrameApplyStrategyDoesNotAdjustSameDisplayMoves() {
        let sourceScreenFrame = CGRect(x: 0, y: -756, width: 1344, height: 756)
        let destinationVisibleFrame = CGRect(x: 0, y: -756, width: 1344, height: 726)
        let targetNormalizedRect = CGRect(x: 0, y: -756, width: 1344, height: 363)
        let targetWindowRect = CGRect(x: 0, y: 1473, width: 1344, height: 363)

        let result = WindowFrameApplyStrategy.adjustedOriginAfterInitialSize(
            targetWindowRect: targetWindowRect,
            targetNormalizedRect: targetNormalizedRect,
            sourceScreenFrame: sourceScreenFrame,
            destinationVisibleFrame: destinationVisibleFrame,
            adjustedSize: CGSize(width: 1344, height: 375))

        XCTAssertNil(result)
    }

    func testWindowFrameApplyStrategyKeepsTopAnchoredOriginWhenHeightIsCoerced() {
        let sourceScreenFrame = CGRect(x: 0, y: 0, width: 1920, height: 1080)
        let destinationVisibleFrame = CGRect(x: 0, y: -756, width: 1344, height: 726)
        let targetNormalizedRect = CGRect(x: 0, y: -393, width: 1344, height: 363)
        let targetWindowRect = CGRect(x: 0, y: 1110, width: 1344, height: 363)

        let result = WindowFrameApplyStrategy.adjustedOriginAfterInitialSize(
            targetWindowRect: targetWindowRect,
            targetNormalizedRect: targetNormalizedRect,
            sourceScreenFrame: sourceScreenFrame,
            destinationVisibleFrame: destinationVisibleFrame,
            adjustedSize: CGSize(width: 1344, height: 375))

        XCTAssertNil(result)
    }

}
