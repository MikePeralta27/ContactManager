//
//  CreateContactFlowTests.swift
//  ContactManagerUITests
//
//  End-to-end: create a contact from the Objective-C list's "Nuevo" button
//  (SwiftUI sheet), then confirm it appears in the UIKit table. Also covers
//  search. This exercises the full ObjC <-> SwiftUI interop round-trip.
//

import XCTest

final class CreateContactFlowTests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// A unique letters-only name so search assertions stay easy to match.
    private func uniqueName() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        return String((0..<8).map { _ in letters.randomElement()! })
    }

    private func launchOnContactsTab() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Contacts"].tap()
        return app
    }

    private func createContact(
        in app: XCUIApplication,
        first: String,
        last: String,
        phone: String,
        email: String
    ) {
        app.navigationBars.buttons["Nuevo"].tap()

        let firstField = app.textFields["First Name"]
        XCTAssertTrue(firstField.waitForExistence(timeout: 5))
        firstField.tap()
        firstField.typeText(first)

        app.textFields["Last Name"].tap()
        app.textFields["Last Name"].typeText(last)

        app.textFields["Phone"].tap()
        app.textFields["Phone"].typeText(phone)

        app.textFields["Email"].tap()
        app.textFields["Email"].typeText(email)

        app.buttons["Save"].tap()
    }

    private func assertLabelExists(_ app: XCUIApplication, containing text: String) {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        let match = app.staticTexts.matching(predicate).firstMatch
        XCTAssertTrue(match.waitForExistence(timeout: 5),
                      "Expected an element whose label contains '\(text)'.")
    }

    func testCreateContactAppearsInList() {
        let app = launchOnContactsTab()
        let first = uniqueName()
        createContact(in: app, first: first, last: "Tester",
                      phone: "5551234567", email: "tester@example.com")

        // Back on the Objective-C table, the new contact should be present.
        assertLabelExists(app, containing: first)
    }

    func testSearchFiltersList() {
        let app = launchOnContactsTab()
        let first = uniqueName()
        createContact(in: app, first: first, last: "Person",
                      phone: "5559990000", email: "person@example.com")

        // Activate the search bar; wait for the keyboard before typing.
        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        if !app.keyboards.firstMatch.waitForExistence(timeout: 3) {
            search.tap()
            _ = app.keyboards.firstMatch.waitForExistence(timeout: 3)
        }
        search.typeText(first)

        assertLabelExists(app, containing: first)
    }
}
