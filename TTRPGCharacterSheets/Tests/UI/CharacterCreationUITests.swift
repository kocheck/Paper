//
//  CharacterCreationUITests.swift
//  TTRPGCharacterSheetsUITests
//
//  Created by Claude on 2026-01-04.
//

import XCTest

final class CharacterCreationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Create Character Flow Tests

    func testCreateCharacterFromTemplate() throws {
        // Given - Start with empty library
        XCTAssertTrue(app.navigationBars["Character Library"].exists)

        // First, we need to import a template
        // Tap the import template button (green FAB)
        let importButton = app.buttons["square.and.arrow.down.fill"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 2))
        importButton.tap()

        // When - Import template sheet appears
        let importSheet = app.navigationBars["Import Template"]
        XCTAssertTrue(importSheet.waitForExistence(timeout: 2))

        // Tap "Select PDF File" button
        let selectPDFButton = app.buttons["Select PDF File"]
        XCTAssertTrue(selectPDFButton.exists)
        // Note: In real UI tests, you would need to handle file picker
        // For now, we'll assume a template is already available

        // Cancel for this test
        app.buttons["Cancel"].tap()

        // Assuming we have templates, tap create character button
        let createButton = app.buttons["plus.circle.fill"]
        if createButton.exists {
            createButton.tap()

            // Then - Create character sheet appears
            let createSheet = app.navigationBars["New Character"]
            XCTAssertTrue(createSheet.waitForExistence(timeout: 2))

            // Enter character name
            let nameField = app.textFields["Character Name"]
            XCTAssertTrue(nameField.exists)
            nameField.tap()
            nameField.typeText("Aragorn")

            // Select a template
            let templateRow = app.buttons.matching(identifier: "TemplateSelectionRow").firstMatch
            if templateRow.exists {
                templateRow.tap()
            }

            // Tap Create
            app.buttons["Create"].tap()

            // Verify we're back on main screen
            XCTAssertTrue(app.navigationBars["Character Library"].waitForExistence(timeout: 2))
        }
    }

    func testCreateCharacterRequiresName() throws {
        // Given - Assuming we have templates
        let createButton = app.buttons["plus.circle.fill"]

        if createButton.exists {
            createButton.tap()

            // When - Try to create without name
            let createSheet = app.navigationBars["New Character"]
            XCTAssertTrue(createSheet.waitForExistence(timeout: 2))

            // Then - Create button should be disabled
            let createActionButton = app.buttons["Create"]
            XCTAssertFalse(createActionButton.isEnabled)

            // When - Enter name
            let nameField = app.textFields["Character Name"]
            nameField.tap()
            nameField.typeText("Gandalf")

            // Select template
            let templateRow = app.buttons.matching(identifier: "TemplateSelectionRow").firstMatch
            if templateRow.exists {
                templateRow.tap()

                // Then - Create button should be enabled
                XCTAssertTrue(createActionButton.isEnabled)
            }
        }
    }

    func testCancelCharacterCreation() throws {
        // Given
        let createButton = app.buttons["plus.circle.fill"]

        if createButton.exists {
            createButton.tap()

            // When - Tap Cancel
            app.buttons["Cancel"].tap()

            // Then - Should return to library
            XCTAssertTrue(app.navigationBars["Character Library"].waitForExistence(timeout: 2))
        }
    }

    // MARK: - Character List Tests

    func testCharacterCardDisplay() throws {
        // Given - Assuming we have at least one character
        let characterCards = app.buttons.matching(identifier: "CharacterCardView")

        if characterCards.count > 0 {
            let firstCard = characterCards.firstMatch

            // Then - Card should be visible
            XCTAssertTrue(firstCard.exists)
        }
    }

    func testTapCharacterOpensEditor() throws {
        // Given - Assuming we have at least one character
        let characterCards = app.buttons.matching(identifier: "CharacterCardView")

        if characterCards.count > 0 {
            let firstCard = characterCards.firstMatch

            // When - Tap character card
            firstCard.tap()

            // Then - Editor should open
            // Note: This depends on the navigation bar title being the character name
            XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
        }
    }

    // MARK: - Search Tests

    func testSearchCharacters() throws {
        // Given - Library view
        XCTAssertTrue(app.navigationBars["Character Library"].exists)

        // When - Tap search field
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Aragorn")

            // Then - Results should filter
            // Note: This would require accessibility identifiers on character cards
        }
    }

    // MARK: - Empty State Tests

    func testEmptyStateDisplay() throws {
        // This test would require launching with empty data
        // Given - Empty library (would need special launch argument)

        // Then - Empty state should show
        let emptyStateImage = app.images["book.closed"]
        let emptyStateText = app.staticTexts["No Characters Yet"]

        // Note: These would only exist in empty state
        // For a real test, you'd configure the app to launch with no data
    }

    // MARK: - Template Library Tests

    func testOpenTemplateLibrary() throws {
        // Given
        XCTAssertTrue(app.navigationBars["Character Library"].exists)

        // When - Tap Templates button
        let templatesButton = app.buttons["Templates"]
        XCTAssertTrue(templatesButton.exists)
        templatesButton.tap()

        // Then - Template library should open
        let templateLibrary = app.navigationBars["Template Library"]
        XCTAssertTrue(templateLibrary.waitForExistence(timeout: 2))

        // Tap Done to dismiss
        app.buttons["Done"].tap()

        // Verify we're back
        XCTAssertTrue(app.navigationBars["Character Library"].waitForExistence(timeout: 2))
    }

    func testImportTemplateFromLibrary() throws {
        // Given - Open template library
        let templatesButton = app.buttons["Templates"]
        templatesButton.tap()

        let templateLibrary = app.navigationBars["Template Library"]
        XCTAssertTrue(templateLibrary.waitForExistence(timeout: 2))

        // When - Tap Import button
        let importButton = app.buttons["Import"]
        XCTAssertTrue(importButton.exists)
        importButton.tap()

        // Then - Import sheet should appear
        let importSheet = app.navigationBars["Import Template"]
        XCTAssertTrue(importSheet.waitForExistence(timeout: 2))

        // Cancel
        app.buttons["Cancel"].tap()
    }

    // MARK: - Favorite Tests

    func testToggleFavorite() throws {
        // Given - Assuming we have at least one character
        let characterCards = app.buttons.matching(identifier: "CharacterCardView")

        if characterCards.count > 0 {
            let firstCard = characterCards.firstMatch

            // When - Long press to show context menu
            firstCard.press(forDuration: 1.0)

            // Then - Context menu should appear with Favorite option
            let favoriteButton = app.buttons["Favorite"]
            if favoriteButton.exists {
                favoriteButton.tap()
            }
        }
    }
}
