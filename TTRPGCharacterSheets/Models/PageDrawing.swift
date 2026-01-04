//
//  PageDrawing.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import Foundation
import SwiftData
import PencilKit

/// Represents the PencilKit drawing data for a specific page of a character
/// Each Character can have multiple PageDrawings (one per PDF page)
@Model
final class PageDrawing {
    /// Unique identifier
    var id: UUID

    /// The page index this drawing corresponds to (0-based)
    var pageIndex: Int

    /// The serialized PKDrawing data
    /// Stored as external storage for better performance with large drawings
    @Attribute(.externalStorage)
    var drawingData: Data

    /// Reference to the character this drawing belongs to
    var character: Character?

    /// Date this drawing was last modified
    var dateModified: Date

    /// Initializer
    init(
        id: UUID = UUID(),
        pageIndex: Int,
        drawingData: Data = Data(),
        character: Character? = nil,
        dateModified: Date = Date()
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.drawingData = drawingData
        self.character = character
        self.dateModified = dateModified
    }

    /// Updates the modification date to now
    func updateModificationDate() {
        self.dateModified = Date()
    }
}

// MARK: - PencilKit Integration
extension PageDrawing {
    /// Converts the stored Data to a PKDrawing object
    /// Returns nil if the data is invalid or empty
    var pkDrawing: PKDrawing? {
        get {
            guard !drawingData.isEmpty else {
                return PKDrawing()
            }

            return try? PKDrawing(data: drawingData)
        }
    }

    /// Saves a PKDrawing to the drawingData property
    func save(drawing: PKDrawing) throws {
        self.drawingData = drawing.dataRepresentation()
        updateModificationDate()
    }

    /// Checks if this page has any drawing content
    var hasContent: Bool {
        guard let drawing = pkDrawing else { return false }
        return !drawing.strokes.isEmpty
    }

    /// Returns the number of strokes in the drawing
    var strokeCount: Int {
        pkDrawing?.strokes.count ?? 0
    }
}
