//
//  Character.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import Foundation
import SwiftData

/// Represents a specific character instance based on a Template
/// Characters contain the user's PencilKit drawings and modifications
@Model
final class Character {
    /// Unique identifier
    var id: UUID

    /// Character name (e.g., "Gandalf the Grey", "Aragorn")
    var name: String

    /// Date the character was created
    var dateCreated: Date

    /// Date the character was last modified
    var dateModified: Date

    /// Reference to the template this character is based on
    var template: Template?

    /// All drawing data for each page of this character
    @Relationship(deleteRule: .cascade, inverse: \PageDrawing.character)
    var pageDrawings: [PageDrawing]

    /// Additional notes or metadata (optional)
    var notes: String?

    /// Favorite/starred status for quick access
    var isFavorite: Bool

    /// Last viewed page index (for state restoration)
    var lastViewedPageIndex: Int

    /// Initializer
    init(
        id: UUID = UUID(),
        name: String,
        dateCreated: Date = Date(),
        dateModified: Date = Date(),
        template: Template? = nil,
        notes: String? = nil,
        isFavorite: Bool = false,
        lastViewedPageIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.template = template
        self.pageDrawings = []
        self.notes = notes
        self.isFavorite = isFavorite
        self.lastViewedPageIndex = lastViewedPageIndex
    }

    /// Updates the modification date to now
    func updateModificationDate() {
        self.dateModified = Date()
    }

    /// Gets or creates a PageDrawing for a specific page index
    func getPageDrawing(for pageIndex: Int) -> PageDrawing? {
        pageDrawings.first { $0.pageIndex == pageIndex }
    }

    /// Creates a new PageDrawing for a specific page if it doesn't exist
    func createPageDrawingIfNeeded(for pageIndex: Int) -> PageDrawing {
        if let existing = getPageDrawing(for: pageIndex) {
            return existing
        }

        let newDrawing = PageDrawing(pageIndex: pageIndex, character: self)
        pageDrawings.append(newDrawing)
        return newDrawing
    }
}

// MARK: - Computed Properties
extension Character {
    /// Returns the template name if available
    var templateName: String {
        template?.name ?? "Unknown Template"
    }

    /// Returns the number of pages (based on template)
    var pageCount: Int {
        template?.pageCount ?? 0
    }

    /// Returns formatted creation date
    var formattedCreationDate: String {
        dateCreated.formatted(date: .abbreviated, time: .omitted)
    }

    /// Returns formatted modification date
    var formattedModificationDate: String {
        dateModified.formatted(date: .abbreviated, time: .shortened)
    }
}
