//
//  ContactFormViewModel.swift
//  ContactManager
//
//  Drives the Create sheet and the Detail screen. Holds draft fields,
//  validation errors, and image-generation state. Image fetching goes through
//  an injected ImageServiceProviding so tests can supply a mock.
//

import Foundation
import Observation

@Observable
final class ContactFormViewModel {
    var firstName: String = ""
    var lastName: String = ""
    /// Only ever holds digits + phone separators; formatted live as typed.
    var phoneNumber: String = "" {
        didSet {
            let formatted = PhoneNumberFormatter.format(phoneNumber)
            if formatted != phoneNumber { phoneNumber = formatted }
        }
    }
    /// Lowercased and whitespace-free (email format) as typed.
    var email: String = "" {
        didSet {
            let formatted = email.lowercased().filter { !$0.isWhitespace }
            if formatted != email { email = formatted }
        }
    }
    var isFavorite: Bool = false
    var imageData: Data?

    var errors: [ContactField: String] = [:]
    var isGeneratingImage: Bool = false
    var imageErrorMessage: String?

    private let imageService: ImageServiceProviding

    /// Baseline captured on load/save; compared against `currentSnapshot`.
    private var savedSnapshot = ContactDraftSnapshot()

    private var currentSnapshot: ContactDraftSnapshot {
        ContactDraftSnapshot(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            isFavorite: isFavorite,
            imageData: imageData
        )
    }

    /// True when any editable field differs from the last loaded/saved values.
    var hasUnsavedChanges: Bool { currentSnapshot != savedSnapshot }

    init(imageService: ImageServiceProviding = ImageService()) {
        self.imageService = imageService
    }

    /// Prefill from an existing contact (Detail screen).
    func load(from contact: Contact) {
        firstName = contact.firstName
        lastName = contact.lastName
        phoneNumber = contact.phoneNumber
        email = contact.email
        isFavorite = contact.isFavorite
        imageData = contact.imageData
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

    /// Validates and, if valid, writes changes back to an existing contact.
    /// Returns false (and surfaces inline errors) when the form is invalid.
    @MainActor
    @discardableResult
    func saveUpdate(to store: ContactStore, id: String) -> Bool {
        guard validate() else { return false }
        store.updateContact(
            id: id,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            email: email,
            isFavorite: isFavorite,
            imageData: imageData
        )
        savedSnapshot = currentSnapshot
        return true
    }

    /// Errors to show inline while typing: only for fields that have content
    /// (so empty required fields can show a marker without a red error).
    /// Create Contact also disables Save until `isValid`; Detail validates on Save tap.
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

    func generateImage() async {
        isGeneratingImage = true
        imageErrorMessage = nil
        defer { isGeneratingImage = false }
        do {
            let data = try await imageService.fetchRandomImage()
            imageData = data
        } catch {
            imageErrorMessage = error.localizedDescription
        }
    }
}
