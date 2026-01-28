# ``SwiftUIFlow``

A type-safe, coordinator-based navigation framework for SwiftUI that makes complex navigation hierarchies simple and predictable.

## Overview

SwiftUIFlow provides a powerful yet intuitive navigation system for SwiftUI applications. Built around the coordinator pattern, it handles everything from simple push navigation to complex cross-coordinator flows with automatic state management.

### Key Features

- **Type-Safe Navigation**: Enum-based routes ensure compile-time safety
- **Universal Navigate API**: Call `navigate(to:)` from anywhere and the framework finds the right path
- **Smart Navigation**: Automatic backward detection, modal dismissal, and state cleanup
- **Hierarchical Coordinators**: Nest coordinators for modular, scalable navigation
- **Tab Coordination**: Built-in support for tab-based navigation
- **Modal Management**: Multiple modal coordinators with automatic lifecycle management
- **Detour Navigation**: Preserve context during deep linking with fullscreen detours
- **Pushed Child Coordinators**: Push entire coordinator hierarchies onto navigation stacks
- **Two-Phase Navigation**: Validation before execution prevents broken navigation states
- **Zero Configuration**: Presentation contexts and back button behavior handled automatically

### Quick Example

```swift
// Define your routes
enum AppRoute: String, Route {
    case home
    case profile
    case settings
}

// Create a coordinator
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
        case .home: return .push
        case .profile: return .push
        case .settings: return .modal
        }
    }
}

// Navigate from anywhere
coordinator.navigate(to: .profile)
coordinator.navigate(to: .settings) // Presents modal
```

### Why SwiftUIFlow?

**Before SwiftUIFlow:**
- Manual state management for navigation
- Fragile navigation hierarchies prone to bugs
- Complex coordinator setup with boilerplate
- Cross-coordinator navigation requires careful orchestration

**With SwiftUIFlow:**
- Framework manages all navigation state automatically
- Type-safe routes prevent navigation errors
- Universal navigate API works from anywhere
- Automatic modal/detour dismissal and state cleanup

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:ImportantConcepts>
- ``Coordinator``
- ``Router``
- ``Route``
- ``NavigationType``
- ``CoordinatorView``

### Navigation

- ``Coordinator/navigate(to:)``

### Modal Presentation

- ``Coordinator/addModalCoordinator(_:)``

### Detour Navigation

- ``Coordinator/presentDetour(_:presenting:)``

### Tab Navigation

- ``TabCoordinator``
- ``TabRoute``

### Advanced Features

- <doc:NavigationPatterns>
- ``FlowOrchestrator``
- ``Coordinator/navigationPath(for:)``
- ``Coordinator/addChild(_:)``

### View Integration

- ``CoordinatorView``
- ``ViewFactory``
- ``CoordinatorUISupport``

### State Management

- ``Router``
- ``NavigationState``
- ``CoordinatorPresentationContext``

### Error Handling

- <doc:ErrorHandling>
- ``SwiftUIFlowError``
- ``ValidationResult``
- ``SwiftUIFlowErrorHandler``

### SwiftUI Framework

- <doc:SwiftUILimitations>
