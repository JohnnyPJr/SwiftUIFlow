//
//  AppRoute.swift
//  SwiftUIFlowExample
//
//  Created by Ioannis Platsis on 1/11/25.
//

import Foundation
import SwiftUIFlow

enum AppRoute: Route {
    case tabRoot
    case login

    var identifier: String {
        switch self {
        case .tabRoot: return "tabRoot"
        case .login: return "login"
        }
    }
}

enum RedRoute: Route {
    case red
    case lightRed
    case darkRed

    var identifier: String {
        switch self {
        case .red: return "red"
        case .lightRed: return "lightRed"
        case .darkRed: return "darkRed"
        }
    }
}

enum GreenRoute: Route {
    case green
    case lightGreen
    case darkGreen
    case evenDarkerGreen

    var identifier: String {
        switch self {
        case .green: return "green"
        case .lightGreen: return "lightGreen"
        case .darkGreen: return "darkGreen"
        case .evenDarkerGreen: return "evenDarkerGreen"
        }
    }
}

enum BlueRoute: Route {
    case blue
    case lightBlue
    case darkBlue
    case invalidView // Coordinator handles but ViewFactory returns nil

    var identifier: String {
        switch self {
        case .blue: return "blue"
        case .lightBlue: return "lightBlue"
        case .darkBlue: return "darkBlue"
        case .invalidView: return "invalidView"
        }
    }
}

enum YellowRoute: Route {
    case yellow
    case lightYellow
    case darkYellow

    var identifier: String {
        switch self {
        case .yellow: return "yellow"
        case .lightYellow: return "lightYellow"
        case .darkYellow: return "darkYellow"
        }
    }
}

enum PurpleRoute: Route {
    case purple
    case lightPurple
    case darkPurple
    case result(success: Bool)

    var identifier: String {
        switch self {
        case .purple: return "purple"
        case .lightPurple: return "lightPurple"
        case .darkPurple: return "darkPurple"
        case let .result(success): return "result_\(success)"
        }
    }
}

// Route type that NO coordinator handles - for testing navigationFailed error
enum UnhandledRoute: Route {
    case invalidRoute

    var identifier: String {
        return "invalidRoute"
    }
}
