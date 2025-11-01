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

    /// Helper to wrap any View in AnyView for cleaner syntax
    public func view(_ view: some View) -> AnyView {
        return AnyView(view)
    }
}
