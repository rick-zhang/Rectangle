# Repository Guidelines

## Project Structure & Module Organization

Rectangle is a macOS AppKit project built from `Rectangle.xcodeproj`. The main app lives in `Rectangle/`, with feature areas split into folders such as `WindowCalculation/`, `Snapping/`, `MultiWindow/`, `Utilities/`, `Logging/`, and `WelcomeWindow/`. `RectangleLauncher/` contains the helper launcher target. Tests are in `RectangleTests/`. UI and assets are stored beside their targets in `Base.lproj/*.storyboard`, `*.xib`, `*.xcassets`, and `mul.lproj/Main.xcstrings`.

## Build, Test, and Development Commands

- `open Rectangle.xcodeproj`: open the project in Xcode for local development.
- `xcodebuild -project Rectangle.xcodeproj -scheme Rectangle -configuration Debug build CODE_SIGN_IDENTITY="-"`: build the app without local signing credentials.
- `xcodebuild test -project Rectangle.xcodeproj -scheme Rectangle -destination 'platform=macOS' CODE_SIGN_IDENTITY="-"`: run the XCTest target.
- `xcodebuild -project Rectangle.xcodeproj -scheme Rectangle archive CODE_SIGN_IDENTITY="-" -archivePath build/Rectangle.xcarchive`: match the CI archive step before export.

Swift Package Manager dependencies, including Sparkle and the Rectangle fork of MASShortcut, are resolved by Xcode.

## Coding Style & Naming Conventions

Use Swift 5 and match the surrounding AppKit style. Keep four-space indentation, braces on the same line, and descriptive type names such as `WindowManager`, `ScreenDetection`, or `BottomRightTwelfthCalculation`. Prefer focused files for each calculation or utility. Keep enum cases and stored defaults stable unless a migration is included. Avoid broad refactors in behavior changes.

## Testing Guidelines

Use XCTest in `RectangleTests/`. Name test methods with the `test...` prefix and keep fixtures local to the test case. Add coverage for window geometry, repeat/cycle behavior, defaults migration, and edge cases around multi-display or non-resizable windows when changing those areas. Run the full `xcodebuild test` command before submitting.

## Commit & Pull Request Guidelines

Recent history uses short imperative subjects, sometimes with a conventional prefix, for example `fix: add missing SF Symbol icons to menu items` or `Add move window to specific display actions (1-9)`. Keep commits scoped and reference issue or PR numbers when relevant.

For pull requests, describe the user-visible change, list test results, and link related issues. Include screenshots or video for UI, snapping, or localization changes. Note macOS version-specific behavior. Do not check in local signing changes or the temporary asset-catalog flag workaround for older macOS builds.

## Security & Configuration Notes

Rectangle depends on Accessibility APIs and macOS window state. Be careful with permission prompts, launch-on-login behavior, entitlement files, and defaults keys. Treat changes to `Info.plist`, entitlements, and bundle identifiers as release-sensitive.
