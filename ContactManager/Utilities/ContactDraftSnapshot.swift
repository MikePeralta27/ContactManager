//
//  ContactDraftSnapshot.swift
//  ContactManager
//
//  A value snapshot of the editable contact fields. View models keep a saved
//  baseline snapshot and compare it against the current one to detect whether
//  the form has unsaved changes.
//

import Foundation

struct ContactDraftSnapshot: Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var phoneNumber: String = ""
    var email: String = ""
    var isFavorite: Bool = false
    var imageData: Data?
}
