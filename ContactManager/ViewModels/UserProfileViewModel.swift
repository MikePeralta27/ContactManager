//
//  UserProfileViewModel.swift
//  ContactManager
//
//  Drives the "Me" tab: loads the single user-profile record, toggles edit
//  mode, generates a profile image, and saves through the store.
//  @MainActor so UI state (including post-await image updates) stays on main.
//

import Foundation
import Observation

@Observable
@MainActor
final class UserProfileViewModel {
    var firstName: String = ""
    var lastName: String = ""
    var phoneNumber: String = "" {
        didSet {
            let formatted = PhoneNumberFormatter.format(phoneNumber)
            if formatted != phoneNumber { phoneNumber = formatted }
        }
    }
    var email: String = "" {
        didSet {
            let formatted = email.lowercased().filter { !$0.isWhitespace }
            if formatted != email { email = formatted }
        }
    }
    var imageData: Data?

    var isEditing: Bool = false
    var errors: [ContactField: String] = [:]
    var isGeneratingImage: Bool = false
    var imageErrorMessage: String?

    private var profileID: String?
    private let imageService: ImageServiceProviding

    /// Baseline captured on load/save; compared against `currentSnapshot`.
    private var savedSnapshot = ContactDraftSnapshot()

    private var currentSnapshot: ContactDraftSnapshot {
        ContactDraftSnapshot(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            imageData: imageData
        )
    }

    /// True when any editable field differs from the last loaded/saved values.
    var hasUnsavedChanges: Bool { currentSnapshot != savedSnapshot }

    init(imageService: ImageServiceProviding = ImageService()) {
        self.imageService = imageService
    }

    func load(from store: ContactStore) {
        guard let profile = store.userProfile() else { return }
        profileID = profile.id.uuidString
        firstName = profile.firstName
        lastName = profile.lastName
        phoneNumber = profile.phoneNumber
        email = profile.email
        imageData = profile.imageData
        savedSnapshot = currentSnapshot
    }

    @discardableResult
    func validate() -> Bool {
        errors = ContactValidator.validateAll(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email
        )
        return errors.isEmpty
    }
    
    var isValid: Bool {
        ContactValidator.validateAll(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email
        ).isEmpty
    }
    /// Inline errors while typing; skip empty fields so * markers handle “required”.
    var visibleErrors: [ContactField: String] {
        var result: [ContactField: String] = [:]
        if !firstName.isEmpty, let e = ContactValidator.validateFirstName(firstName) {
            result[.firstName] = e
        }
        if !lastName.isEmpty, let e = ContactValidator.validateLastName(lastName) {
            result[.lastName] = e
        }
        if !phoneNumber.isEmpty, let e = ContactValidator.validatePhone(phoneNumber) {
            result[.phoneNumber] = e
        }
        if !email.isEmpty, let e = ContactValidator.validateEmail(email) {
            result[.email] = e
        }
        return result
    }

    /// Returns true if the profile was valid and saved.
    @discardableResult
    func save(to store: ContactStore) -> Bool {
        guard validate(), let profileID else { return false }
        store.updateContact(
            id: profileID,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            isFavorite: false,
            imageData: imageData
        )
        savedSnapshot = currentSnapshot
        isEditing = false
        return true
    }

    /// Discards in-flight edits and restores the last saved values.
    func cancelEditing(reloadFrom store: ContactStore) {
        load(from: store)
        errors = [:]
        isEditing = false
    }

    func generateImage() async {
        isGeneratingImage = true
        imageErrorMessage = nil
        defer { isGeneratingImage = false }
        do {
            imageData = try await imageService.fetchRandomImage()
        } catch {
            imageErrorMessage = error.localizedDescription
        }
    }
}
