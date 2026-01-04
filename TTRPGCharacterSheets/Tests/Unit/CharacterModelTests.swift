//
//  CharacterModelTests.swift
//  TTRPGCharacterSheetsTests
//
//  Created by Claude on 2026-01-04.
//

import XCTest
import SwiftData
@testable import TTRPGCharacterSheets

@MainActor
final class CharacterModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        let schema = Schema([
            Template.self,
            Character.self,
            PageDrawing.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        modelContext = modelContainer.mainContext
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testCharacterInitialization() {
        // Given
        let name = "Gandalf"

        // When
        let character = Character(name: name)

        // Then
        XCTAssertNotNil(character.id)
        XCTAssertEqual(character.name, name)
        XCTAssertNotNil(character.dateCreated)
        XCTAssertNotNil(character.dateModified)
        XCTAssertTrue(character.pageDrawings.isEmpty)
        XCTAssertNil(character.notes)
        XCTAssertFalse(character.isFavorite)
        XCTAssertEqual(character.lastViewedPageIndex, 0)
    }

    func testCharacterWithTemplate() {
        // Given
        let template = Template(
            name: "D&D Sheet",
            pdfData: Data(),
            pageCount: 3
        )

        // When
        let character = Character(
            name: "Aragorn",
            template: template,
            notes: "Ranger of the North",
            isFavorite: true
        )

        // Then
        XCTAssertEqual(character.template?.id, template.id)
        XCTAssertEqual(character.notes, "Ranger of the North")
        XCTAssertTrue(character.isFavorite)
    }

    // MARK: - Persistence Tests

    func testCharacterPersistence() throws {
        // Given
        let template = Template(
            name: "Test Template",
            pdfData: Data(),
            pageCount: 2
        )

        let character = Character(
            name: "Test Character",
            template: template
        )

        // When
        modelContext.insert(template)
        modelContext.insert(character)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Character>()
        let characters = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(characters.count, 1)
        XCTAssertEqual(characters.first?.name, "Test Character")
    }

    // MARK: - Update Modification Date Tests

    func testUpdateModificationDate() throws {
        // Given
        let character = Character(name: "Test")
        let originalDate = character.dateModified

        // Wait a bit to ensure time difference
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // When
        character.updateModificationDate()

        // Then
        XCTAssertGreaterThan(character.dateModified, originalDate)
    }

    // MARK: - Page Drawing Management Tests

    func testGetPageDrawing() {
        // Given
        let character = Character(name: "Test")
        let pageDrawing = PageDrawing(pageIndex: 0, character: character)
        character.pageDrawings.append(pageDrawing)

        // When
        let retrieved = character.getPageDrawing(for: 0)

        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.pageIndex, 0)
    }

    func testGetPageDrawingNonExistent() {
        // Given
        let character = Character(name: "Test")

        // When
        let retrieved = character.getPageDrawing(for: 5)

        // Then
        XCTAssertNil(retrieved)
    }

    func testCreatePageDrawingIfNeeded_New() {
        // Given
        let character = Character(name: "Test")

        // When
        let pageDrawing = character.createPageDrawingIfNeeded(for: 2)

        // Then
        XCTAssertEqual(pageDrawing.pageIndex, 2)
        XCTAssertEqual(character.pageDrawings.count, 1)
        XCTAssertEqual(character.pageDrawings.first?.pageIndex, 2)
    }

    func testCreatePageDrawingIfNeeded_Existing() {
        // Given
        let character = Character(name: "Test")
        let existingDrawing = PageDrawing(pageIndex: 1, character: character)
        character.pageDrawings.append(existingDrawing)

        // When
        let pageDrawing = character.createPageDrawingIfNeeded(for: 1)

        // Then
        XCTAssertEqual(pageDrawing.id, existingDrawing.id)
        XCTAssertEqual(character.pageDrawings.count, 1) // Still only 1
    }

    // MARK: - Computed Properties Tests

    func testTemplateNameWithTemplate() {
        // Given
        let template = Template(
            name: "Pathfinder Sheet",
            pdfData: Data(),
            pageCount: 1
        )
        let character = Character(name: "Test", template: template)

        // When
        let templateName = character.templateName

        // Then
        XCTAssertEqual(templateName, "Pathfinder Sheet")
    }

    func testTemplateNameWithoutTemplate() {
        // Given
        let character = Character(name: "Test")

        // When
        let templateName = character.templateName

        // Then
        XCTAssertEqual(templateName, "Unknown Template")
    }

    func testPageCount() {
        // Given
        let template = Template(
            name: "Multi-page",
            pdfData: Data(),
            pageCount: 5
        )
        let character = Character(name: "Test", template: template)

        // When
        let pageCount = character.pageCount

        // Then
        XCTAssertEqual(pageCount, 5)
    }

    func testPageCountWithoutTemplate() {
        // Given
        let character = Character(name: "Test")

        // When
        let pageCount = character.pageCount

        // Then
        XCTAssertEqual(pageCount, 0)
    }

    func testFormattedDates() {
        // Given
        let character = Character(name: "Test")

        // When
        let creationDate = character.formattedCreationDate
        let modificationDate = character.formattedModificationDate

        // Then
        XCTAssertFalse(creationDate.isEmpty)
        XCTAssertFalse(modificationDate.isEmpty)
    }

    // MARK: - Cascade Delete Tests

    func testPageDrawingsCascadeDelete() throws {
        // Given
        let character = Character(name: "Test")
        let drawing1 = PageDrawing(pageIndex: 0, character: character)
        let drawing2 = PageDrawing(pageIndex: 1, character: character)

        modelContext.insert(character)
        modelContext.insert(drawing1)
        modelContext.insert(drawing2)
        try modelContext.save()

        // When
        modelContext.delete(character)
        try modelContext.save()

        // Then
        let drawingDescriptor = FetchDescriptor<PageDrawing>()
        let remainingDrawings = try modelContext.fetch(drawingDescriptor)

        XCTAssertTrue(remainingDrawings.isEmpty)
    }

    // MARK: - Favorite Tests

    func testToggleFavorite() {
        // Given
        let character = Character(name: "Test", isFavorite: false)

        // When
        character.isFavorite.toggle()

        // Then
        XCTAssertTrue(character.isFavorite)

        // When - Toggle again
        character.isFavorite.toggle()

        // Then
        XCTAssertFalse(character.isFavorite)
    }

    // MARK: - Last Viewed Page Tests

    func testLastViewedPageIndex() {
        // Given
        let character = Character(name: "Test")

        // When
        character.lastViewedPageIndex = 3

        // Then
        XCTAssertEqual(character.lastViewedPageIndex, 3)
    }
}
