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
    case info

    var identifier: String {
        switch self {
        case .red: return "red"
        case .lightRed: return "lightRed"
        case .darkRed: return "darkRed"
        case .info: return "info"
        }
    }
}

// Rainbow routes for testing pushed child coordinators
enum RainbowRoute: Route {
    case red, orange, yellow, green, blue, purple

    var identifier: String {
        switch self {
        case .red: return "rainbow_red"
        case .orange: return "rainbow_orange"
        case .yellow: return "rainbow_yellow"
        case .green: return "rainbow_green"
        case .blue: return "rainbow_blue"
        case .purple: return "rainbow_purple"
        }
    }
}

enum GreenRoute: Route {
    case green
    case lightGreen
    case darkGreen
    case evenDarkerGreen
    case info

    var identifier: String {
        switch self {
        case .green: return "green"
        case .lightGreen: return "lightGreen"
        case .darkGreen: return "darkGreen"
        case .evenDarkerGreen: return "evenDarkerGreen"
        case .info: return "info"
        }
    }
}

enum BlueRoute: Route {
    case blue
    case lightBlue
    case darkBlue
    case invalidView // Coordinator handles but ViewFactory returns nil
    case info

    var identifier: String {
        switch self {
        case .blue: return "blue"
        case .lightBlue: return "lightBlue"
        case .darkBlue: return "darkBlue"
        case .invalidView: return "invalidView"
        case .info: return "info"
        }
    }
}

enum YellowRoute: Route {
    case yellow
    case lightYellow
    case darkYellow
    case info

    var identifier: String {
        switch self {
        case .yellow: return "yellow"
        case .lightYellow: return "lightYellow"
        case .darkYellow: return "darkYellow"
        case .info: return "info"
        }
    }
}

enum PurpleRoute: Route {
    case purple
    case lightPurple
    case darkPurple
    case result(success: Bool)
    case info

    var identifier: String {
        switch self {
        case .purple: return "purple"
        case .lightPurple: return "lightPurple"
        case .darkPurple: return "darkPurple"
        case let .result(success): return "result_\(success)"
        case .info: return "info"
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
