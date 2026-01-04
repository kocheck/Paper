//
//  TemplateModelTests.swift
//  TTRPGCharacterSheetsTests
//
//  Created by Claude on 2026-01-04.
//

import XCTest
import SwiftData
@testable import TTRPGCharacterSheets

@MainActor
final class TemplateModelTests: XCTestCase {
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

    func testTemplateInitialization() {
        // Given
        let name = "D&D 5e Character Sheet"
        let pdfData = Data([0x01, 0x02, 0x03])
        let pageCount = 3

        // When
        let template = Template(
            name: name,
            pdfData: pdfData,
            pageCount: pageCount
        )

        // Then
        XCTAssertNotNil(template.id)
        XCTAssertEqual(template.name, name)
        XCTAssertEqual(template.pdfData, pdfData)
        XCTAssertEqual(template.pageCount, pageCount)
        XCTAssertTrue(template.characters.isEmpty)
        XCTAssertNotNil(template.dateImported)
    }

    func testTemplateWithThumbnail() {
        // Given
        let thumbnailData = Data([0xFF, 0xD8, 0xFF, 0xE0])

        // When
        let template = Template(
            name: "Test Template",
            pdfData: Data(),
            pageCount: 1,
            thumbnailData: thumbnailData
        )

        // Then
        XCTAssertEqual(template.thumbnailData, thumbnailData)
    }

    // MARK: - Persistence Tests

    func testTemplatePersistence() throws {
        // Given
        let template = Template(
            name: "Persistent Template",
            pdfData: Data([0x01, 0x02]),
            pageCount: 2
        )

        // When
        modelContext.insert(template)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<Template>()
        let templates = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(templates.count, 1)
        XCTAssertEqual(templates.first?.name, "Persistent Template")
        XCTAssertEqual(templates.first?.pageCount, 2)
    }

    // MARK: - Relationship Tests

    func testTemplateCharacterRelationship() throws {
        // Given
        let template = Template(
            name: "Test Template",
            pdfData: Data(),
            pageCount: 1
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
        XCTAssertEqual(template.characters.count, 1)
        XCTAssertEqual(template.characters.first?.name, "Test Character")
        XCTAssertEqual(character.template?.id, template.id)
    }

    func testTemplateCascadeDelete() throws {
        // Given
        let template = Template(
            name: "Template to Delete",
            pdfData: Data(),
            pageCount: 1
        )

        let character1 = Character(name: "Character 1", template: template)
        let character2 = Character(name: "Character 2", template: template)

        modelContext.insert(template)
        modelContext.insert(character1)
        modelContext.insert(character2)
        try modelContext.save()

        // When - Delete template
        modelContext.delete(template)
        try modelContext.save()

        // Then - Characters should be deleted
        let characterDescriptor = FetchDescriptor<Character>()
        let remainingCharacters = try modelContext.fetch(characterDescriptor)

        XCTAssertTrue(remainingCharacters.isEmpty)
    }

    // MARK: - Computed Properties Tests

    func testFormattedFileSize() {
        // Given
        let oneMB = Data(count: 1_048_576) // 1 MB
        let template = Template(
            name: "Large Template",
            pdfData: oneMB,
            pageCount: 1
        )

        // When
        let formattedSize = template.formattedFileSize

        // Then
        XCTAssertTrue(formattedSize.contains("MB") || formattedSize.contains("1"))
    }

    func testCharacterCount() throws {
        // Given
        let template = Template(
            name: "Popular Template",
            pdfData: Data(),
            pageCount: 1
        )

        // When - Add characters
        for i in 1...5 {
            let character = Character(name: "Character \(i)", template: template)
            modelContext.insert(character)
        }

        modelContext.insert(template)
        try modelContext.save()

        // Then
        XCTAssertEqual(template.characterCount, 5)
    }

    // MARK: - Query Tests

    func testTemplatesSortedByDateImported() throws {
        // Given
        let template1 = Template(
            name: "First",
            dateImported: Date().addingTimeInterval(-100),
            pdfData: Data(),
            pageCount: 1
        )

        let template2 = Template(
            name: "Second",
            dateImported: Date().addingTimeInterval(-50),
            pdfData: Data(),
            pageCount: 1
        )

        let template3 = Template(
            name: "Third",
            dateImported: Date(),
            pdfData: Data(),
            pageCount: 1
        )

        // When
        modelContext.insert(template1)
        modelContext.insert(template2)
        modelContext.insert(template3)
        try modelContext.save()

        var fetchDescriptor = FetchDescriptor<Template>(
            sortBy: [SortDescriptor(\.dateImported, order: .reverse)]
        )

        let templates = try modelContext.fetch(fetchDescriptor)

        // Then
        XCTAssertEqual(templates.count, 3)
        XCTAssertEqual(templates[0].name, "Third")
        XCTAssertEqual(templates[1].name, "Second")
        XCTAssertEqual(templates[2].name, "First")
    }
}
