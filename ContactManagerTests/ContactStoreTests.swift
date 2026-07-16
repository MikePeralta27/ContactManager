//
//  ContactStoreTests.swift
//  ContactManagerTests
//
//  Exercises the shared store's search-by-any-field, favorites filter, sort,
//  and delete guard using an in-memory SwiftData container.
//

import XCTest
import SwiftData
@testable import ContactManager

@MainActor
final class ContactStoreTests: XCTestCase {

    // Retained for the lifetime of each test so the in-memory context stays valid.
    private var container: ModelContainer!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Contact.self, configurations: config)
    }

    override func tearDown() {
        container = nil
    }

    private func makeStore() throws -> (ContactStore, ModelContext) {
        let context = container.mainContext
        return (ContactStore(context: context), context)
    }

    private func seed(_ context: ModelContext) {
        context.insert(Contact(firstName: "Ada", lastName: "Lovelace",
                               phoneNumber: "5551110000", email: "ada@math.org",
                               isFavorite: true))
        context.insert(Contact(firstName: "Alan", lastName: "Turing",
                               phoneNumber: "5552223333", email: "alan@enigma.uk",
                               isFavorite: false))
        context.insert(Contact(firstName: "Grace", lastName: "Hopper",
                               phoneNumber: "5559998888", email: "grace@navy.mil",
                               isFavorite: true))
        // A user-profile record that must be excluded from lists.
        context.insert(Contact(firstName: "Me", lastName: "",
                               phoneNumber: "", email: "",
                               isUserProfile: true))
        try? context.save()
    }

    func testExcludesUserProfile() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let all = store.contacts(matchingSearch: "", favoritesOnly: false, ascending: true)
        XCTAssertEqual(all.count, 3)
        XCTAssertFalse(all.contains { $0.isUserProfile })
    }

    func testSearchByFirstName() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let results = store.contacts(matchingSearch: "grace", favoritesOnly: false, ascending: true)
        XCTAssertEqual(results.map(\.firstName), ["Grace"])
    }

    func testSearchByLastName() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let results = store.contacts(matchingSearch: "turing", favoritesOnly: false, ascending: true)
        XCTAssertEqual(results.map(\.firstName), ["Alan"])
    }

    func testSearchByPhone() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let results = store.contacts(matchingSearch: "9998", favoritesOnly: false, ascending: true)
        XCTAssertEqual(results.map(\.firstName), ["Grace"])
    }

    func testSearchByEmail() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let results = store.contacts(matchingSearch: "enigma", favoritesOnly: false, ascending: true)
        XCTAssertEqual(results.map(\.firstName), ["Alan"])
    }

    func testFavoritesOnly() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let favs = store.contacts(matchingSearch: "", favoritesOnly: true, ascending: true)
        XCTAssertEqual(Set(favs.map(\.firstName)), ["Ada", "Grace"])
    }

    func testAscendingAndDescendingSort() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let asc = store.contacts(matchingSearch: "", favoritesOnly: false, ascending: true)
        XCTAssertEqual(asc.map(\.firstName), ["Ada", "Alan", "Grace"])
        let desc = store.contacts(matchingSearch: "", favoritesOnly: false, ascending: false)
        XCTAssertEqual(desc.map(\.firstName), ["Grace", "Alan", "Ada"])
    }

    func testCreateContactAppears() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let created = store.createContact(firstName: "Katherine", lastName: "Johnson",
                                          phoneNumber: "5554445555", email: "kj@nasa.gov",
                                          isFavorite: false, imageData: nil)
        XCTAssertNotNil(created)
        let all = store.contacts(matchingSearch: "", favoritesOnly: false, ascending: true)
        XCTAssertEqual(all.count, 4)
    }

    func testDeleteRemovesContact() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let all = store.contacts(matchingSearch: "alan", favoritesOnly: false, ascending: true)
        let id = try XCTUnwrap(all.first?.id)
        XCTAssertTrue(store.deleteContacts(ids: [id]))
        let after = store.contacts(matchingSearch: "alan", favoritesOnly: false, ascending: true)
        XCTAssertTrue(after.isEmpty)
    }

    func testDeleteGuardsUserProfile() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let profile = try XCTUnwrap(store.userProfile())
        // Profile is skipped; empty delete still saves successfully.
        XCTAssertTrue(store.deleteContacts(ids: [profile.id.uuidString]))
        XCTAssertNotNil(store.userProfile(), "The user profile must not be deletable.")
    }

    func testSetFavorite() throws {
        let (store, ctx) = try makeStore()
        seed(ctx)
        let alan = try XCTUnwrap(
            store.contacts(matchingSearch: "alan", favoritesOnly: false, ascending: true).first
        )
        XCTAssertTrue(store.setFavorite(true, forID: alan.id))
        let favs = store.contacts(matchingSearch: "", favoritesOnly: true, ascending: true)
        XCTAssertTrue(favs.contains { $0.firstName == "Alan" })
    }
}
