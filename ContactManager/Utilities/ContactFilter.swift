//
//  ContactFilter.swift
//  ContactManager
//

import Foundation

/// Which subset of contacts a list screen shows.
enum ContactFilter {
    case all
    case favorites

    var title: String {
        switch self {
        case .all: return "Contacts"
        case .favorites: return "Favorites"
        }
    }
}
