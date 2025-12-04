# SwiftUIFlow

A type-safe, coordinator-based navigation framework for SwiftUI that makes complex navigation hierarchies simple and predictable.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017+%20|%20macOS%2014+-blue.svg)](https://developer.apple.com)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- ✅ **Type-Safe Navigation** - Enum-based routes ensure compile-time safety
- ✅ **Universal Navigate API** - Call `navigate(to:)` from anywhere and the framework finds the right path
- ✅ **Smart Navigation** - Automatic backward detection, modal dismissal, and state cleanup
- ✅ **Hierarchical Coordinators** - Nest coordinators for modular, scalable navigation
- ✅ **Tab Coordination** - Built-in support for tab-based navigation
- ✅ **Modal Management** - Multiple modal coordinators with automatic lifecycle management
- ✅ **Detour Navigation** - Preserve context during deep linking with fullscreen detours
- ✅ **Pushed Child Coordinators** - Push entire coordinator hierarchies onto navigation stacks
- ✅ **Two-Phase Navigation** - Validation before execution prevents broken navigation states
- ✅ **Zero Configuration** - Presentation contexts and back button behavior handled automatically
- ✅ **Comprehensive Error Handling** - Type-safe error reporting with global handler
- ✅ **Full Documentation** - Complete DocC documentation with guides and examples

## Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+

## Installation

### Swift Package Manager

Add SwiftUIFlow to your project using Swift Package Manager:

1. In Xcode, select **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/JohnnyPJr/SwiftUIFlow`
3. Select the version you want to use
4. Click **Add Package**

Alternatively, add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/JohnnyPJr/SwiftUIFlow.git", from: "1.0.0")
]
```

## Quick Start

### 1. Define Your Routes

```swift
import SwiftUIFlow

enum AppRoute: Route {
    case home
    case profile
    case settings

    var identifier: String {
        switch self {
        case .home: return "home"
        case .profile: return "profile"
        case .settings: return "settings"
        }
    }
}
```

### 2. Create a Coordinator

```swift
class AppCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: AppRoute) -> Bool {
        return true
    }

    override func navigationType(for route: AppRoute) -> NavigationType {
        switch route {
        case .home, .profile:
            return .push
        case .settings:
            return .modal
        }
    }
}
```

### 3. Create a View Factory

```swift
class AppViewFactory: ViewFactory<AppRoute> {
    weak var coordinator: AppCoordinator?

    override func buildView(for route: AppRoute) -> AnyView {
        guard let coordinator else {
            return AnyView(Text("Error: Coordinator not set"))
        }

        switch route {
        case .home:
            return AnyView(HomeView(coordinator: coordinator))
        case .profile:
            return AnyView(ProfileView(coordinator: coordinator))
        case .settings:
            return AnyView(SettingsView(coordinator: coordinator))
        }
    }
}
```

### 4. Navigate from Anywhere

```swift
struct HomeView: View {
    let coordinator: AppCoordinator

    var body: some View {
        VStack {
            Button("View Profile") {
                coordinator.navigate(to: .profile)
            }

            Button("Settings") {
                coordinator.navigate(to: .settings) // Presents as modal
            }
        }
        .navigationTitle("Home")
    }
}
```

## Why SwiftUIFlow?

### Before SwiftUIFlow

```swift
// Manual state management
@State private var path = NavigationPath()
@State private var showingModal = false
@State private var modalContent: ModalType?

// Fragile navigation prone to bugs
Button("Navigate") {
    path.append(someRoute)
    // Hope this works across the app...
}

// Complex cross-screen navigation
// Requires passing bindings through multiple levels
```

### With SwiftUIFlow

```swift
// Type-safe, predictable navigation
coordinator.navigate(to: .profile)

// Works from anywhere in your app
coordinator.navigate(to: .settings) // Automatically presents as modal

// Framework handles all navigation state automatically
// Automatic modal/detour dismissal and state cleanup
```

## What You Can Do

### Simple Modals? Use Plain SwiftUI!

**Important:** Not every modal needs a coordinator! For simple pickers, selectors, or forms without navigation, use SwiftUI's `.sheet()` directly:

```swift
struct HomeView: View {
    let coordinator: AppCoordinator
    @State private var showThemePicker = false

    var body: some View {
        Button("Pick Theme") { showThemePicker = true }
            .sheet(isPresented: $showThemePicker) {
                ThemePickerView(selectedTheme: $theme)
            }
    }
}
```

**Use coordinator-based modals only when you need:**
- Deep linking to the modal
- Navigation within the modal (calling `.navigate()`, not just dismissing)
- Route-based presentation tracking
- Custom modal detents (automatic content-sizing with `.custom`)

**SwiftUIFlow is for navigation** - if your modal doesn't navigate anywhere, you don't need a coordinator!

### Navigate from Anywhere in Your App

Call `navigate(to:)` from any view, any coordinator, any level deep. The framework automatically finds the right coordinator to handle the route:

```swift
// From a deeply nested view in Tab1
coordinator.navigate(to: Tab2Route.settings)
// Automatically switches to Tab2 and navigates to settings
```

### Automatic Modal and Detour Dismissal

The framework automatically cleans up navigation state when navigating across coordinators:

```swift
// Modal is currently open
coordinator.navigate(to: AnotherTabRoute.details)
// Framework automatically:
// 1. Dismisses the modal
// 2. Switches tabs
// 3. Navigates to the target route
```

### Smart Backward Navigation

Navigate to a route already in the stack and the framework automatically pops instead of pushing:

```swift
// Current stack: [Home, Profile, Settings]
coordinator.navigate(to: .profile)
// Framework detects .profile is in stack
// Automatically pops back to Profile (doesn't push again)
```

### Content-Sized Modal Sheets

Use the `.custom` detent for modals that automatically size to their content:

```swift
override func modalDetentConfiguration(for route: AppRoute) -> ModalDetentConfiguration {
    switch route {
    case .settings:
        // Modal automatically sizes to content height
        return ModalDetentConfiguration(detents: [.custom, .medium])
    default:
        return ModalDetentConfiguration(detents: [.large])
    }
}
```

### Deep Linking with Context Preservation

Present deep links as detours to preserve the user's current navigation context:

```swift
func handleDeepLink(to route: any Route) {
    // User is deep in a flow: Tab2 → Unlock → EnterCode → Loading
    let profileCoordinator = ProfileCoordinator()
    presentDetour(profileCoordinator, presenting: .profile)
    // User can tap back to return to Loading screen
    // Their context is preserved!
}
```

### Multi-Step Navigation Paths

Build navigation paths that guide users through sequential flows:

```swift
override func navigationPath(for route: OceanRoute) -> [any Route]? {
    switch route {
    case .shallow:
        return [.shallow]
    case .deep:
        return [.shallow, .deep]
    case .abyss:
        return [.shallow, .deep, .abyss]
    default:
        return nil
    }
}

// Navigate directly to the abyss
coordinator.navigate(to: .abyss)
// Framework builds: shallow → deep → abyss
// User can navigate back through each level
```

### Cross-Tab Navigation

Navigate to any tab's routes from anywhere in your app:

```swift
// From Tab1's deeply nested view
coordinator.navigate(to: Tab3Route.userProfile(id: "123"))
// Framework automatically:
// 1. Switches to Tab3
// 2. Navigates to the profile within Tab3
```

### Hierarchical Coordinator Organization

Break your app into modular, reusable coordinator hierarchies:

```swift
class MainTabCoordinator: TabCoordinator<AppRoute> {
    init() {
        super.init(router: Router(initial: .home, factory: factory))

        // Each tab is its own coordinator hierarchy
        addChild(HomeCoordinator())      // Manages home flow
        addChild(SearchCoordinator())    // Manages search flow
        addChild(ProfileCoordinator())   // Manages profile flow
    }
}
```

### Nested Modal Coordinators

Present modals from within modals with full navigation support:

```swift
class SettingsCoordinator: Coordinator<SettingsRoute> {
    let privacyModal: PrivacyCoordinator

    init() {
        super.init(router: Router(initial: .main, factory: factory))

        // Modal can present its own modal
        privacyModal = PrivacyCoordinator()
        addModalCoordinator(privacyModal)
    }
}
```

### Pushed Child Coordinators

Push entire coordinator hierarchies onto navigation stacks:

```swift
class RedCoordinator: Coordinator<RedRoute> {
    let rainbowCoordinator: RainbowCoordinator

    init() {
        super.init(router: Router(initial: .red, factory: factory))

        // Push entire rainbow flow as a child
        rainbowCoordinator = RainbowCoordinator()
        addChild(rainbowCoordinator)
    }
}

// Navigate to rainbow route
coordinator.navigate(to: RainbowRoute.red)
// Framework pushes rainbowCoordinator onto the stack
// Full navigation support within the child
```

### Comprehensive Error Handling

Set up a global error handler to respond to all framework errors:

```swift
class AppState: ObservableObject {
    init() {
        SwiftUIFlowErrorHandler.shared.setHandler { [weak self] error in
            DispatchQueue.main.async {
                self?.showError(error)
            }
        }
    }
}
```

Common errors are automatically reported:
- Navigation failures (no coordinator can handle route)
- Missing modal coordinators
- View creation failures
- Configuration errors

## Documentation

📚 **[Complete Documentation](https://johnnypjr.github.io/SwiftUIFlow/documentation/swiftuiflow/)**

### Essential Guides

- **[Getting Started](https://johnnypjr.github.io/SwiftUIFlow/documentation/swiftuiflow/gettingstarted)** - Step-by-step setup guide
- **[Important Concepts](https://johnnypjr.github.io/SwiftUIFlow/documentation/swiftuiflow/importantconcepts)** - Critical patterns and best practices
- **[Navigation Patterns](https://johnnypjr.github.io/SwiftUIFlow/documentation/swiftuiflow/navigationpatterns)** - Advanced features and techniques
- **[Error Handling](https://johnnypjr.github.io/SwiftUIFlow/documentation/swiftuiflow/errorhandling)** - Comprehensive error handling guide
- **[SwiftUI Limitations](https://johnnypjr.github.io/SwiftUIFlow/documentation/swiftuiflow/swiftuilimitations)** - Known framework bugs and workarounds

## Example App

Want to see SwiftUIFlow in action? The repository includes a comprehensive example app demonstrating:

- Tab-based navigation with multiple coordinators
- Modal presentations with various detent configurations
- Pushed child coordinators
- Deep linking and detour navigation
- Cross-coordinator navigation flows
- Error handling patterns

**To run the example:**

1. Clone this repository: `git clone https://github.com/JohnnyPJr/SwiftUIFlow.git`
2. Open `SwiftUIFlow.xcodeproj` in Xcode
3. Select the `SwiftUIFlowExample` scheme
4. Build and run (⌘R)

## Advanced Examples

### Tab Coordination

```swift
class MainTabCoordinator: TabCoordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        addChild(HomeCoordinator())
        addChild(SearchCoordinator())
        addChild(ProfileCoordinator())
    }
}
```

### Modal Coordinators with Shared Route Type

```swift
class ParentCoordinator: Coordinator<AppRoute> {
    let settingsModal: SettingsCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        // Modal must share parent's route type
        settingsModal = SettingsCoordinator()
        addModalCoordinator(settingsModal)
    }

    override func navigationType(for route: AppRoute) -> NavigationType {
        return route == .settings ? .modal : .push
    }
}

class SettingsCoordinator: Coordinator<AppRoute> {
    init() {
        super.init(router: Router(initial: .settings, factory: factory))
    }
}
```

### FlowOrchestrator for Major Transitions

```swift
class AppCoordinator: FlowOrchestrator<AppRoute> {
    override func canHandleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }
        return appRoute == .login || appRoute == .mainApp
    }

    override func handleFlowChange(to route: any Route) -> Bool {
        guard let appRoute = route as? AppRoute else { return false }

        switch appRoute {
        case .login:
            transitionToFlow(LoginCoordinator(), root: .login)
            return true
        case .mainApp:
            transitionToFlow(MainTabCoordinator(), root: .mainApp)
            return true
        default:
            return false
        }
    }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

SwiftUIFlow is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Author

Created by [Ioannis Platsis](https://github.com/JohnnyPJr)

---

**Need Help?** Check out the [documentation](https://johnnypjr.github.io/SwiftUIFlow/documentation/swiftuiflow/) or [open an issue](https://github.com/JohnnyPJr/SwiftUIFlow/issues).
