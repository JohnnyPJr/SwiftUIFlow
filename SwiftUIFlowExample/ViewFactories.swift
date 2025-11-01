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
            return view(LoginView(appCoordinator: appCoordinator))
        }
    }
}

class RedViewFactory: ViewFactory<RedRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: RedRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .red:
            return view(RedView(appCoordinator: appCoordinator))
        case .lightRed:
            return view(LightRedView(appCoordinator: appCoordinator))
        case .darkRed:
            return view(DarkRedView(appCoordinator: appCoordinator))
        }
    }
}

class GreenViewFactory: ViewFactory<GreenRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: GreenRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .green:
            return view(GreenView(appCoordinator: appCoordinator))
        case .lightGreen:
            return view(LightGreenView(appCoordinator: appCoordinator))
        case .darkGreen:
            return view(DarkGreenView(appCoordinator: appCoordinator))
        }
    }
}

class BlueViewFactory: ViewFactory<BlueRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: BlueRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .blue:
            return view(BlueView(appCoordinator: appCoordinator))
        case .lightBlue:
            return view(LightBlueView(appCoordinator: appCoordinator))
        case .darkBlue:
            return view(DarkBlueView(appCoordinator: appCoordinator))
        }
    }
}

class YellowViewFactory: ViewFactory<YellowRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: YellowRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .yellow:
            return view(YellowView(appCoordinator: appCoordinator))
        case .lightYellow:
            return view(LightYellowView(appCoordinator: appCoordinator))
        case .darkYellow:
            return view(DarkYellowView(appCoordinator: appCoordinator))
        }
    }
}

class PurpleViewFactory: ViewFactory<PurpleRoute> {
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: PurpleRoute) -> AnyView? {
        guard let appCoordinator else { return nil }

        switch route {
        case .purple:
            return view(PurpleView(appCoordinator: appCoordinator))
        case .lightPurple:
            return view(LightPurpleView(appCoordinator: appCoordinator))
        case .darkPurple:
            return view(DarkPurpleView(appCoordinator: appCoordinator))
        case let .result(success):
            return view(ResultView(success: success, appCoordinator: appCoordinator))
        }
    }
}
