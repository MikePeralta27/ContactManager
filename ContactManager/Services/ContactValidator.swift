//
//  ContactValidator.swift
//  ContactManager
//

import Foundation

/// Identifies each editable field so views can show errors inline.
enum ContactField: String, CaseIterable {
    case firstName
    case lastName
    case phoneNumber
    case email
}

/// Pure, stateless validation - trivially unit testable (no I/O, no state).
enum ContactValidator {

    // MARK: - Individual field rules

    static func validateFirstName(_ value: String) -> String? {
        validateName(value, fieldLabel: "First name", required: true)
    }

    static func validateLastName(_ value: String) -> String? {
        // Last name is optional; only its format is checked when provided.
        validateName(value, fieldLabel: "Last name", required: false)
    }

    static func validateName(_ value: String, fieldLabel: String, required: Bool) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return required ? "\(fieldLabel) is required." : nil }
        if trimmed.count > 50 { return "\(fieldLabel) must be 50 characters or fewer." }
        // Unicode letter class (accented / international names) plus digits.
        let pattern = "^[\\p{L}0-9][\\p{L}0-9 '\\-]*$"
        if trimmed.range(of: pattern, options: .regularExpression) == nil {
            return "\(fieldLabel) contains invalid characters."
        }
        return nil
    }

    static func validatePhone(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Phone number is required." }
        // Allowed input characters.
        let allowed = "^[0-9+()\\-\\s]+$"
        if trimmed.range(of: allowed, options: .regularExpression) == nil {
            return "Phone number contains invalid characters."
        }
        let digits = trimmed.filter(\.isNumber)
        if digits.count < 7 || digits.count > 15 {
            return "Phone number must have 7 to 15 digits."
        }
        return nil
    }

    static func validateEmail(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        // Email is optional; only its format is checked when provided.
        if trimmed.isEmpty { return nil }
        // Permissive but standard email shape.
        let pattern = "^[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$"
        if trimmed.range(of: pattern, options: .regularExpression) == nil {
            return "Enter a valid email address."
        }
        return nil
    }

    // MARK: - Aggregate

    /// Returns a dictionary of field -> error message. Empty means valid.
    static func validateAll(
        firstName: String,
        lastName: String,
        phoneNumber: String,
        email: String
    ) -> [ContactField: String] {
        var errors: [ContactField: String] = [:]
        if let e = validateFirstName(firstName) { errors[.firstName] = e }
        if let e = validateLastName(lastName) { errors[.lastName] = e }
        if let e = validatePhone(phoneNumber) { errors[.phoneNumber] = e }
        if let e = validateEmail(email) { errors[.email] = e }
        return errors
    }
}
