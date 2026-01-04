//
//  PageDrawingModelTests.swift
//  TTRPGCharacterSheetsTests
//
//  Created by Claude on 2026-01-04.
//

import XCTest
import SwiftData
import PencilKit
@testable import TTRPGCharacterSheets

@MainActor
final class PageDrawingModelTests: XCTestCase {
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

    func testPageDrawingInitialization() {
        // Given
        let pageIndex = 2

        // When
        let pageDrawing = PageDrawing(pageIndex: pageIndex)

        // Then
        XCTAssertNotNil(pageDrawing.id)
        XCTAssertEqual(pageDrawing.pageIndex, pageIndex)
        XCTAssertTrue(pageDrawing.drawingData.isEmpty)
        XCTAssertNotNil(pageDrawing.dateModified)
    }

    func testPageDrawingWithCharacter() {
        // Given
        let character = Character(name: "Test")
        let pageIndex = 0

        // When
        let pageDrawing = PageDrawing(pageIndex: pageIndex, character: character)

        // Then
        XCTAssertEqual(pageDrawing.character?.id, character.id)
        XCTAssertEqual(pageDrawing.pageIndex, pageIndex)
    }

    // MARK: - Persistence Tests

    func testPageDrawingPersistence() throws {
        // Given
        let character = Character(name: "Test")
        let pageDrawing = PageDrawing(pageIndex: 0, character: character)

        // When
        modelContext.insert(character)
        modelContext.insert(pageDrawing)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<PageDrawing>()
        let drawings = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(drawings.count, 1)
        XCTAssertEqual(drawings.first?.pageIndex, 0)
    }

    // MARK: - Update Modification Date Tests

    func testUpdateModificationDate() throws {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)
        let originalDate = pageDrawing.dateModified

        // Wait a bit
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // When
        pageDrawing.updateModificationDate()

        // Then
        XCTAssertGreaterThan(pageDrawing.dateModified, originalDate)
    }

    // MARK: - PencilKit Integration Tests

    func testPKDrawing_EmptyData() {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)

        // When
        let pkDrawing = pageDrawing.pkDrawing

        // Then
        XCTAssertNotNil(pkDrawing)
        XCTAssertTrue(pkDrawing?.strokes.isEmpty ?? false)
    }

    func testSaveDrawing() throws {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)
        let drawing = PKDrawing()

        // When
        try pageDrawing.save(drawing: drawing)

        // Then
        XCTAssertFalse(pageDrawing.drawingData.isEmpty)
        XCTAssertEqual(pageDrawing.drawingData, drawing.dataRepresentation())
    }

    func testSaveAndLoadDrawing() throws {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)

        // Create a drawing with a stroke
        var drawing = PKDrawing()
        let inkingTool = PKInkingTool(.pen, color: .black, width: 5)
        let strokePath = PKStrokePath(
            controlPoints: [
                PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 100, y: 100), timeOffset: 1, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0)
            ],
            creationDate: Date()
        )
        let stroke = PKStroke(ink: inkingTool.ink, path: strokePath)
        drawing.strokes.append(stroke)

        // When
        try pageDrawing.save(drawing: drawing)
        let loadedDrawing = pageDrawing.pkDrawing

        // Then
        XCTAssertNotNil(loadedDrawing)
        XCTAssertEqual(loadedDrawing?.strokes.count, 1)
    }

    func testHasContent_Empty() {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)

        // When
        let hasContent = pageDrawing.hasContent

        // Then
        XCTAssertFalse(hasContent)
    }

    func testHasContent_WithStrokes() throws {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)

        var drawing = PKDrawing()
        let inkingTool = PKInkingTool(.pen, color: .black, width: 5)
        let strokePath = PKStrokePath(
            controlPoints: [
                PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 50, y: 50), timeOffset: 1, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0)
            ],
            creationDate: Date()
        )
        let stroke = PKStroke(ink: inkingTool.ink, path: strokePath)
        drawing.strokes.append(stroke)

        // When
        try pageDrawing.save(drawing: drawing)
        let hasContent = pageDrawing.hasContent

        // Then
        XCTAssertTrue(hasContent)
    }

    func testStrokeCount() throws {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)

        var drawing = PKDrawing()

        // Add multiple strokes
        for i in 0..<3 {
            let inkingTool = PKInkingTool(.pen, color: .black, width: 5)
            let strokePath = PKStrokePath(
                controlPoints: [
                    PKStrokePoint(location: CGPoint(x: i * 10, y: i * 10), timeOffset: 0, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0),
                    PKStrokePoint(location: CGPoint(x: i * 10 + 50, y: i * 10 + 50), timeOffset: 1, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0)
                ],
                creationDate: Date()
            )
            let stroke = PKStroke(ink: inkingTool.ink, path: strokePath)
            drawing.strokes.append(stroke)
        }

        // When
        try pageDrawing.save(drawing: drawing)
        let strokeCount = pageDrawing.strokeCount

        // Then
        XCTAssertEqual(strokeCount, 3)
    }

    func testStrokeCount_Empty() {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)

        // When
        let strokeCount = pageDrawing.strokeCount

        // Then
        XCTAssertEqual(strokeCount, 0)
    }

    // MARK: - External Storage Tests

    func testLargeDrawingData() throws {
        // Given
        let pageDrawing = PageDrawing(pageIndex: 0)
        var drawing = PKDrawing()

        // Add many strokes to create large data
        for i in 0..<100 {
            let inkingTool = PKInkingTool(.pen, color: .black, width: 5)
            let strokePath = PKStrokePath(
                controlPoints: [
                    PKStrokePoint(location: CGPoint(x: i * 5, y: i * 5), timeOffset: 0, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0),
                    PKStrokePoint(location: CGPoint(x: i * 5 + 25, y: i * 5 + 25), timeOffset: 1, size: CGSize(width: 5, height: 5), opacity: 1, force: 1, azimuth: 0, altitude: 0)
                ],
                creationDate: Date()
            )
            let stroke = PKStroke(ink: inkingTool.ink, path: strokePath)
            drawing.strokes.append(stroke)
        }

        // When
        try pageDrawing.save(drawing: drawing)

        modelContext.insert(pageDrawing)
        try modelContext.save()

        // Then
        let fetchDescriptor = FetchDescriptor<PageDrawing>()
        let drawings = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(drawings.count, 1)
        XCTAssertEqual(drawings.first?.strokeCount, 100)
    }

    // MARK: - Character Relationship Tests

    func testPageDrawingCharacterRelationship() throws {
        // Given
        let character = Character(name: "Test")
        let pageDrawing = PageDrawing(pageIndex: 0, character: character)

        // When
        modelContext.insert(character)
        modelContext.insert(pageDrawing)
        try modelContext.save()

        // Then
        XCTAssertEqual(pageDrawing.character?.id, character.id)
        XCTAssertEqual(character.pageDrawings.count, 1)
        XCTAssertEqual(character.pageDrawings.first?.id, pageDrawing.id)
    }
}
