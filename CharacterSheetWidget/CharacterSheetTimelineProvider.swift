//
//  CharacterSheetTimelineProvider.swift
//  CharacterSheetWidget
//
//  Timeline provider for character sheet widget
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents

/// Timeline entry for character sheet widget
struct CharacterSheetEntry: TimelineEntry {
    let date: Date
    let characterID: UUID?
    let characterName: String
    let templateName: String
    let snapshotImage: UIImage?
    let configuration: SelectCharacterIntent
}

/// Timeline provider that fetches character data for the widget
struct CharacterSheetTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = CharacterSheetEntry
    typealias Intent = SelectCharacterIntent
    
    // MARK: - Configuration
    
    /// Widget refresh interval in minutes
    /// Determines how frequently the widget updates to reflect changes made in the main app
    private static let refreshIntervalMinutes = 15

    // MARK: - Placeholder

    func placeholder(in context: Context) -> CharacterSheetEntry {
        CharacterSheetEntry(
            date: Date(),
            characterID: UUID(), // Non-nil placeholder UUID for debugging
            characterName: "Character Name",
            templateName: "D&D 5E",
            snapshotImage: WidgetImageRenderer.generatePlaceholderImage(),
            configuration: SelectCharacterIntent()
        )
    }

    // MARK: - Snapshot

    func snapshot(for configuration: SelectCharacterIntent, in context: Context) async -> CharacterSheetEntry {
        if context.isPreview {
            return placeholder(in: context)
        }

        return await fetchCharacterEntry(for: configuration, in: context)
    }

    // MARK: - Timeline

    func timeline(for configuration: SelectCharacterIntent, in context: Context) async -> Timeline<CharacterSheetEntry> {
        let entry = await fetchCharacterEntry(for: configuration, in: context)

        // Update timeline based on configured refresh interval
        // This allows the widget to refresh if the user modifies the character
        let nextUpdate = Calendar.current.date(
            byAdding: .minute,
            value: Self.refreshIntervalMinutes,
            to: Date()
        ) ?? Date()

        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    // MARK: - Data Fetching

    private func fetchCharacterEntry(
        for configuration: SelectCharacterIntent,
        in context: Context
    ) async -> CharacterSheetEntry {
        // Determine which character to display
        let characterID: UUID?

        if configuration.showLastViewed {
            // Get last viewed character from shared UserDefaults
            characterID = getLastViewedCharacterID()
        } else if let selectedCharacter = configuration.character {
            // Use explicitly selected character
            characterID = selectedCharacter.id
        } else {
            // Fallback to last viewed
            characterID = getLastViewedCharacterID()
        }

        guard let characterID = characterID else {
            // No character available - return placeholder
            return CharacterSheetEntry(
                date: Date(),
                characterID: nil,
                characterName: "No Character",
                templateName: "Select a character",
                snapshotImage: WidgetImageRenderer.generatePlaceholderImage(),
                configuration: configuration
            )
        }

        // Fetch character data from SwiftData
        return await fetchCharacterData(characterID: characterID, configuration: configuration, context: context)
    }

    private func fetchCharacterData(
        characterID: UUID,
        configuration: SelectCharacterIntent,
        context: Context
    ) async -> CharacterSheetEntry {
        // Create or reuse cached model container from AppGroupContainer
        // After the first creation, AppGroupContainer returns the cached instance to reduce overhead
        let expectedSchema = Schema([Template.self, Character.self, PageDrawing.self])
        guard let modelContainer = try? AppGroupContainer.createModelContainer(
            schema: expectedSchema,
            isStoredInMemoryOnly: false
        ) else {
            WidgetLogger.error("Failed to create model container")
            return createErrorEntry(configuration: configuration, characterID: characterID)
        }

        #if DEBUG
        // Validate that the cached container's schema matches the requested schema.
        // This helps catch cases where the schema has changed but the cached container
        // is still using an outdated schema during development.
        let cachedSchemaModels = Set(modelContainer.schema.entities.map { $0.name })
        let expectedSchemaModels = Set(expectedSchema.entities.map { $0.name })
        if cachedSchemaModels != expectedSchemaModels {
            assertionFailure("""
                Schema mismatch detected. Expected: \(expectedSchemaModels), \
                Got: \(cachedSchemaModels). Force-quit app/widget to reload schema.
                """)
        }
        #endif

        let modelContext = ModelContext(modelContainer)

        // Fetch the character
        let descriptor = FetchDescriptor<Character>(
            predicate: #Predicate { character in
                character.id == characterID
            }
        )

        do {
            let characters = try modelContext.fetch(descriptor)

            guard let character = characters.first else {
                WidgetLogger.error("Character not found for ID: \(characterID.uuidString)")
                return createErrorEntry(configuration: configuration, characterID: characterID)
            }

            // Get the template
            guard let template = character.template else {
                WidgetLogger.error("Character has no template")
                return createErrorEntry(configuration: configuration, characterID: characterID)
            }

            // Get the first page drawing (page index 0) using a targeted fetch
            // This is more efficient than loading all pageDrawings into memory
            let pageDrawingDescriptor = FetchDescriptor<PageDrawing>(
                predicate: #Predicate { pageDrawing in
                    pageDrawing.character?.id == characterID && pageDrawing.pageIndex == 0
                }
            )
            let pageDrawing = try modelContext.fetch(pageDrawingDescriptor).first

            // Render the character sheet image
            // Choose render configuration based on widget size
            let renderConfig: WidgetImageRenderer.RenderConfiguration
            switch context.family {
            case .systemLarge:
                renderConfig = .widgetLarge
            case .systemExtraLarge:
                renderConfig = WidgetImageRenderer.RenderConfiguration(
                    targetSize: CGSize(width: 1000, height: 1300),
                    scale: UIScreen.main.scale,
                    compressionQuality: 0.85,
                    cropToContent: false
                )
            default:
                renderConfig = .widgetDefault
            }

            let snapshotImage = WidgetImageRenderer.renderCharacterSheetImage(
                pdfData: template.pdfData,
                pageIndex: 0,
                drawingData: pageDrawing?.drawingData,
                configuration: renderConfig
            )

            return CharacterSheetEntry(
                date: Date(),
                characterID: character.id,
                characterName: character.name,
                templateName: template.name,
                snapshotImage: snapshotImage ?? WidgetImageRenderer.generatePlaceholderImage(),
                configuration: configuration
            )

        } catch {
            WidgetLogger.error("Failed to fetch character", error: error)
            return createErrorEntry(configuration: configuration, characterID: characterID)
        }
    }

    // MARK: - Helper Methods

    private func getLastViewedCharacterID() -> UUID? {
        guard let defaults = UserDefaults(suiteName: AppGroupContainer.identifier),
              let idString = defaults.string(forKey: "lastViewedCharacterID"),
              let id = UUID(uuidString: idString) else {
            return nil
        }
        return id
    }

    private func createErrorEntry(configuration: SelectCharacterIntent, characterID: UUID? = nil) -> CharacterSheetEntry {
        // Include characterID even when loading fails to aid in debugging
        if let characterID = characterID {
            WidgetLogger.error("Failed to load character \(characterID.uuidString)")
        }
        
        return CharacterSheetEntry(
            date: Date(),
            characterID: characterID,  // Preserve characterID for debugging
            characterName: "Error",
            templateName: "Unable to load character",
            snapshotImage: WidgetImageRenderer.generatePlaceholderImage(),
            configuration: configuration
        )
    }
}
