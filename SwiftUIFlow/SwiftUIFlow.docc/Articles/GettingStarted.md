# Getting Started

Learn how to integrate SwiftUIFlow into your SwiftUI app and create your first coordinator-based navigation flow.

## Overview

SwiftUIFlow uses the coordinator pattern to manage navigation in SwiftUI applications. This guide will walk you through setting up your first coordinator, defining routes, and implementing navigation.

## Installation

### Swift Package Manager

Add SwiftUIFlow to your project using Swift Package Manager:

1. In Xcode, select **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/JohnnyPJr/SwiftUIFlow`
3. Select the version you want to use
4. Click **Add Package**

## Basic Setup

### Step 1: Define Your Routes

Create an enum that conforms to the ``Route`` protocol:

```swift
import SwiftUIFlow

enum AppRoute: Route {
    case home
    case profile(userId: String)
    case settings

    var identifier: String {
        switch self {
        case .home:
            return "home"
        case .profile(let userId):
            return "profile_\(userId)"
        case .settings:
            return "settings"
        }
    }
}
```

The `identifier` is used for route equality checks and logging. Make it unique for each route case.

### Step 2: Create Your Views

Create SwiftUI views for each route:

```swift
import SwiftUI

struct HomeView: View {
    let coordinator: AppCoordinator

    var body: some View {
        VStack {
            Text("Home")
                .font(.largeTitle)

            Button("Go to Profile") {
                coordinator.navigate(to: .profile(userId: "123"))
            }

            Button("Open Settings") {
                coordinator.navigate(to: .settings)
            }
        }
    }
}

struct ProfileView: View {
    let coordinator: AppCoordinator
    let userId: String

    var body: some View {
        VStack {
            Text("Profile: \(userId)")
                .font(.largeTitle)

            Button("Go to Settings") {
                coordinator.navigate(to: .settings)
            }
        }
    }
}

struct SettingsView: View {
    let coordinator: AppCoordinator

    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
        }
    }
}
```

### Step 3: Create a View Factory

The view factory creates views for each route:

```swift
import SwiftUIFlow

class AppViewFactory: ViewFactory<AppRoute> {
    weak var coordinator: AppCoordinator?

    override func buildView(for route: AppRoute) -> AnyView {
        guard let coordinator else {
            return AnyView(Text("Error: Coordinator not set"))
        }

        switch route {
        case .home:
            return AnyView(HomeView(coordinator: coordinator))

        case .profile(let userId):
            return AnyView(ProfileView(coordinator: coordinator, userId: userId))

        case .settings:
            return AnyView(SettingsView(coordinator: coordinator))
        }
    }
}
```

> Important: The `coordinator` property should be `weak` to avoid reference cycles.

### Step 4: Create Your Coordinator

Create a coordinator that manages your navigation:

```swift
import SwiftUIFlow

class AppCoordinator: Coordinator<AppRoute> {
    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: AppRoute) -> Bool {
        return route is AppRoute // This coordinator handles all AppRoutes
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

### Step 5: Integrate with Your App

Use ``CoordinatorView`` in your SwiftUI app:

```swift
import SwiftUI
import SwiftUIFlow

@main
struct MyApp: App {
    let coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            CoordinatorView(coordinator: coordinator)
        }
    }
}
```

That's it! Your app now has coordinator-based navigation.

## Navigation Basics

### Push Navigation

Navigate to a new screen:

```swift
coordinator.navigate(to: .profile(userId: "123"))
```

### Modal Presentation

**When to Use Coordinators for Modals:**

Use coordinator-based modals when you need:
- **Deep linking** to the modal
- **Navigation within the modal** (calling `.navigate()`, not just dismissing)
- **Route-based presentation** tracking
- **Custom modal detents** (automatic content-sized sheets with `.custom` detent)

**When to Use Plain SwiftUI Sheets:**

For simple pickers, selectors, or forms that don't need navigation, use SwiftUI's `.sheet()` directly:

```swift
struct HomeView: View {
    let coordinator: AppCoordinator
    @State private var showThemePicker = false

    var body: some View {
        VStack {
            Button("Pick Theme") { showThemePicker = true }
        }
        .sheet(isPresented: $showThemePicker) {
            ThemePickerView(selectedTheme: $theme)
        }
    }
}
```

**Coordinator-Based Modal Setup:**

To present a route as a coordinator-managed modal:

1. **Create a modal coordinator** with that route as its root
2. **Register it** using `addModalCoordinator()`
3. **Return `.modal`** from `navigationType(for:)` for that route

```swift
// Modal coordinator for settings with its own navigation
class SettingsCoordinator: Coordinator<SettingsRoute> {
    init() {
        let factory = SettingsViewFactory()
        super.init(router: Router(initial: .main, factory: factory))
        factory.coordinator = self
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is SettingsRoute
    }
}

// Parent coordinator registers and presents the modal
class AppCoordinator: Coordinator<AppRoute> {
    let settingsModalCoordinator: SettingsCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        // Register modal coordinator
        settingsModalCoordinator = SettingsCoordinator()
        addModalCoordinator(settingsModalCoordinator)
    }

    override func canHandle(_ route: any Route) -> Bool {
        return route is AppRoute
    }

    override func navigationType(for route: any Route) -> NavigationType {
        guard let appRoute = route as? AppRoute else { return .push }
        switch appRoute {
        case .home, .profile:
            return .push
        case .settings:
            return .modal
        }
    }
}
```

Then navigate normally:

```swift
coordinator.navigate(to: .settings) // Presents modal automatically
```

The framework finds the modal coordinator with `.settings` as its root route and presents it as a sheet.

### Going Back

Users can go back using:
- **Native back button** in the navigation bar (automatically provided by SwiftUI)
- **Swipe gesture** from the left edge (iOS standard behavior)
- **Modal dismiss** via swipe-down gesture or close button (for sheets)

For custom back button implementations, use the environment values:

```swift
struct ProfileView: View {
    let coordinator: AppCoordinator
    let userId: String

    @Environment(\.navigationBackAction) var backAction
    @Environment(\.canNavigateBack) var canNavigateBack

    var body: some View {
        VStack {
            Text("Profile: \(userId)")
                .font(.largeTitle)

            if canNavigateBack {
                Button("Custom Back Button") {
                    backAction?()
                }
            }
        }
    }
}
```

The framework automatically injects the correct back action based on presentation context (push, modal, or detour).

## Next Steps

- Learn about <doc:NavigationPatterns> for advanced scenarios
- Explore ``TabCoordinator`` for tab-based navigation
- Read about ``FlowOrchestrator`` for managing major app flow transitions
- Check out the example app for comprehensive usage patterns

## See Also

- ``Coordinator``
- ``Router``
- ``NavigationType``
- <doc:NavigationPatterns>
