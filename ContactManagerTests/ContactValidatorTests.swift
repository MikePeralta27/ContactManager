//
//  ContactValidatorTests.swift
//  ContactManagerTests
//

import XCTest
@testable import ContactManager

final class ContactValidatorTests: XCTestCase {

    // MARK: - Names

    func testValidNamePasses() {
        XCTAssertNil(ContactValidator.validateFirstName("Michael"))
        XCTAssertNil(ContactValidator.validateLastName("Peralta"))
    }

    func testAccentedNamePasses() {
        // Unicode letter class must accept accented / international names.
        XCTAssertNil(ContactValidator.validateFirstName("José"))
        XCTAssertNil(ContactValidator.validateLastName("Müller"))
        XCTAssertNil(ContactValidator.validateFirstName("Renée"))
    }

    func testEmptyFirstNameFails() {
        XCTAssertNotNil(ContactValidator.validateFirstName(""))
        XCTAssertNotNil(ContactValidator.validateFirstName("   "))
    }

    func testEmptyLastNameIsAllowed() {
        // Last name is optional.
        XCTAssertNil(ContactValidator.validateLastName(""))
        XCTAssertNil(ContactValidator.validateLastName("   "))
    }

    func testNameWithDigitsIsAllowed() {
        XCTAssertNil(ContactValidator.validateFirstName("John3"))
        XCTAssertNil(ContactValidator.validateLastName("Agent007"))
    }

    func testTooLongNameFails() {
        XCTAssertNotNil(ContactValidator.validateFirstName(String(repeating: "a", count: 21)))
    }

    // MARK: - Phone

    func testValidPhonePasses() {
        XCTAssertNil(ContactValidator.validatePhone("+1 (555) 123-4567"))
        XCTAssertNil(ContactValidator.validatePhone("5551234"))
    }

    func testPhoneTooShortFails() {
        XCTAssertNotNil(ContactValidator.validatePhone("12345"))
    }

    func testPhoneWithLettersFails() {
        XCTAssertNotNil(ContactValidator.validatePhone("555-CALL"))
    }

    // MARK: - Email

    func testValidEmailPasses() {
        XCTAssertNil(ContactValidator.validateEmail("test@example.com"))
        XCTAssertNil(ContactValidator.validateEmail("first.last+tag@sub.domain.co"))
    }

    func testInvalidEmailFails() {
        XCTAssertNotNil(ContactValidator.validateEmail("not-an-email"))
        XCTAssertNotNil(ContactValidator.validateEmail("missing@domain"))
        XCTAssertNotNil(ContactValidator.validateEmail("@example.com"))
    }

    func testEmptyEmailIsAllowed() {
        // Email is optional.
        XCTAssertNil(ContactValidator.validateEmail(""))
        XCTAssertNil(ContactValidator.validateEmail("   "))
    }

    // MARK: - Aggregate

    func testValidateAllRequiresOnlyNameAndPhone() {
        let errors = ContactValidator.validateAll(
            firstName: "",
            lastName: "",
            phoneNumber: "",
            email: ""
        )
        // Only first name and phone are mandatory.
        XCTAssertEqual(errors.count, 2)
        XCTAssertNotNil(errors[.firstName])
        XCTAssertNotNil(errors[.phoneNumber])
        XCTAssertNil(errors[.lastName])
        XCTAssertNil(errors[.email])
    }

    func testValidateAllValidWithOnlyNameAndPhone() {
        // Last name and email omitted -> still valid.
        let errors = ContactValidator.validateAll(
            firstName: "Ada",
            lastName: "",
            phoneNumber: "5551234567",
            email: ""
        )
        XCTAssertTrue(errors.isEmpty)
    }

    func testValidateAllReportsBadEmailWhenProvided() {
        let errors = ContactValidator.validateAll(
            firstName: "Ada",
            lastName: "",
            phoneNumber: "5551234567",
            email: "bad-email"
        )
        XCTAssertNotNil(errors[.email])
    }

    func testValidateAllEmptyWhenValid() {
        let errors = ContactValidator.validateAll(
            firstName: "Ada",
            lastName: "Lovelace",
            phoneNumber: "5551234567",
            email: "ada@example.com"
        )
        XCTAssertTrue(errors.isEmpty)
    }
}
