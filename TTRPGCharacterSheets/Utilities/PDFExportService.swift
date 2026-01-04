//
//  PDFExportService.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import Foundation
import PDFKit
import PencilKit
import UIKit

/// Service responsible for exporting PDFs with PencilKit annotations baked in
final class PDFExportService {

    // MARK: - Errors

    enum ExportError: LocalizedError {
        case missingTemplate
        case invalidPDF
        case renderingFailed
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .missingTemplate:
                return "Character template is missing"
            case .invalidPDF:
                return "PDF document is invalid"
            case .renderingFailed:
                return "Failed to render annotations onto PDF"
            case .saveFailed:
                return "Failed to save exported PDF"
            }
        }
    }

    // MARK: - Export Options

    struct ExportOptions {
        /// Include only pages with annotations
        var exportOnlyAnnotatedPages: Bool = false

        /// Compression quality (0.0 - 1.0)
        var compressionQuality: CGFloat = 0.9

        /// File name for export (without extension)
        var fileName: String

        /// Whether to include metadata
        var includeMetadata: Bool = true
    }

    // MARK: - Export Method

    /// Exports a character's PDF with all annotations baked in
    /// - Parameters:
    ///   - character: The character to export
    ///   - options: Export options
    /// - Returns: URL of the exported PDF file
    static func exportCharacter(
        _ character: Character,
        options: ExportOptions
    ) throws -> URL {
        // Validate template and PDF
        guard let template = character.template else {
            throw ExportError.missingTemplate
        }

        guard let sourcePDF = PDFDocument(data: template.pdfData) else {
            throw ExportError.invalidPDF
        }

        // Create new PDF document
        let exportedPDF = PDFDocument()

        // Process each page
        for pageIndex in 0..<sourcePDF.pageCount {
            // Skip pages without annotations if option is set
            if options.exportOnlyAnnotatedPages {
                let hasAnnotations = character.getPageDrawing(for: pageIndex)?.hasContent ?? false
                if !hasAnnotations {
                    continue
                }
            }

            // Get source page
            guard let sourcePage = sourcePDF.page(at: pageIndex) else {
                continue
            }

            // Render page with annotations
            let renderedPage = try renderPage(
                sourcePage,
                withDrawing: character.getPageDrawing(for: pageIndex)
            )

            // Add to exported PDF
            exportedPDF.insert(renderedPage, at: exportedPDF.pageCount)
        }

        // Add metadata if requested
        if options.includeMetadata {
            addMetadata(to: exportedPDF, character: character)
        }

        // Save to temporary location
        let tempURL = try saveToTemporaryFile(
            pdf: exportedPDF,
            fileName: options.fileName
        )

        return tempURL
    }

    // MARK: - Page Rendering

    /// Renders a PDF page with PencilKit drawing overlay
    private static func renderPage(
        _ pdfPage: PDFPage,
        withDrawing pageDrawing: PageDrawing?
    ) throws -> PDFPage {
        let pageRect = pdfPage.bounds(for: .mediaBox)

        // Create graphics context
        let renderer = UIGraphicsImageRenderer(bounds: pageRect)

        let pageImage = renderer.image { context in
            // Fill with white background
            UIColor.white.setFill()
            context.fill(pageRect)

            // Draw PDF page
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: 0, y: pageRect.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)
            pdfPage.draw(with: .mediaBox, to: context.cgContext)
            context.cgContext.restoreGState()

            // Draw PencilKit annotations if available
            if let drawing = pageDrawing?.pkDrawing {
                let drawingImage = drawing.image(from: pageRect, scale: UIScreen.main.scale)
                drawingImage.draw(in: pageRect)
            }
        }

        // Create new PDF page from rendered image
        guard let newPage = PDFPage(image: pageImage) else {
            throw ExportError.renderingFailed
        }

        return newPage
    }

    // MARK: - Metadata

    /// Adds metadata to the exported PDF
    private static func addMetadata(to pdf: PDFDocument, character: Character) {
        var attributes: [PDFDocumentAttribute: Any] = [:]

        attributes[.titleAttribute] = character.name
        attributes[.authorAttribute] = "TTRPG Character Sheets"
        attributes[.creatorAttribute] = "TTRPG Character Sheets App"
        attributes[.producerAttribute] = "PDFKit + PencilKit"
        attributes[.creationDateAttribute] = Date()
        attributes[.modificationDateAttribute] = character.dateModified

        if let notes = character.notes, !notes.isEmpty {
            attributes[.subjectAttribute] = notes
        }

        pdf.documentAttributes = attributes
    }

    // MARK: - File Management

    /// Saves PDF to temporary file
    private static func saveToTemporaryFile(
        pdf: PDFDocument,
        fileName: String
    ) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let safeFileName = fileName.replacingOccurrences(of: "/", with: "-")
        let fileURL = tempDir.appendingPathComponent("\(safeFileName).pdf")

        // Remove existing file if it exists
        try? FileManager.default.removeItem(at: fileURL)

        // Write PDF
        guard pdf.write(to: fileURL) else {
            throw ExportError.saveFailed
        }

        return fileURL
    }

    // MARK: - Convenience Methods

    /// Quick export with default options
    static func quickExport(_ character: Character) throws -> URL {
        let options = ExportOptions(fileName: character.name)
        return try exportCharacter(character, options: options)
    }

    /// Export only annotated pages
    static func exportAnnotatedPages(_ character: Character) throws -> URL {
        let options = ExportOptions(
            exportOnlyAnnotatedPages: true,
            fileName: "\(character.name) - Annotated"
        )
        return try exportCharacter(character, options: options)
    }
}

// MARK: - Export Statistics

extension PDFExportService {
    /// Statistics about an export
    struct ExportStatistics {
        let totalPages: Int
        let annotatedPages: Int
        let fileSize: Int64
        let exportDate: Date

        var formattedFileSize: String {
            ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }
    }

    /// Get statistics for a potential export
    static func getExportStatistics(for character: Character) -> ExportStatistics? {
        guard let template = character.template else { return nil }

        let totalPages = template.pageCount
        let annotatedPages = character.pageDrawings.filter { $0.hasContent }.count

        return ExportStatistics(
            totalPages: totalPages,
            annotatedPages: annotatedPages,
            fileSize: Int64(template.pdfData.count), // Approximate
            exportDate: Date()
        )
    }
}
