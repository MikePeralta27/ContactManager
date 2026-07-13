//
//  ContactFormViewModelTests.swift
//  ContactManagerTests
//
//  Validation + image generation logic with an injected mock image service.
//

import XCTest
import SwiftData
@testable import ContactManager

@MainActor
final class ContactFormViewModelTests: XCTestCase {

    // Retained so the in-memory context stays valid for the whole test.
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Contact.self, configurations: config)
    }

    override func tearDown() {
        container = nil
    }

    private func makeStoreWithContact() throws -> (ContactStore, String) {
        let store = ContactStore(context: container.mainContext)
        store.createContact(firstName: "Ada", lastName: "Lovelace",
                            phoneNumber: "5551234567", email: "ada@example.com",
                            isFavorite: false, imageData: nil)
        let id = try XCTUnwrap(
            store.contacts(matchingSearch: "", favoritesOnly: false, ascending: true).first?.id
        )
        return (store, id)
    }

    func testValidationFailsWhenEmpty() {
        let vm = ContactFormViewModel(imageService: MockImageService())
        XCTAssertFalse(vm.validate())
        // Only first name and phone are mandatory.
        XCTAssertEqual(vm.errors.count, 2)
        XCTAssertNotNil(vm.errors[.firstName])
        XCTAssertNotNil(vm.errors[.phoneNumber])
    }

    func testValidationPassesWhenComplete() {
        let vm = ContactFormViewModel(imageService: MockImageService())
        vm.firstName = "Ada"
        vm.lastName = "Lovelace"
        vm.phoneNumber = "5551234567"
        vm.email = "ada@example.com"
        XCTAssertTrue(vm.validate())
        XCTAssertTrue(vm.errors.isEmpty)
    }

    func testSaveUpdatePersistsChangesAndReturnsTrue() throws {
        let (store, id) = try makeStoreWithContact()

        let vm = ContactFormViewModel(imageService: MockImageService())
        vm.firstName = "Ada"
        vm.lastName = "Byron"        // last name is optional but valid here
        vm.phoneNumber = "5559998888"
        vm.email = ""                // email now optional

        XCTAssertTrue(vm.saveUpdate(to: store, id: id))

        let updated = try XCTUnwrap(store.contact(withID: id))
        XCTAssertEqual(updated.lastName, "Byron")
        XCTAssertEqual(updated.phoneNumber.filter(\.isNumber), "5559998888")
        XCTAssertEqual(updated.email, "")
    }

    func testSaveUpdateFailsWhenInvalidAndLeavesContactUnchanged() throws {
        let (store, id) = try makeStoreWithContact()

        let vm = ContactFormViewModel(imageService: MockImageService())
        vm.firstName = ""            // required -> invalid
        vm.phoneNumber = "5551234567"

        XCTAssertFalse(vm.saveUpdate(to: store, id: id))
        XCTAssertNotNil(vm.errors[.firstName])

        let unchanged = try XCTUnwrap(store.contact(withID: id))
        XCTAssertEqual(unchanged.firstName, "Ada")
    }

    func testHasUnsavedChangesFalseAfterLoad() throws {
        let (store, id) = try makeStoreWithContact()
        let contact = try XCTUnwrap(store.contact(withID: id))
        let vm = ContactFormViewModel(imageService: MockImageService())
        vm.load(from: contact)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testHasUnsavedChangesTrueAfterEditingField() throws {
        let (store, id) = try makeStoreWithContact()
        let contact = try XCTUnwrap(store.contact(withID: id))
        let vm = ContactFormViewModel(imageService: MockImageService())
        vm.load(from: contact)
        vm.lastName = "Changed"
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func testHasUnsavedChangesFalseAgainAfterSave() throws {
        let (store, id) = try makeStoreWithContact()
        let contact = try XCTUnwrap(store.contact(withID: id))
        let vm = ContactFormViewModel(imageService: MockImageService())
        vm.load(from: contact)
        vm.lastName = "Changed"
        XCTAssertTrue(vm.saveUpdate(to: store, id: id))
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testGenerateImageSetsData() async {
        let expected = Data([0xAA, 0xBB, 0xCC])
        let vm = ContactFormViewModel(imageService: MockImageService(dataToReturn: expected))
        XCTAssertNil(vm.imageData)
        await vm.generateImage()
        XCTAssertEqual(vm.imageData, expected)
        XCTAssertFalse(vm.isGeneratingImage)
        XCTAssertNil(vm.imageErrorMessage)
    }

    func testGenerateImageHandlesError() async {
        let vm = ContactFormViewModel(imageService: MockImageService(shouldThrow: true))
        await vm.generateImage()
        XCTAssertNil(vm.imageData)
        XCTAssertNotNil(vm.imageErrorMessage)
    }
}
