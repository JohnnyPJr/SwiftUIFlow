//
//  NavigationFlowIntegrationTests.swift
//  SwiftUIFlowTests
//
//  Created by Ioannis Platsis on 2/8/25.
//

@testable import SwiftUIFlow
import XCTest

final class NavigationFlowIntegrationTests: XCTestCase {
    func test_SmartBackwardNavigationInRetryFlow() {
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        // Navigate to Tab2
        XCTAssertTrue(mainCoordinator.navigate(to: MainTabRoute.tab2))

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Navigate to loading - this will create UnlockCoordinator with enterCode as root,
        // then push loading onto the stack
        XCTAssertTrue(tab2.navigate(to: UnlockRoute.loading))

        guard let unlock = tab2.children.first(where: { $0 is UnlockCoordinator }) as? UnlockCoordinator else {
            XCTFail("Expected UnlockCoordinator to be created")
            return
        }

        // CRITICAL: Verify that UnlockCoordinator was pushed to tab2's navigation stack
        XCTAssertTrue(tab2.router.state.pushedChildren.contains(where: { $0 === unlock }),
                      "UnlockCoordinator should be in tab2's pushedChildren array")
        XCTAssertEqual(tab2.router.state.pushedChildren.count, 1,
                       "Tab2 should have exactly 1 pushed child coordinator")

        // Stack should have [.loading] (enterCode is root, not in stack)
        XCTAssertEqual(unlock.router.state.stack.count, 1, "Stack should have 1 item")
        XCTAssertEqual(unlock.router.state.stack[0], .loading)

        // Navigate to failure - push onto stack
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.failure))

        // Verify stack has [.loading, .failure] (enterCode is root, not in stack)
        XCTAssertEqual(unlock.router.state.stack.count, 2, "Stack should have 2 items")
        XCTAssertEqual(unlock.router.state.stack[0], .loading)
        XCTAssertEqual(unlock.router.state.stack[1], .failure)

        // User taps "Retry" - navigate back to loading (smart backward navigation)
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(unlock.router.state.stack.count, 1, "Stack should have 1 item after popping back to loading")
        XCTAssertEqual(unlock.router.state.stack[0], .loading, "Should be at loading after retry")

        // Navigate to failure - push onto stack
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.failure))

        // User could also tap "Retry with different code" - navigate back to enterCode root
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.enterCode))
        XCTAssertTrue(unlock.router.state.stack.isEmpty, "Stack should be empty after going to root")

        // User enters new code and navigates through flow again
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.loading))
        XCTAssertEqual(unlock.router.state.stack.count, 1, "Stack should have 1 item after navigating to loading")
        XCTAssertEqual(unlock.router.state.stack[0], .loading)

        // Navigate to failure - push onto stack
        XCTAssertTrue(unlock.navigate(to: UnlockRoute.failure))

        // User taps "Cancel" - navigate back to Tab2's root screen (.startUnlock)
        // This exits the unlock flow and returns to the parent screen
        XCTAssertTrue(unlock.navigate(to: Tab2Route.startUnlock))

        // Verify we're now at Tab2's root screen (.startUnlock)
        XCTAssertTrue(tab2.router.state.stack.isEmpty, "Tab2 should be at root with empty stack")
        XCTAssertNil(tab2.router.state.presented, "Tab2 should have no modal presented")

        // CRITICAL: Verify unlock coordinator was popped from pushedChildren
        XCTAssertTrue(tab2.router.state.pushedChildren.isEmpty,
                      "Tab2 pushedChildren should be empty after exiting unlock flow")

        // Verify unlock coordinator is still a child (children are permanent)
        XCTAssertTrue(tab2.children.contains(where: { $0 is UnlockCoordinator }),
                      "UnlockCoordinator should still be a child")

        // Verify unlock's stack was cleaned when we exited the flow
        XCTAssertTrue(unlock.router.state.stack.isEmpty, "Unlock stack should be cleaned after canceling")
    }

    // MARK: - Replace Navigation Integration Tests

    func test_MultiStepFlowWithReplaceNavigation() {
        // Simulate a password reset flow with replace navigation
        // User should not be able to go back to previous steps
        let router = Router<MainTabRoute>(initial: .tab1, factory: DummyFactory())
        let mainCoordinator = MainTabCoordinator(router: router)

        guard let tab2 = mainCoordinator.children[1] as? Tab2Coordinator else {
            XCTFail("Expected Tab2Coordinator")
            return
        }

        // Add password reset coordinator to Tab2 (app knows its hierarchy upfront)
        let resetRouter = Router<PasswordResetRoute>(initial: .enterCode, factory: DummyFactory())
        let resetCoordinator = PasswordResetCoordinator(router: resetRouter)
        tab2.addChild(resetCoordinator)

        // Step 1: ENTRY - Navigate from anywhere (like a deeplink or tab switch)
        // This tests: MainTabCoordinator → switches to Tab2 → delegates to PasswordResetCoordinator
        XCTAssertTrue(mainCoordinator.navigate(to: PasswordResetRoute.enterCode))
        XCTAssertEqual(router.state.selectedTab, 1, "Should switch to Tab2")
        XCTAssertTrue(resetRouter.state.stack.isEmpty, "enterCode is root, stack should be empty")

        // Step 2-4: INTERNAL FLOW - User is now IN the reset coordinator, navigates within it
        // This is realistic: user enters code → app validates → navigates to next step
        // Each uses replace so user can't go back

        // User enters code → navigate to verifying (replace)
        XCTAssertTrue(resetCoordinator.navigate(to: PasswordResetRoute.verifying))
        XCTAssertEqual(resetRouter.state.stack, [.verifying], "Should have verifying in stack")
        XCTAssertFalse(resetRouter.state.stack.contains(.enterCode), "enterCode should be replaced")

        // Code verified → navigate to newPassword (replace)
        XCTAssertTrue(resetCoordinator.navigate(to: PasswordResetRoute.newPassword))
        XCTAssertEqual(resetRouter.state.stack, [.newPassword], "Should have newPassword in stack")
        XCTAssertFalse(resetRouter.state.stack.contains(.verifying), "verifying should be replaced")

        // Password entered → navigate to success (replace)
        XCTAssertTrue(resetCoordinator.navigate(to: PasswordResetRoute.success))
        XCTAssertEqual(resetRouter.state.stack, [.success], "Should have success in stack")
        XCTAssertFalse(resetRouter.state.stack.contains(.newPassword), "newPassword should be replaced")

        // Step 5: User taps back - should exit entire reset flow (pop to root)
        resetCoordinator.pop()
        XCTAssertTrue(resetRouter.state.stack.isEmpty, "Popping should empty stack (back to root)")
        XCTAssertEqual(resetRouter.state.currentRoute, .enterCode, "Should be back at root")
    }

    // MARK: - SetRoot Integration Tests

    func test_LoginToHomeFlowTransition() {
        // Simulate app starting with login, then transitioning to home after login
        // This is the most common real-world scenario

        // Step 1: App starts with AppCoordinator managing major flows
        let appRouter = Router<AppFlowRoute>(initial: .login, factory: DummyFactory())
        let appCoordinator = AppFlowCoordinator(router: appRouter)

        // Verify we start in login flow
        XCTAssertEqual(appRouter.state.root, .login, "App should start at login")
        XCTAssertTrue(appCoordinator.children.contains(where: { $0 is LoginFlowCoordinator }),
                      "Should have LoginFlowCoordinator as child")

        // Step 2: Simulate login flow (email → password → 2FA)
        guard let loginCoordinator = appCoordinator.children
            .first(where: { $0 is LoginFlowCoordinator }) as? LoginFlowCoordinator
        else {
            XCTFail("Expected LoginFlowCoordinator")
            return
        }

        // Build up login state (user goes through login flow)
        XCTAssertTrue(loginCoordinator.navigate(to: LoginRoute.enterPassword))
        XCTAssertTrue(loginCoordinator.navigate(to: LoginRoute.twoFactor))
        XCTAssertEqual(loginCoordinator.router.state.stack.count, 2, "Should have navigation stack in login")

        // Step 3: User completes login - navigate to home
        let loginSuccess = appCoordinator.navigate(to: AppFlowRoute.home)
        XCTAssertTrue(loginSuccess, "Navigation to home should succeed")

        // Step 4: Verify app state after login → home transition
        XCTAssertEqual(appRouter.state.root, .home, "App root should now be home")
        XCTAssertTrue(appRouter.state.stack.isEmpty, "Stack should be empty (clean slate)")

        // Step 5: Verify login coordinator was removed
        XCTAssertFalse(appCoordinator.children.contains(where: { $0 is LoginFlowCoordinator }),
                       "LoginFlowCoordinator should be removed")

        // Step 6: Verify home coordinator exists
        XCTAssertTrue(appCoordinator.children.contains(where: { $0 is HomeFlowCoordinator }),
                      "Should have HomeFlowCoordinator as child")

        // Step 7: User cannot navigate back to login (coordinator is gone, root changed)
        // Attempting to pop should do nothing (we're at root with empty stack)
        appCoordinator.pop()
        XCTAssertEqual(appRouter.state.root, .home, "Should still be at home")
        XCTAssertTrue(appRouter.state.stack.isEmpty, "Stack should still be empty")
    }

    func test_OnboardingToLoginToHomeFullFlow() {
        // Comprehensive test: First launch → Onboarding → Login → Home
        // Tests multiple setRoot transitions

        let appRouter = Router<AppFlowRoute>(initial: .onboarding, factory: DummyFactory())
        let appCoordinator = AppFlowCoordinator(router: appRouter)

        // Phase 1: Onboarding
        XCTAssertEqual(appRouter.state.root, .onboarding, "Should start at onboarding")
        guard let onboardingCoordinator = appCoordinator.children
            .first(where: { $0 is OnboardingFlowCoordinator }) as? OnboardingFlowCoordinator
        else {
            XCTFail("Expected OnboardingFlowCoordinator")
            return
        }

        // User goes through onboarding steps
        XCTAssertTrue(onboardingCoordinator.navigate(to: OnboardingRoute.step1))
        XCTAssertTrue(onboardingCoordinator.navigate(to: OnboardingRoute.step2))
        XCTAssertEqual(onboardingCoordinator.router.state.stack.count, 2)

        // Phase 2: Complete onboarding → transition to login
        XCTAssertTrue(appCoordinator.navigate(to: AppFlowRoute.login))
        XCTAssertEqual(appRouter.state.root, .login, "Should transition to login")
        XCTAssertTrue(appRouter.state.stack.isEmpty, "Stack should be clean")
        XCTAssertFalse(appCoordinator.children.contains(where: { $0 is OnboardingFlowCoordinator }),
                       "Onboarding should be removed")

        // Phase 3: User logs in → transition to home
        guard let loginCoordinator = appCoordinator.children
            .first(where: { $0 is LoginFlowCoordinator }) as? LoginFlowCoordinator
        else {
            XCTFail("Expected LoginFlowCoordinator")
            return
        }

        XCTAssertTrue(loginCoordinator.navigate(to: LoginRoute.enterPassword))
        XCTAssertTrue(appCoordinator.navigate(to: AppFlowRoute.home))

        // Verify final state
        XCTAssertEqual(appRouter.state.root, .home, "Should end at home")
        XCTAssertTrue(appRouter.state.stack.isEmpty, "Stack should be clean")
        XCTAssertFalse(appCoordinator.children.contains(where: { $0 is LoginFlowCoordinator }),
                       "Login should be removed")
        XCTAssertTrue(appCoordinator.children.contains(where: { $0 is HomeFlowCoordinator }),
                      "Home should exist")

        // User cannot navigate back to login or onboarding
        appCoordinator.pop()
        XCTAssertEqual(appRouter.state.root, .home, "Should remain at home after pop")
    }
}
