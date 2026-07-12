//
//  ContactSortOrder.swift
//  ContactManager
//
//  Named `ContactSortOrder` to avoid clashing with Foundation.SortOrder.
//

import Foundation

enum ContactSortOrder: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var label: String {
        switch self {
        case .ascending: return "Name (A-Z)"
        case .descending: return "Name (Z-A)"
        }
    }

    var isAscending: Bool { self == .ascending }
}
