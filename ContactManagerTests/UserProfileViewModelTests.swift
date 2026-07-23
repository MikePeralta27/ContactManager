//
//  UserProfileViewModelTests.swift
//  ContactManagerTests
//
//  Covers the "Me" tab view model: loading the profile, saving edits, and the
//  discard flow that restores the last saved values.
//

import XCTest
import SwiftData
@testable import ContactManager

@MainActor
final class UserProfileViewModelTests: XCTestCase {

    // Retained so the in-memory context stays valid for the whole test.
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Contact.self, configurations: config)
    }

    override func tearDown() {
        container = nil
    }

    private func makeStoreWithProfile() -> ContactStore {
        let context = container.mainContext
        context.insert(Contact(firstName: "Me", lastName: "Owner",
                               phoneNumber: "5551110000", email: "me@example.com",
                               isUserProfile: true))
        try? context.save()
        return ContactStore(context: context)
    }

    func testLoadPopulatesProfileFields() {
        let store = makeStoreWithProfile()
        let vm = UserProfileViewModel(imageService: MockImageService())

        vm.load(from: store)

        XCTAssertEqual(vm.firstName, "Me")
        XCTAssertEqual(vm.lastName, "Owner")
        XCTAssertEqual(vm.phoneNumber.filter(\.isNumber), "5551110000")
        XCTAssertEqual(vm.email, "me@example.com")
    }

    func testSavePersistsChangesAndExitsEditing() throws {
        let store = makeStoreWithProfile()
        let vm = UserProfileViewModel(imageService: MockImageService())
        vm.load(from: store)
        vm.isEditing = true

        vm.firstName = "Renamed"
        XCTAssertTrue(vm.save(to: store))
        XCTAssertFalse(vm.isEditing)
        XCTAssertNil(vm.saveErrorMessage)

        let profile = try XCTUnwrap(store.userProfile())
        XCTAssertEqual(profile.firstName, "Renamed")
    }

    func testHasUnsavedChangesFalseAfterLoad() {
        let store = makeStoreWithProfile()
        let vm = UserProfileViewModel(imageService: MockImageService())
        vm.load(from: store)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testHasUnsavedChangesTrueAfterEditingField() {
        let store = makeStoreWithProfile()
        let vm = UserProfileViewModel(imageService: MockImageService())
        vm.load(from: store)
        vm.firstName = "Changed"
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func testHasUnsavedChangesFalseAfterSave() {
        let store = makeStoreWithProfile()
        let vm = UserProfileViewModel(imageService: MockImageService())
        vm.load(from: store)
        vm.isEditing = true
        vm.firstName = "Changed"
        XCTAssertTrue(vm.save(to: store))
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testHasUnsavedChangesFalseAfterCancel() {
        let store = makeStoreWithProfile()
        let vm = UserProfileViewModel(imageService: MockImageService())
        vm.load(from: store)
        vm.isEditing = true
        vm.firstName = "Changed"
        vm.cancelEditing(reloadFrom: store)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testCancelEditingRestoresSavedValues() {
        let store = makeStoreWithProfile()
        let vm = UserProfileViewModel(imageService: MockImageService())
        vm.load(from: store)
        vm.isEditing = true

        // Make in-flight edits, then discard them.
        vm.firstName = "Temp"
        vm.lastName = "Draft"
        vm.email = "temp@draft.dev"
        vm.cancelEditing(reloadFrom: store)

        XCTAssertEqual(vm.firstName, "Me")
        XCTAssertEqual(vm.lastName, "Owner")
        XCTAssertEqual(vm.email, "me@example.com")
        XCTAssertFalse(vm.isEditing)
        XCTAssertTrue(vm.errors.isEmpty)
        XCTAssertNil(vm.saveErrorMessage)
    }
}
