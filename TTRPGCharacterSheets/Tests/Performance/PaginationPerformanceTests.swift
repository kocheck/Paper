//
//  PaginationPerformanceTests.swift
//  TTRPGCharacterSheetsTests
//
//  Created by Claude on 2026-01-04.
//

import XCTest
import SwiftUI
import PDFKit
import SwiftData
@testable import TTRPGCharacterSheets

@MainActor
final class PaginationPerformanceTests: XCTestCase {
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

    // MARK: - Page Navigation Performance

    func testPageIndexUpdatePerformance() throws {
        let template = Template(name: "Test Template", pdfData: createMultiPagePDF())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        measure {
            // Simulate rapid page flipping
            for pageIndex in 0..<4 {
                character.lastViewedPageIndex = pageIndex
            }
            try? modelContext.save()
        }
    }

    func testLazyPageDrawingCreationPerformance() throws {
        let template = Template(name: "Test Template", pdfData: createMultiPagePDF())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        measure {
            // Simulate user navigating through all pages
            for pageIndex in 0..<4 {
                // Check if page drawing exists
                if character.pageDrawings.first(where: { $0.pageIndex == pageIndex }) == nil {
                    let pageDrawing = PageDrawing(pageIndex: pageIndex)
                    pageDrawing.character = character
                    modelContext.insert(pageDrawing)
                }
            }
            try? modelContext.save()
        }
    }

    // MARK: - State Restoration Performance

    func testStateRestorationLoadPerformance() throws {
        // Setup: Create character with last viewed page
        let template = Template(name: "Test Template", pdfData: createMultiPagePDF())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        character.lastViewedPageIndex = 2
        modelContext.insert(character)

        for pageIndex in 0..<4 {
            let pageDrawing = PageDrawing(pageIndex: pageIndex)
            pageDrawing.character = character
            modelContext.insert(pageDrawing)
        }

        try modelContext.save()

        // Store character ID
        let characterID = character.id

        // Clear context
        modelContext.reset()

        measure {
            // Simulate app launch and state restoration
            let descriptor = FetchDescriptor<Character>(
                predicate: #Predicate { $0.id == characterID }
            )

            if let restoredCharacter = try? modelContext.fetch(descriptor).first {
                let lastPage = restoredCharacter.lastViewedPageIndex
                _ = restoredCharacter.pageDrawings.first(where: { $0.pageIndex == lastPage })
            }
        }
    }

    // MARK: - Page Transition Animation Performance

    func testPageTransitionPreparationPerformance() throws {
        let pdfDocument = PDFDocument(data: createMultiPagePDF())!

        measure {
            // Simulate preparing next page for transition
            for pageIndex in 0..<(pdfDocument.pageCount - 1) {
                guard let currentPage = pdfDocument.page(at: pageIndex),
                      let nextPage = pdfDocument.page(at: pageIndex + 1) else {
                    continue
                }

                // Get page bounds (needed for transition)
                _ = currentPage.boundsForBox(.mediaBox)
                _ = nextPage.boundsForBox(.mediaBox)

                // Pre-render thumbnails
                _ = currentPage.thumbnail(of: CGSize(width: 100, height: 100), for: .mediaBox)
                _ = nextPage.thumbnail(of: CGSize(width: 100, height: 100), for: .mediaBox)
            }
        }
    }

    // MARK: - Memory Management

    func testPageUnloadingMemoryPerformance() throws {
        let template = Template(name: "Test Template", pdfData: createMultiPagePDF())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        // Create drawings for all pages
        for pageIndex in 0..<4 {
            let pageDrawing = PageDrawing(pageIndex: pageIndex)
            pageDrawing.drawing = createComplexDrawing(strokeCount: 100)
            pageDrawing.character = character
            modelContext.insert(pageDrawing)
        }

        try modelContext.save()

        measure(metrics: [XCTMemoryMetric()]) {
            // Simulate loading only current page
            for currentPage in 0..<4 {
                // Load current page drawing
                if let currentDrawing = character.pageDrawings.first(where: { $0.pageIndex == currentPage }) {
                    _ = currentDrawing.drawing
                }

                // Note: In real app, would unload other pages here
                // SwiftData handles automatic faulting
            }
        }
    }

    // MARK: - Baseline Metrics

    func testPageNavigationBaseline() throws {
        // Baseline: Page navigation state updates should complete quickly
        let template = Template(name: "Test Template", pdfData: createMultiPagePDF())
        modelContext.insert(template)

        let character = Character(name: "Test Character", template: template)
        modelContext.insert(character)

        let options = XCTMeasureOptions()
        options.iterationCount = 60

        measure(metrics: [XCTClockMetric()], options: options) {
            character.lastViewedPageIndex = (character.lastViewedPageIndex + 1) % 4
        }

        // Note: Measures model property update performance, not UI rendering
    }

    // MARK: - Helper Methods

    private func createMultiPagePDF() -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            for pageNum in 1...4 {
                context.beginPage()
                let text = "Character Sheet - Page \(pageNum)"
                text.draw(at: CGPoint(x: 50, y: 50), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24)
                ])

                // Add some content to make it more realistic
                for y in stride(from: 100, to: 700, by: 30) {
                    "Stat Block Entry \(y)".draw(at: CGPoint(x: 50, y: CGFloat(y)), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 12)
                    ])
                }
            }
        }

        return data
    }

    private func createComplexDrawing(strokeCount: Int) -> PKDrawing {
        var drawing = PKDrawing()

        for i in 0..<strokeCount {
            let stroke = createStroke(at: CGPoint(x: CGFloat(i * 10), y: CGFloat(i * 5)))
            drawing.strokes.append(stroke)
        }

        return drawing
    }

    private func createStroke(at startPoint: CGPoint) -> PKStroke {
        var points: [PKStrokePoint] = []

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
