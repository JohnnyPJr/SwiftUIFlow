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
    weak var coordinator: AnyCoordinator?

    override func buildView(for route: RedRoute) -> AnyView? {
        switch route {
        case .red:
            guard let coord = coordinator as? RedCoordinator else { return nil }
            return view(RedView(coordinator: coord))
        case .lightRed:
            guard let coord = coordinator as? RedCoordinator else { return nil }
            return view(LightRedView(coordinator: coord))
        case .darkRed:
            guard let coord = coordinator as? RedModalCoordinator else { return nil }
            return view(DarkRedView(coordinator: coord))
        }
    }
}

class GreenViewFactory: ViewFactory<GreenRoute> {
    weak var coordinator: AnyCoordinator?

    override func buildView(for route: GreenRoute) -> AnyView? {
        switch route {
        case .green:
            guard let coord = coordinator as? GreenCoordinator else { return nil }
            return view(GreenView(coordinator: coord))
        case .lightGreen:
            guard let coord = coordinator as? GreenCoordinator else { return nil }
            return view(LightGreenView(coordinator: coord))
        case .darkGreen:
            guard let coord = coordinator as? GreenModalCoordinator else { return nil }
            return view(DarkGreenView(coordinator: coord))
        }
    }
}

class BlueViewFactory: ViewFactory<BlueRoute> {
    weak var coordinator: AnyCoordinator?

    override func buildView(for route: BlueRoute) -> AnyView? {
        switch route {
        case .blue:
            guard let coord = coordinator as? BlueCoordinator else { return nil }
            return view(BlueView(coordinator: coord))
        case .lightBlue:
            guard let coord = coordinator as? BlueCoordinator else { return nil }
            return view(LightBlueView(coordinator: coord))
        case .darkBlue:
            guard let coord = coordinator as? BlueModalCoordinator else { return nil }
            return view(DarkBlueView(coordinator: coord))
        }
    }
}

class YellowViewFactory: ViewFactory<YellowRoute> {
    weak var coordinator: AnyCoordinator?

    override func buildView(for route: YellowRoute) -> AnyView? {
        switch route {
        case .yellow:
            guard let coord = coordinator as? YellowCoordinator else { return nil }
            return view(YellowView(coordinator: coord))
        case .lightYellow:
            guard let coord = coordinator as? YellowCoordinator else { return nil }
            return view(LightYellowView(coordinator: coord))
        case .darkYellow:
            guard let coord = coordinator as? YellowModalCoordinator else { return nil }
            return view(DarkYellowView(coordinator: coord))
        }
    }
}

class PurpleViewFactory: ViewFactory<PurpleRoute> {
    weak var coordinator: AnyCoordinator?
    weak var appCoordinator: AppCoordinator?

    override func buildView(for route: PurpleRoute) -> AnyView? {
        switch route {
        case .purple:
            guard let coord = coordinator as? PurpleCoordinator,
                  let appCoord = appCoordinator else { return nil }
            return view(PurpleView(coordinator: coord, appCoordinator: appCoord))
        case .lightPurple:
            guard let coord = coordinator as? PurpleCoordinator else { return nil }
            return view(LightPurpleView(coordinator: coord))
        case .darkPurple:
            guard let coord = coordinator as? PurpleModalCoordinator else { return nil }
            return view(DarkPurpleView(coordinator: coord))
        case let .result(success):
            guard let coord = coordinator as? PurpleCoordinator else { return nil }
            return view(ResultView(success: success, coordinator: coord))
        }
    }
}
