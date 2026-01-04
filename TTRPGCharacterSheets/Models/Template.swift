//
//  Template.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import Foundation
import SwiftData

/// Represents a PDF template for character sheets
/// Templates are the base "blank" PDFs that can be instantiated into multiple characters
@Model
final class Template {
    /// Unique identifier
    var id: UUID

    /// User-friendly name for the template (e.g., "D&D 5e Character Sheet")
    var name: String

    /// Date the template was imported
    var dateImported: Date

    /// PDF file data - stores the original blank PDF
    @Attribute(.externalStorage)
    var pdfData: Data

    /// Number of pages in the PDF
    var pageCount: Int

    /// Thumbnail image data for display in the library (generated from first page)
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    /// All characters created from this template
    @Relationship(deleteRule: .cascade, inverse: \Character.template)
    var characters: [Character]

    /// Initializer
    init(
        id: UUID = UUID(),
        name: String,
        dateImported: Date = Date(),
        pdfData: Data,
        pageCount: Int,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.dateImported = dateImported
        self.pdfData = pdfData
        self.pageCount = pageCount
        self.thumbnailData = thumbnailData
        self.characters = []
    }
}

// MARK: - Computed Properties
extension Template {
    /// Returns the file size of the PDF in a human-readable format
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(pdfData.count), countStyle: .file)
    }

    /// Returns the number of characters created from this template
    var characterCount: Int {
        characters.count
    }
}
