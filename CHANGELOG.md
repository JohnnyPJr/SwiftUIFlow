# Changelog

All notable changes to SwiftUIFlow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - Unreleased

### Fixed
- **Critical: Double-Push Bug** - Fixed bug where child coordinators could be pushed twice when navigating across tabs and deep linking back to routes they handle. The framework now checks if a child is already in `pushedChildren` before pushing it again, preventing duplicate routes in navigation stacks.
- **Modal State Reset** - Fixed bug where modal coordinators retained stale pushed children after dismissal. `resetToCleanState()` and `dismissModal()` now properly clear pushed children, ensuring clean state when re-presenting modals.
- **Navigation Path Root Handling** - Added defensive skip-root check in path building. If `navigationPath()` accidentally includes the root route, the framework now skips it to prevent pushing the root onto the stack.

### Changed
- Refactored `delegateToChildren()` into three focused methods for improved code organization and maintainability.
- Consolidated duplicate path-building logic into shared `buildNavigationPath()` helper method.
- Updated `.swiftformat` configuration to disable `preferKeyPath` rule to prevent compilation issues with existential types.

### Added
- Comprehensive regression test suite (`PushedChildRegressionTests`) with 6 tests covering the fixed bugs and related edge cases to prevent future regressions.

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

[1.0.1]: https://github.com/JohnnyPJr/SwiftUIFlow/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/JohnnyPJr/SwiftUIFlow/releases/tag/v1.0.0
