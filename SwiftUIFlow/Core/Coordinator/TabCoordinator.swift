//
//  TabCoordinator.swift
//  SwiftUIFlow
//
//  Created by Ioannis Platsis on 15/9/25.
//

import Foundation

open class TabCoordinator<R: Route>: Coordinator<R> {
    override public var navigationType: NavigationType {
        return .tabSwitch(index: 0)
    }

    open func getTabIndex(for coordinator: AnyCoordinator) -> Int? {
        for (index, child) in children.enumerated() {
            if child === coordinator {
                return index
            }
        }
        return nil
    }

    open func switchToTab(_ index: Int) {
        router.selectTab(index)
    }
}
