# Error Handling

Understanding and handling errors in SwiftUIFlow applications.

## Overview

SwiftUIFlow provides a comprehensive error handling system that helps you diagnose and respond to navigation errors, view creation failures, and configuration issues. All framework errors are reported through a centralized error handling system.

## SwiftUIFlowError

The framework reports errors using the ``SwiftUIFlowError`` enum, which provides detailed context about what went wrong:

```swift
public enum SwiftUIFlowError: Error {
    case navigationFailed(coordinator: String, route: String, routeType: String, context: String)
    case viewCreationFailed(coordinator: String, route: String, routeType: String, viewType: ViewType)
    case modalCoordinatorNotConfigured(coordinator: String, route: String, routeType: String)
    case invalidDetourNavigation(coordinator: String, route: String, routeType: String)
    case circularReference(coordinator: String)
    case duplicateChild(coordinator: String, child: String)
    case invalidTabIndex(index: Int, validRange: Range<Int>)
    case configurationError(message: String)
}
```

## Global Error Handler

Set up a global error handler to respond to all framework errors:

```swift
@main
struct MyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            AppRootView(appState: appState)
        }
    }
}

class AppState: ObservableObject {
    let appCoordinator: AppCoordinator
    @Published var currentError: SwiftUIFlowError?
    @Published var showErrorToast: Bool = false

    init() {
        appCoordinator = AppCoordinator()

        // Set up global error handler
        SwiftUIFlowErrorHandler.shared.setHandler { [weak self] error in
            DispatchQueue.main.async {
                self?.currentError = error
                self?.showErrorToast = true
            }
        }
    }
}
```

## Common Errors

### Navigation Failed

Occurs when no coordinator in the hierarchy can handle a route:

```swift
case .navigationFailed(coordinator: "AppCoordinator",
                       route: "unknownRoute",
                       routeType: "AppRoute",
                       context: "No coordinator can handle this route")
```

**Solution:** Ensure the route is handled by a coordinator in your hierarchy, or implement `handleFlowChange(to:)` to handle flow transitions.

### Modal Coordinator Not Configured

Occurs when `navigationType()` returns `.modal` but no modal coordinator is registered:

```swift
case .modalCoordinatorNotConfigured(coordinator: "ParentCoordinator",
                                     route: "settings",
                                     routeType: "AppRoute")
```

**Solution:** Register the modal coordinator using `addModalCoordinator()`:

```swift
class ParentCoordinator: Coordinator<AppRoute> {
    let settingsModal: SettingsCoordinator

    init() {
        let factory = AppViewFactory()
        super.init(router: Router(initial: .home, factory: factory))
        factory.coordinator = self

        // Register modal coordinator
        settingsModal = SettingsCoordinator()
        addModalCoordinator(settingsModal)  // ← Don't forget this!
    }
}
```

### View Creation Failed

Occurs when `ViewFactory.buildView(for:)` returns `nil`:

```swift
case .viewCreationFailed(coordinator: "ProductCoordinator",
                         route: "detail",
                         routeType: "ProductRoute",
                         viewType: .root)
```

**Solution:** Ensure your view factory handles all route cases:

```swift
class ProductViewFactory: ViewFactory<ProductRoute> {
    override func buildView(for route: ProductRoute) -> AnyView {
        guard let coordinator else {
            return AnyView(Text("Error: Coordinator not set"))
        }

        switch route {
        case .list:
            return AnyView(ProductListView(coordinator: coordinator))
        case .detail:
            return AnyView(ProductDetailView(coordinator: coordinator))
        // ⚠️ Make sure all cases are covered!
        }
    }
}
```

## Error Reporting View

When view creation fails, the framework automatically shows ``ErrorReportingView`` in place of the failed view:

```swift
// Framework shows this automatically when buildView() returns nil
ErrorReportingView(error: error)
```

This ensures your app never shows a blank screen - users always see an error indicator while you receive the error through the global handler.

## Displaying Errors to Users

Example: Create a reusable error toast modifier:

```swift
struct ErrorToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let error: SwiftUIFlowError?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if isPresented, let error {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                        Text(errorMessage(for: error))
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.red)
                    .cornerRadius(8)
                    .padding()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func errorMessage(for error: SwiftUIFlowError) -> String {
        switch error {
        case .navigationFailed(_, let route, _, let context):
            return "Navigation failed: \(route) - \(context)"
        case .modalCoordinatorNotConfigured(_, let route, _):
            return "Modal not configured for: \(route)"
        case .viewCreationFailed(_, let route, _, _):
            return "Failed to create view for: \(route)"
        default:
            return "Navigation error occurred"
        }
    }
}

extension View {
    func errorToast(isPresented: Binding<Bool>, error: SwiftUIFlowError?) -> some View {
        modifier(ErrorToastModifier(isPresented: isPresented, error: error))
    }
}
```

Use it in your root view:

```swift
struct AppRootView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        CoordinatorView(coordinator: appState.appCoordinator)
            .errorToast(isPresented: $appState.showErrorToast,
                       error: appState.currentError)
    }
}
```

## Best Practices

### 1. Always Set Up Error Handler

Configure the global error handler during app initialization:

```swift
init() {
    appCoordinator = AppCoordinator()

    SwiftUIFlowErrorHandler.shared.setHandler { error in
        // Log to analytics
        // Show user notification
        // etc.
    }
}
```

### 2. Log Errors for Debugging

Send errors to your logging system:

```swift
SwiftUIFlowErrorHandler.shared.setHandler { error in
    Logger().error("SwiftUIFlow Error: \(error.localizedDescription)")
    // Analytics.logError(error)
}
```

### 3. Provide User Feedback

Always show users when navigation fails:

```swift
SwiftUIFlowErrorHandler.shared.setHandler { [weak self] error in
    DispatchQueue.main.async {
        self?.showError(error)
    }
}
```

### 4. Handle All Route Cases

Ensure your view factories handle all route cases to prevent view creation errors:

```swift
override func buildView(for route: AppRoute) -> AnyView {
    // Handle ALL cases in your enum
    switch route {
    case .home: return AnyView(HomeView(...))
    case .profile: return AnyView(ProfileView(...))
    // Don't leave any cases unhandled!
    }
}
```

## See Also

- ``SwiftUIFlowError``
- ``SwiftUIFlowErrorHandler``
- ``ErrorReportingView``
- ``ValidationResult``
