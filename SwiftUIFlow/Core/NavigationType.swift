//
//  NavigationType.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 15/9/25.
//

import Foundation

public enum NavigationType: Equatable {
    case push
    case replace
    case modal
    case detour
    case tabSwitch(index: Int)
}
