//
//  ContactDTO.swift
//  ContactManager
//
//  Plain @objc value object used to carry contact data across the
//  Swift <-> Objective-C boundary. SwiftData @Model types cannot be @objc,
//  so the UIKit list consumes DTOs instead of the live model.
//

import Foundation

@objc(ContactDTO)
final class ContactDTO: NSObject {
    @objc let id: String
    @objc let firstName: String
    @objc let lastName: String
    @objc let phoneNumber: String
    @objc let email: String
    @objc let isFavorite: Bool
    @objc let isUserProfile: Bool
    @objc let imageData: Data?

    @objc var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    init(
        id: String,
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String,
        isFavorite: Bool,
        isUserProfile: Bool,
        imageData: Data?
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumber = phoneNumber
        self.email = email
        self.isFavorite = isFavorite
        self.isUserProfile = isUserProfile
        self.imageData = imageData
    }

    convenience init(contact: Contact) {
        self.init(
            id: contact.id.uuidString,
            firstName: contact.firstName,
            lastName: contact.lastName,
            phoneNumber: contact.phoneNumber,
            email: contact.email,
            isFavorite: contact.isFavorite,
            isUserProfile: contact.isUserProfile,
            imageData: contact.imageData
        )
    }
}
