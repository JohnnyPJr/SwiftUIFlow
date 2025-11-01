//
//  ViewFactories.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

class AppViewFactory: ViewFactory<AppRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: AppRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .tabRoot:
            return nil
        case .login:
            return AnyView(LoginView(appCoordinator: appCoordinator))
        }
    }
}

class RedViewFactory: ViewFactory<RedRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: RedRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .red:
            return AnyView(RedView(appCoordinator: appCoordinator))
        case .lightRed:
            return AnyView(LightRedView(appCoordinator: appCoordinator))
        case .darkRed:
            return AnyView(DarkRedView(appCoordinator: appCoordinator))
        }
    }
}

class GreenViewFactory: ViewFactory<GreenRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: GreenRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .green:
            return AnyView(GreenView(appCoordinator: appCoordinator))
        case .lightGreen:
            return AnyView(LightGreenView(appCoordinator: appCoordinator))
        case .darkGreen:
            return AnyView(DarkGreenView(appCoordinator: appCoordinator))
        }
    }
}

class BlueViewFactory: ViewFactory<BlueRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: BlueRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .blue:
            return AnyView(BlueView(appCoordinator: appCoordinator))
        case .lightBlue:
            return AnyView(LightBlueView(appCoordinator: appCoordinator))
        case .darkBlue:
            return AnyView(DarkBlueView(appCoordinator: appCoordinator))
        }
    }
}

class YellowViewFactory: ViewFactory<YellowRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: YellowRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .yellow:
            return AnyView(YellowView(appCoordinator: appCoordinator))
        case .lightYellow:
            return AnyView(LightYellowView(appCoordinator: appCoordinator))
        case .darkYellow:
            return AnyView(DarkYellowView(appCoordinator: appCoordinator))
        }
    }
}

class PurpleViewFactory: ViewFactory<PurpleRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: PurpleRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .purple:
            return AnyView(PurpleView(appCoordinator: appCoordinator))
        case .lightPurple:
            return AnyView(LightPurpleView(appCoordinator: appCoordinator))
        case .darkPurple:
            return AnyView(DarkPurpleView(appCoordinator: appCoordinator))
        case let .result(success):
            return AnyView(ResultView(success: success, appCoordinator: appCoordinator))
        }
    }
}
