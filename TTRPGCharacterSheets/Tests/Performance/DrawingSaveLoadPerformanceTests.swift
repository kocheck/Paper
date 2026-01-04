//
//  DrawingSaveLoadPerformanceTests.swift
//  TTRPGCharacterSheetsTests
//
//  Created by Claude on 2026-01-04.
//

import XCTest
import PencilKit
import SwiftData
@testable import TTRPGCharacterSheets

@MainActor
final class DrawingSaveLoadPerformanceTests: XCTestCase {
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

    // MARK: - Drawing Serialization Performance

    func testDrawingSerializationPerformance() throws {
        let drawing = createComplexDrawing(strokeCount: 100)

        measure {
            _ = drawing.dataRepresentation()
        }
    }

    func testDrawingDeserializationPerformance() throws {
        let drawing = createComplexDrawing(strokeCount: 100)
        let data = drawing.dataRepresentation()

        measure {
            _ = try? PKDrawing(data: data)
        }
    }

    // MARK: - SwiftData Persistence Performance

    func testPageDrawingSavePerformance() throws {
        let template = Template(name: "Test Template", pdfData: Data())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        measure {
            // Create fresh drawing data for each iteration
            let pageDrawing = PageDrawing(pageIndex: Int.random(in: 0..<100))
            pageDrawing.drawing = createComplexDrawing(strokeCount: 50)
            pageDrawing.character = character
            modelContext.insert(pageDrawing)

            do {
                try modelContext.save()
            } catch {
                XCTFail("Failed to save: \(error)")
            }

            // Clean up for next iteration
            modelContext.delete(pageDrawing)
        }
    }

    func testPageDrawingLoadPerformance() throws {
        // Setup: Create and save a page drawing
        let template = Template(name: "Test Template", pdfData: Data())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        let pageDrawing = PageDrawing(pageIndex: 0)
        pageDrawing.drawing = createComplexDrawing(strokeCount: 100)
        pageDrawing.character = character
        modelContext.insert(pageDrawing)

        try modelContext.save()

        // Clear context to force reload
        modelContext.reset()

        measure {
            let descriptor = FetchDescriptor<PageDrawing>()
            _ = try? modelContext.fetch(descriptor)
        }
    }

    // MARK: - Large Drawing Performance

    func testLargeDrawingSavePerformance() throws {
        // Simulate detailed character sheet with 500 strokes (maps, detailed notes)
        let largeDrawing = createComplexDrawing(strokeCount: 500)

        let template = Template(name: "Test Template", pdfData: Data())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        let pageDrawing = PageDrawing(pageIndex: 0)
        modelContext.insert(pageDrawing)
        pageDrawing.character = character

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            pageDrawing.drawing = largeDrawing
            do {
                try modelContext.save()
            } catch {
                XCTFail("Failed to save: \(error)")
            }
        }
    }

    // MARK: - Multiple Page Drawings Performance

    func testMultiplePageDrawingsLoadPerformance() throws {
        // Setup: Create character with 4 pages of drawings
        let template = Template(name: "Test Template", pdfData: Data())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        for pageIndex in 0..<4 {
            let pageDrawing = PageDrawing(pageIndex: pageIndex)
            pageDrawing.drawing = createComplexDrawing(strokeCount: 50)
            pageDrawing.character = character
            modelContext.insert(pageDrawing)
        }

        try modelContext.save()
        modelContext.reset()

        measure {
            let descriptor = FetchDescriptor<Character>()
            if let loadedCharacter = try? modelContext.fetch(descriptor).first {
                // Access page drawings to trigger relationship loading
                _ = loadedCharacter.pageDrawings.count
                for drawing in loadedCharacter.pageDrawings {
                    _ = drawing.drawing // Trigger PKDrawing deserialization
                }
            }
        }
    }

    // MARK: - Drawing Modification Performance

    func testDrawingStrokeAdditionPerformance() throws {
        var drawing = createSimpleDrawing()

        measure {
            // Simulate adding strokes during drawing session
            for _ in 0..<10 {
                let newStroke = createStroke()
                drawing.strokes.append(newStroke)
            }
        }
    }

    // MARK: - Memory Usage

    func testDrawingMemoryFootprint() throws {
        let drawings = (0..<10).map { _ in
            createComplexDrawing(strokeCount: 100)
        }

        measure(metrics: [XCTMemoryMetric()]) {
            // Load all drawings into memory
            _ = drawings.map { $0.dataRepresentation() }
        }
    }

    // MARK: - Baseline Metrics

    func testDrawingSaveBaseline() throws {
        // Baseline: Drawing serialization should complete in < 50ms for typical annotation
        let drawing = createComplexDrawing(strokeCount: 50)

        let options = XCTMeasureOptions()
        options.iterationCount = 10

        measure(metrics: [XCTClockMetric()], options: options) {
            _ = drawing.dataRepresentation()
        }

        // Note: In real implementation, use XCTMetric baselines in Xcode
        // Target: < 0.05 seconds per save
    }

    // MARK: - Helper Methods

    private func createSimpleDrawing() -> PKDrawing {
        var drawing = PKDrawing()
        let stroke = createStroke()
        drawing.strokes.append(stroke)
        return drawing
    }

    private func createComplexDrawing(strokeCount: Int) -> PKDrawing {
        var drawing = PKDrawing()

        for i in 0..<strokeCount {
            let stroke = createStroke(at: CGPoint(x: CGFloat(i * 10), y: CGFloat(i * 5)))
            drawing.strokes.append(stroke)
        }

        return drawing
    }

    private func createStroke(at startPoint: CGPoint = CGPoint(x: 100, y: 100)) -> PKStroke {
        var points: [PKStrokePoint] = []

        // Create a curved stroke with 10 points
        for i in 0..<10 {
            let point = PKStrokePoint(
                location: CGPoint(
                    x: startPoint.x + CGFloat(i * 5),
                    y: startPoint.y + sin(Double(i) * 0.5) * 20
                ),
                timeOffset: TimeInterval(i) * 0.01,
                size: CGSize(width: 2, height: 2),
                opacity: 1.0,
                force: 1.0,
                azimuth: 0,
                altitude: 0
            )
            points.append(point)
        }

        let ink = PKInk(.pen, color: .black)
        let path = PKStrokePath(controlPoints: points, creationDate: Date())

        return PKStroke(ink: ink, path: path)
    }
}
