# Changelog

All notable changes to SwiftUIFlow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 10/12/2024

### Added
- **`CustomTabCoordinatorView`** - New wrapper view that automatically handles modal and detour presentations for custom tab bar designs. Provides compile-time safety and eliminates the need to manually add presentation modifiers.
- **`TabCoordinatorPresentationsModifier`** - Advanced modifier for manual control of modal and detour presentations via `.withTabCoordinatorPresentations()`. Available for advanced use cases where the wrapper doesn't fit.
- **Tab Coordinator Modal & Detour Support** - TabCoordinator now supports presenting modals and detours, enabling custom tab bars to handle the full range of navigation patterns.
- Comprehensive regression test suite (`PushedChildRegressionTests`) with 6 tests covering the fixed bugs and related edge cases to prevent future regressions.

### Fixed
- **Critical: Double-Push Bug** - Fixed bug where child coordinators could be pushed twice when navigating across tabs and deep linking back to routes they handle. The framework now checks if a child is already in `pushedChildren` before pushing it again, preventing duplicate routes in navigation stacks.
- **Modal State Reset** - Fixed bug where modal coordinators retained stale pushed children after dismissal. `resetToCleanState()` and `dismissModal()` now properly clear pushed children, ensuring clean state when re-presenting modals.
- **Navigation Path Root Handling** - Added defensive skip-root check in path building. If `navigationPath()` accidentally includes the root route, the framework now skips it to prevent pushing the root onto the stack.
- **Double-Pushing Modals** - Fixed bug where modals could be presented twice when already active.

### Changed
- **TabCoordinatorView Refactor** - Refactored to use `.withTabCoordinatorPresentations()` internally, eliminating ~80 lines of duplicate code.
- Refactored `delegateToChildren()` into three focused methods for improved code organization and maintainability.
- Consolidated duplicate path-building logic into shared `buildNavigationPath()` helper method.
- Updated `.swiftformat` configuration to disable `preferKeyPath` rule to prevent compilation issues with existential types.
- Renamed `TabCoordinatorModalsModifier` to `TabCoordinatorPresentationsModifier` for clarity (handles both modals and detours).

### Documentation
- **README Updates**:
  - Added comprehensive Tab Coordination section showing all three rendering options (native, wrapper, modifier)
  - Added "Handling External Deep Links" section with both `navigate()` and `presentDetour()` approaches
  - Added clear guidance on when to use each deep linking approach
- **NavigationPatterns.md Updates**:
  - Enhanced "Custom Tab Bar Options" section with detailed examples
  - Rewrote "Detour Navigation" as "Handling External Deep Links" with emphasis on external triggers
  - Added centralized deep link handling patterns with `DeepLinkHandler` examples
- **Code Quality**: Replaced `print()` with `Logger()` in all documentation examples
- Added clarifications for modal coordinator usage and best practices

### Example App
- Updated to demonstrate realistic centralized detour pattern via `DeepLinkHandler`
- All detour presentations now use centralized pattern from `MainTabCoordinator`
- Fixed incorrect button labels and destinations in example screens
- Removed debug print statements for cleaner code
- Updated `CustomTabBarView` to use new `CustomTabCoordinatorView` wrapper

## [1.0.0] - 2024-12-09

### Added
- Initial public release of SwiftUIFlow
- Type-safe coordinator-based navigation with enum routes
- Universal `navigate(to:)` API that works from anywhere in the app
- Smart navigation with automatic backward detection and modal dismissal
- Hierarchical coordinator architecture for modular navigation flows
- `TabCoordinator` for tab-based navigation
- Modal management with multiple modal coordinators and custom detents
- Detour navigation for preserving context during deep links
- Pushed child coordinators for complex navigation hierarchies
- Two-phase navigation (validation before execution)
- Navigation paths for multi-step sequential flows
- Comprehensive error handling with global error handler
- Complete DocC documentation with guides and examples
- Full-featured example app demonstrating all capabilities

[1.0.1]: https://github.com/JohnnyPJr/SwiftUIFlow/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/JohnnyPJr/SwiftUIFlow/releases/tag/v1.0.0
