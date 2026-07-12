//
//  ContactFormFields.swift
//  ContactManager
//
//  Reusable Form sections for name/phone/email + optional favorite toggle,
//  with inline validation messages. Used by Create, Detail, and Me screens.
//

import SwiftUI

struct ContactFormFields: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var phoneNumber: String
    @Binding var email: String
    /// Optional so the Me screen (no favorite concept) can omit the toggle.
    var isFavorite: Binding<Bool>? = nil
    var errors: [ContactField: String] = [:]
    /// Fields that should show a required marker (empty ones block Save).
    var requiredFields: Set<ContactField> = []
    var isEditable: Bool = true

    var body: some View {
        Section("Name") {
            field(.firstName, title: "First Name", text: $firstName, error: errors[.firstName]) {
                $0.textContentType(.givenName)
            }
            field(.lastName, title: "Last Name", text: $lastName, error: errors[.lastName]) {
                $0.textContentType(.familyName)
            }
        }

        Section("Contact") {
            field(.phoneNumber, title: "Phone", text: $phoneNumber, error: errors[.phoneNumber]) {
                $0.textContentType(.telephoneNumber).keyboardType(.phonePad)
            }
            field(.email, title: "Email", text: $email, error: errors[.email]) {
                $0.textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }

        if let isFavorite {
            Section {
                Toggle(isOn: isFavorite) {
                    Label("Favorite", systemImage: "star")
                }
                .disabled(!isEditable)
            }
        }
    }

    @ViewBuilder
    private func field<Content: View>(
        _ id: ContactField,
        title: String,
        text: Binding<String>,
        error: String?,
        modifiers: (TextField<Text>) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 2) {
                modifiers(TextField(title, text: text))
                    .disabled(!isEditable)
                    .foregroundStyle(isEditable ? .primary : .secondary)
                if requiredFields.contains(id) && text.wrappedValue.isEmpty {
                    Text("*")
                        .foregroundStyle(.red)
                        .accessibilityLabel("\(title) required")
                }
            }
            if let error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("\(title) error: \(error)")
            }
        }
    }
}
