//
//  CharacterSelectionIntent.swift
//  CharacterSheetWidget
//
//  App Intent for configurable character selection in widgets
//

import AppIntents
import SwiftData
import Foundation

/// App Intent that allows users to select which character to display in the widget
struct SelectCharacterIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Character"
    static var description = IntentDescription("Choose which character to display in the widget")

    /// Selected character (optional - if nil, shows last viewed)
    @Parameter(title: "Character", optionsProvider: CharacterOptionsProvider())
    var character: CharacterEntity?

    /// Indicates whether to show the last viewed character
    @Parameter(title: "Show Last Viewed", default: true)
    var showLastViewed: Bool
}

/// Entity representing a character for App Intents
struct CharacterEntity: AppEntity {
    var id: UUID
    var displayString: String

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Character")

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayString)")
    }

    static var defaultQuery = CharacterEntityQuery()
}

/// Query provider for character entities
struct CharacterEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [CharacterEntity] {
        guard let modelContainer = try? AppGroupContainer.createModelContainer(
            schema: Schema([Template.self, Character.self, PageDrawing.self]),
            isStoredInMemoryOnly: false
        ) else {
            return []
        }

        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Character>(
            predicate: #Predicate { character in
                identifiers.contains(character.id)
            }
        )

        do {
            let characters = try context.fetch(descriptor)
            return characters.map { character in
                CharacterEntity(
                    id: character.id,
                    displayString: "\(character.name) (\(character.template?.name ?? "Unknown"))"
                )
            }
        } catch {
            print("Failed to fetch characters: \(error)")
            return []
        }
    }

    func suggestedEntities() async throws -> [CharacterEntity] {
        guard let modelContainer = try? AppGroupContainer.createModelContainer(
            schema: Schema([Template.self, Character.self, PageDrawing.self]),
            isStoredInMemoryOnly: false
        ) else {
            return []
        }

        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<Character>(
            sortBy: [SortDescriptor(\Character.dateModified, order: .reverse)]
        )
        descriptor.fetchLimit = 10  // Limit to recent characters

        do {
            let characters = try context.fetch(descriptor)
            return characters.map { character in
                CharacterEntity(
                    id: character.id,
                    displayString: "\(character.name) (\(character.template?.name ?? "Unknown"))"
                )
            }
        } catch {
            print("Failed to fetch characters: \(error)")
            return []
        }
    }
}

/// Options provider for character selection
struct CharacterOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [CharacterEntity] {
        try await CharacterEntityQuery().suggestedEntities()
    }

    func defaultResult() async -> CharacterEntity? {
        // Try to get the last viewed character from shared UserDefaults
        guard let defaults = UserDefaults(suiteName: AppGroupContainer.identifier),
              let lastViewedIDString = defaults.string(forKey: "lastViewedCharacterID"),
              let lastViewedID = UUID(uuidString: lastViewedIDString) else {
            return nil
        }

        // Fetch the character
        guard let modelContainer = try? AppGroupContainer.createModelContainer(
            schema: Schema([Template.self, Character.self, PageDrawing.self]),
            isStoredInMemoryOnly: false
        ) else {
            return nil
        }

        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Character>(
            predicate: #Predicate { character in
                character.id == lastViewedID
            }
        )

        do {
            if let character = try context.fetch(descriptor).first {
                return CharacterEntity(
                    id: character.id,
                    displayString: "\(character.name) (\(character.template?.name ?? "Unknown"))"
                )
            }
        } catch {
            print("Failed to fetch default character: \(error)")
        }

        return nil
    }
}
