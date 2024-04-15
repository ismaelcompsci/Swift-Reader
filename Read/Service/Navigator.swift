//
//  Navigator.swift
//  Read
//
//  Created by Mirna Olvera on 4/13/24.
//

import Foundation

public enum NavigatorDestination: Hashable {
    case localDetails(book: Book)
    case sourceSearch(search: String)

    var id: String {
        switch self {
        case .localDetails:
            "localDetails"
        case .sourceSearch:
            "sourceSearch"
        }
    }
}

public enum SideMenuNavigation: String, Hashable {
    case home = "Home"
    case settings = "Settings"
    case discover = "Discover"
    case search = "Search"
}

@Observable
public class Navigator {
    public var path: [NavigatorDestination] = []
    public var sideMenuTab: SideMenuNavigation = .home

    public init() {}

    public func navigate(to: NavigatorDestination) {
        path.append(to)
    }
}
