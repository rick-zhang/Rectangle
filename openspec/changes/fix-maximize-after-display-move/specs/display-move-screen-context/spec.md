## ADDED Requirements

### Requirement: Preserve destination display context after Rectangle display moves

Rectangle SHALL preserve the destination display context from a successful Next Display or Previous Display action for the same window until the window is externally moved, the display layout changes, or another Rectangle action records a newer result.

The preserved destination display context SHALL include a display identity that prefers `NSScreenNumber` / `CGDirectDisplayID` and falls back to the display frame.

#### Scenario: Maximize after next display uses destination display

- **WHEN** Rectangle moves a window from Display A to Display B using Next Display and the next action for that same unchanged window is Maximize
- **THEN** Rectangle MUST calculate Maximize using Display B as the current display
- **AND** the resulting window frame MUST remain on Display B

#### Scenario: Maximize after previous display uses destination display

- **WHEN** Rectangle moves a window from Display B to Display A using Previous Display and the next action for that same unchanged window is Maximize
- **THEN** Rectangle MUST calculate Maximize using Display A as the current display
- **AND** the resulting window frame MUST remain on Display A

#### Scenario: External movement invalidates preserved display context

- **WHEN** Rectangle has recorded a destination display for a window and the current window frame no longer matches the recorded Rectangle result
- **THEN** Rectangle MUST discard the preserved destination display context for that window
- **AND** Rectangle MUST use normal screen detection for the next action

#### Scenario: Display layout change invalidates preserved display context

- **WHEN** Rectangle has recorded a destination display identity for a window and neither its screen number nor its frame can be matched in the current display list
- **THEN** Rectangle MUST ignore the preserved destination display context
- **AND** Rectangle MUST use normal screen detection for the next action

#### Scenario: Display identity prefers screen number before frame

- **WHEN** Rectangle has recorded a destination display with a screen number and frame
- **AND** the current display list contains a display with the same screen number but a different frame
- **THEN** Rectangle MUST treat the display with the same screen number as the preserved destination display

#### Scenario: Display identity falls back to frame

- **WHEN** Rectangle has recorded a destination display without a usable screen number
- **AND** the current display list contains a display with the same frame
- **THEN** Rectangle MUST treat the display with the same frame as the preserved destination display

### Requirement: Preserve layouts across display moves

Rectangle SHALL preserve the previous non-Maximize Rectangle layout when moving a window across displays with Next Display or Previous Display, provided the previous action has a calculation available.

#### Scenario: Previous layout is recalculated on destination display

- **WHEN** a window was last placed using a non-Maximize Rectangle layout
- **AND** the user executes Next Display or Previous Display
- **THEN** Rectangle MUST recalculate that same layout on the destination display
- **AND** Rectangle MUST NOT fall back to the default center placement

#### Scenario: Maximize remains handled by maximize behavior

- **WHEN** a window was last placed using Maximize
- **AND** the user executes Next Display or Previous Display
- **THEN** Rectangle MUST preserve the Maximize behavior rather than treating Maximize as a generic layout match

### Requirement: Apply display move results robustly

Rectangle SHALL verify cross-display window moves against the full expected frame and retry a limited number of times when macOS does not apply the frame accurately.

#### Scenario: Cross-display result comparison uses whole frame

- **WHEN** Rectangle calculates a cross-display target frame
- **AND** macOS applies a frame with matching size but a different origin
- **THEN** Rectangle MUST treat the result as not matching
- **AND** Rectangle MAY retry applying the target frame

#### Scenario: Small frame drift is tolerated

- **WHEN** Rectangle calculates a cross-display target frame
- **AND** macOS applies a frame within a small tolerance of the target frame
- **THEN** Rectangle MUST treat the result as matching

### Requirement: Avoid bottom-anchored layout jump during cross-display move

Rectangle SHALL avoid visible origin jumps for bottom-anchored layouts when moving a window across displays and macOS coerces the first applied height.

#### Scenario: Bottom-anchored layout keeps bottom edge when height is coerced

- **WHEN** Rectangle applies a bottom-anchored layout on another display
- **AND** macOS initially applies a height different from the requested height
- **THEN** Rectangle MUST adjust the origin so the window remains anchored to the destination visible frame bottom edge

#### Scenario: Top-anchored and same-display moves are unchanged

- **WHEN** Rectangle applies a top-anchored layout or moves a window on the same display
- **THEN** Rectangle MUST NOT apply the bottom-anchor correction

### Requirement: Diagnostic logging is opt-in

Rectangle SHALL keep display move diagnostics disabled by default and expose a Debug-only menu item to toggle them for local troubleshooting.

#### Scenario: Diagnostics are disabled by default

- **WHEN** Rectangle launches in Debug
- **THEN** Rectangle MUST NOT clear or write `/private/tmp/rectangle-display-move.log` until diagnostics are enabled

#### Scenario: Debug menu toggles diagnostics

- **WHEN** the user selects the Debug menu item named `开启跨屏诊断日志`
- **THEN** Rectangle MUST enable display move diagnostics
- **AND** the same menu item MUST change to `关闭跨屏诊断日志`

### Requirement: Preserve existing display action behavior

Rectangle SHALL preserve existing Next Display and Previous Display behavior while adding destination display context for subsequent actions.

#### Scenario: Display traversal remains unchanged

- **WHEN** a user executes Next Display or Previous Display
- **THEN** Rectangle MUST continue selecting the destination display using the existing adjacent display ordering behavior
- **AND** Rectangle MUST NOT change shortcut names, URL action names, or user defaults

#### Scenario: Single display behavior remains unchanged

- **WHEN** only one display is available
- **THEN** Rectangle MUST continue using the existing single-display traversal behavior and defaults
