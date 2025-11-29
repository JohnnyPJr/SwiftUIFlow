//
//  ViewFactories.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import SwiftUI
import SwiftUIFlow

class AppViewFactory: ViewFactory<AppRoute> {
    override func buildView(for route: AppRoute) -> AnyView? {
        switch route {
        case .tabRoot:
            return nil
        case .login:
            guard let coord = coordinator as? LoginCoordinator else { return nil }
            return view(LoginView(coordinator: coord))
        }
    }
}

class RedViewFactory: ViewFactory<RedRoute> {
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
        case .info:
            return view(InfoView(title: "Red Tab Info",
                                 description: "This modal has .custom detent, automatically sizing to fit its content.",
                                 detentType: ".custom",
                                 color: .red))
        }
    }
}

class GreenViewFactory: ViewFactory<GreenRoute> {
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
        case .evenDarkerGreen:
            guard let coord = coordinator as? GreenModalCoordinator else { return nil }
            return view(EvenDarkerGreenView(coordinator: coord))
        case .darkestGreen:
            guard let coord = coordinator as? GreenDarkestModalCoordinator else { return nil }
            return view(DarkestGreenView(coordinator: coord))
        case .info:
            return view(InfoView(title: "Green Tab Info",
                                 description: "This modal uses .small detent, showing only essential content.",
                                 detentType: ".small",
                                 color: .green))
        }
    }
}

class BlueViewFactory: ViewFactory<BlueRoute> {
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
        case .invalidView:
            // Intentionally return nil to trigger viewCreationFailed error
            return nil
        case .info:
            return view(InfoView(title: "Blue Tab Info",
                                 description: "This modal uses .medium detent, approximately 50% of screen height.",
                                 detentType: ".medium",
                                 color: .blue))
        }
    }
}

class YellowViewFactory: ViewFactory<YellowRoute> {
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
        case .info:
            return view(InfoView(title: "Yellow Tab Info",
                                 description: "This modal uses .large detent, nearly full screen at 99.9% height.",
                                 detentType: ".large",
                                 color: .orange))
        }
    }
}

class PurpleViewFactory: ViewFactory<PurpleRoute> {
    override func buildView(for route: PurpleRoute) -> AnyView? {
        switch route {
        case .purple:
            guard let coord = coordinator as? PurpleCoordinator else { return nil }
            return view(PurpleView(coordinator: coord))
        case .lightPurple:
            guard let coord = coordinator as? PurpleCoordinator else { return nil }
            return view(LightPurpleView(coordinator: coord))
        case .darkPurple:
            guard let coord = coordinator as? PurpleModalCoordinator else { return nil }
            return view(DarkPurpleView(coordinator: coord))
        case let .result(success):
            guard let coord = coordinator as? PurpleCoordinator else { return nil }
            return view(ResultView(success: success, coordinator: coord))
        case .info:
            return view(InfoView(title: "Purple Tab Info",
                                 description: "This modal has .fullscreen detent, presenting as a true fullScreenCover",
                                 detentType: ".fullscreen",
                                 color: .purple))
        }
    }
}

// MARK: - Rainbow View Factory (Testing Pushed Children)

final class RainbowViewFactory: ViewFactory<RainbowRoute> {
    override func buildView(for route: RainbowRoute) -> AnyView? {
        guard let coordinator = coordinator as? RainbowCoordinator else { return nil }

        switch route {
        case .red:
            return view(RainbowRedView(coordinator: coordinator))
        case .orange:
            return view(RainbowOrangeView(coordinator: coordinator))
        case .yellow:
            return view(RainbowYellowView(coordinator: coordinator))
        case .green:
            return view(RainbowGreenView(coordinator: coordinator))
        case .blue:
            return view(RainbowBlueView(coordinator: coordinator))
        case .purple:
            return view(RainbowPurpleView(coordinator: coordinator))
        }
    }
}
