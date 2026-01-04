//
//  CharacterEditorViewModel.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import Foundation
import SwiftUI
import SwiftData
import PDFKit
import PencilKit

/// ViewModel for CharacterEditorView, managing PDF loading, page navigation, and drawing state
@MainActor
@Observable
final class CharacterEditorViewModel {
    // MARK: - Published State

    var currentPageIndex: Int {
        didSet {
            handlePageIndexChange(oldValue: oldValue, newValue: currentPageIndex)
        }
    }

    var pdfDocument: PDFDocument?
    var hasUnsavedChanges = false
    var showingToolPicker = false
    var showingExportView = false
    var isLoading = true

    // MARK: - Undo/Redo State

    var canUndo = false
    var canRedo = false
    private(set) var currentUndoManager: UndoManager?

    // MARK: - Dependencies

    private let character: Character
    private let modelContext: ModelContext
    private let stateRestoration: StateRestorationManager
    private let preferences: UserPreferences

    // MARK: - Initialization

    init(
        character: Character,
        modelContext: ModelContext,
        stateRestoration: StateRestorationManager = .shared,
        preferences: UserPreferences = .shared
    ) {
        self.character = character
        self.modelContext = modelContext
        self.stateRestoration = stateRestoration
        self.preferences = preferences
        self.currentPageIndex = character.lastViewedPageIndex
    }

    // MARK: - Public Methods

    /// Load PDF document from character's template
    func loadPDF() {
        guard let template = character.template else {
            isLoading = false
            return
        }

        pdfDocument = PDFDocument(data: template.pdfData)
        isLoading = false

        // Save initial state
        stateRestoration.saveState(characterID: character.id, pageIndex: currentPageIndex)
    }

    /// Navigate to a specific page
    /// - Parameter pageIndex: The target page index
    /// - Returns: True if navigation was successful, false if index is invalid
    @discardableResult
    func navigateToPage(_ pageIndex: Int) -> Bool {
        guard pageIndex >= 0 && pageIndex < character.pageCount else {
            return false
        }

        currentPageIndex = pageIndex
        return true
    }

    /// Navigate to next page
    /// - Returns: True if navigation was successful, false if already on last page
    @discardableResult
    func navigateToNextPage() -> Bool {
        navigateToPage(currentPageIndex + 1)
    }

    /// Navigate to previous page
    /// - Returns: True if navigation was successful, false if already on first page
    @discardableResult
    func navigateToPreviousPage() -> Bool {
        navigateToPage(currentPageIndex - 1)
    }

    /// Check if can navigate to previous page
    var canNavigatePrevious: Bool {
        currentPageIndex > 0
    }

    /// Check if can navigate to next page
    var canNavigateNext: Bool {
        currentPageIndex < character.pageCount - 1
    }

    /// Get page number label for display (1-indexed)
    var pageNumberLabel: String {
        "Page \(currentPageIndex + 1) of \(character.pageCount)"
    }

    /// Show the tool picker sheet
    func showToolPicker() {
        showingToolPicker = true
    }

    /// Hide the tool picker sheet
    func hideToolPicker() {
        showingToolPicker = false
    }

    /// Show the export view sheet
    func showExportView() {
        showingExportView = true
    }

    /// Hide the export view sheet
    func hideExportView() {
        showingExportView = false
    }

    /// Mark that drawing has changed
    func markDrawingChanged() {
        hasUnsavedChanges = true
    }

    /// Clear unsaved changes flag (called after successful save)
    func clearUnsavedChanges() {
        hasUnsavedChanges = false
    }

    /// Save character and dismiss editor
    /// - Parameter onDismiss: Closure to call after saving
    func saveAndDismiss(onDismiss: @escaping () -> Void) {
        // Update modification date
        character.updateModificationDate()

        // Save context
        do {
            try modelContext.save()
            hasUnsavedChanges = false
            onDismiss()
        } catch {
            print("❌ Failed to save character: \(error)")
            // In production, would show error alert
        }
    }

    /// Get page transition style preference
    var pageTransitionStyle: UserPreferences.PageTransitionStyle {
        preferences.pageTransitionStyle
    }

    // MARK: - Undo/Redo Methods

    /// Register an undo manager (typically from PKCanvasView)
    /// - Parameter undoManager: The undo manager to register
    func registerUndoManager(_ undoManager: UndoManager?) {
        currentUndoManager = undoManager
        updateUndoRedoState()

        // Observe undo manager changes
        if let undoManager = undoManager {
            NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidUndoChange,
                object: undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.updateUndoRedoState()
            }

            NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidRedoChange,
                object: undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.updateUndoRedoState()
            }

            NotificationCenter.default.addObserver(
                forName: .NSUndoManagerDidCloseUndoGroup,
                object: undoManager,
                queue: .main
            ) { [weak self] _ in
                self?.updateUndoRedoState()
            }
        }
    }

    /// Perform undo
    func undo() {
        currentUndoManager?.undo()
        updateUndoRedoState()
        markDrawingChanged()
    }

    /// Perform redo
    func redo() {
        currentUndoManager?.redo()
        updateUndoRedoState()
        markDrawingChanged()
    }

    /// Update undo/redo button states
    private func updateUndoRedoState() {
        canUndo = currentUndoManager?.canUndo ?? false
        canRedo = currentUndoManager?.canRedo ?? false
    }

    // MARK: - Private Methods

    private func handlePageIndexChange(oldValue: Int, newValue: Int) {
        // Update character's last viewed page
        character.lastViewedPageIndex = newValue

        // Save state for restoration
        stateRestoration.saveState(characterID: character.id, pageIndex: newValue)

        // Could add analytics here
        #if DEBUG
        print("📄 Navigated from page \(oldValue + 1) to \(newValue + 1)")
        #endif
    }
}

// MARK: - Environment Key

struct CharacterEditorViewModelKey: EnvironmentKey {
    static let defaultValue: CharacterEditorViewModel? = nil
}

extension EnvironmentValues {
    var characterEditorViewModel: CharacterEditorViewModel? {
        get { self[CharacterEditorViewModelKey.self] }
        set { self[CharacterEditorViewModelKey.self] = newValue }
    }
}

// MARK: - Preview Support

#if DEBUG
extension CharacterEditorViewModel {
    /// Create a mock view model for previews
    static func mock(
        character: Character,
        modelContext: ModelContext
    ) -> CharacterEditorViewModel {
        CharacterEditorViewModel(
            character: character,
            modelContext: modelContext
        )
    }
}
#endif
