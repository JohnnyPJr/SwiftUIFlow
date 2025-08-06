//
//  ViewFactory.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 7/8/25.
//

import Combine
import Foundation
import SwiftUI

open class ViewFactory<R: Route>: ObservableObject {
    public init() {}

    open func buildView(for route: R) -> AnyView? { nil }
}
