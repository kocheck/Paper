//
//  PDFRenderingPerformanceTests.swift
//  TTRPGCharacterSheetsTests
//
//  Created by Claude on 2026-01-04.
//

import XCTest
import PDFKit
import SwiftData
@testable import TTRPGCharacterSheets

@MainActor
final class PDFRenderingPerformanceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var samplePDFData: Data!

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

        // Create sample PDF data for testing
        samplePDFData = createSamplePDF()
    }

    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        samplePDFData = nil
        try await super.tearDown()
    }

    // MARK: - PDF Loading Performance

    func testPDFDocumentCreationPerformance() throws {
        measure {
            _ = PDFDocument(data: samplePDFData)
        }
    }

    func testPDFThumbnailGenerationPerformance() throws {
        let pdfDocument = PDFDocument(data: samplePDFData)!

        measure {
            for pageIndex in 0..<min(pdfDocument.pageCount, 4) {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                _ = page.thumbnail(of: CGSize(width: 200, height: 200), for: .mediaBox)
            }
        }
    }

    func testPDFPageRenderingPerformance() throws {
        let pdfDocument = PDFDocument(data: samplePDFData)!
        guard let firstPage = pdfDocument.page(at: 0) else {
            XCTFail("PDF has no pages")
            return
        }

        let options = XCTMeasureOptions()
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()], options: options) {
            // Simulate rendering at iPad resolution
            let bounds = CGRect(x: 0, y: 0, width: 1024, height: 1366)
            UIGraphicsBeginImageContextWithOptions(bounds.size, false, 2.0)
            defer { UIGraphicsEndImageContext() }

            guard let context = UIGraphicsGetCurrentContext() else { return }
            context.saveGState()
            context.translateBy(x: 0, y: bounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
            firstPage.draw(with: .mediaBox, to: context)
            context.restoreGState()
        }
    }

    // MARK: - Multi-Page Performance

    func testMultiPagePDFNavigationPerformance() throws {
        let pdfDocument = PDFDocument(data: createMultiPagePDF())!

        measure {
            // Simulate rapid page flipping
            for pageIndex in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                _ = page.boundsForBox(.mediaBox)
            }
        }
    }

    // MARK: - Baseline Metrics

    func testPDFLoadingBaseline() throws {
        // Baseline: PDF loading should complete in < 100ms for typical 2-page character sheet
        measure(metrics: [XCTClockMetric()]) {
            _ = PDFDocument(data: samplePDFData)
        }

        // Note: Baseline thresholds can be configured in Xcode's test plan
        // Target: < 0.1 seconds for 2-page character sheet
    }

    // MARK: - Helper Methods

    private func createSamplePDF() -> Data {
        // Create a simple 2-page PDF for testing
        let pdfMetaData = [
            kCGPDFContextCreator: "TTRPG Character Sheets Test Suite",
            kCGPDFContextAuthor: "Test"
        ]

        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            // Page 1
            context.beginPage()
            let text = "Character Sheet - Page 1"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24)
            ]
            text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)

            // Add grid to simulate character sheet
            let gridSize: CGFloat = 20
            context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            for x in stride(from: 0, to: pageRect.width, by: gridSize) {
                context.cgContext.move(to: CGPoint(x: x, y: 0))
                context.cgContext.addLine(to: CGPoint(x: x, y: pageRect.height))
            }
            for y in stride(from: 0, to: pageRect.height, by: gridSize) {
                context.cgContext.move(to: CGPoint(x: 0, y: y))
                context.cgContext.addLine(to: CGPoint(x: pageRect.width, y: y))
            }
            context.cgContext.strokePath()

            // Page 2
            context.beginPage()
            let text2 = "Character Sheet - Page 2"
            text2.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
        }

        return data
    }

    private func createMultiPagePDF() -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)

        let data = renderer.pdfData { context in
            for pageNum in 1...4 {
                context.beginPage()
                let text = "Page \(pageNum)"
                text.draw(at: CGPoint(x: 50, y: 50), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 24)
                ])
            }
        }

        return data
    }
}
