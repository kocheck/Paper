//
//  TTRPGCharacterSheetsApp.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI
import SwiftData

@main
struct TTRPGCharacterSheetsApp: App {
    // MARK: - State Restoration
    @AppStorage("lastViewedCharacterID") private var lastViewedCharacterID: String?

    // MARK: - SwiftData Model Container
    var modelContainer: ModelContainer = {
        let schema = Schema([
            Template.self,
            Character.self,
            PageDrawing.self
        ])

        do {
            // Use App Group container for sharing with Widget Extension
            return try AppGroupContainer.createModelContainer(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }()

    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            MainLibraryView()
                .modelContainer(modelContainer)
                .environmentObject(StateRestorationManager.shared)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    // MARK: - Deep Linking

    /// Handles deep link URLs from widgets and other sources
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url)")

        // Expected formats:
        // - ttrpgcharactersheets://character/{uuid} (host-based)
        // - ttrpgcharactersheets:///character/{uuid} (path-based)
        guard url.scheme == "ttrpgcharactersheets" else {
            print("❌ Invalid deep link scheme: \(url.scheme ?? "nil")")
            return
        }

        // Extract character ID from URL components
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }

        // Determine where "character" appears (host vs first path component)
        let characterIDString: String?
        if url.host == "character" {
            // Format: ttrpgcharactersheets://character/{uuid}
            guard pathComponents.count == 1 else {
                print("❌ Invalid path structure for deep link with host 'character': \(pathComponents)")
                return
            }
            characterIDString = pathComponents.first
        } else if pathComponents.first == "character" {
            // Format: ttrpgcharactersheets:///character/{uuid}
            guard pathComponents.count == 2 else {
                print("❌ Invalid path structure for deep link with 'character' in path: \(pathComponents)")
                return
            }
            characterIDString = pathComponents.last
        } else {
            print("❌ Invalid deep link host or path; expected 'character' segment")
            return
        }

        guard let characterIDString,
              let characterID = UUID(uuidString: characterIDString) else {
            print("❌ Invalid character ID format in deep link: \(characterIDString ?? "nil")")
            return
        }

        print("✅ Opening character: \(characterID)")

        // Validate that the character exists before setting it for restoration
        // Dispatch to main thread since StateRestorationManager has @Published properties
        Task { @MainActor in
            if Task.isCancelled {
                print("⚠️ State restoration task was cancelled before updating for character: \(characterID)")
                return
            }
            
            // Check if character exists in the database
            let descriptor = FetchDescriptor<Character>(
                predicate: #Predicate { character in
                    character.id == characterID
                }
            )
            
            do {
                let context = ModelContext(modelContainer)
                let characters = try context.fetch(descriptor)
                
                if !characters.isEmpty {
                    // Character exists - proceed with restoration
                    StateRestorationManager.shared.characterToRestore = characterID
                    StateRestorationManager.shared.shouldRestoreState = true
                    print("✅ Character found, state restoration enabled")
                    
                    // Verify that the state was updated as expected for debugging/monitoring
                    if StateRestorationManager.shared.characterToRestore != characterID {
                        print("⚠️ StateRestorationManager failed to update characterToRestore to \(characterID)")
                    }
                } else {
                    print("⚠️ Character \(characterID) not found in database, skipping restoration")
                }
            } catch {
                print("❌ Failed to validate character existence: \(error)")
            }
        }
    }
}

// MARK: - State Restoration Manager
/// Manages app state restoration for seamless user experience
/// Uses App Group shared UserDefaults for widget access
class StateRestorationManager: ObservableObject {
    static let shared = StateRestorationManager()

    @Published var shouldRestoreState: Bool = false
    @Published var characterToRestore: UUID?
    @Published var pageIndexToRestore: Int = 0

    /// Shared UserDefaults for App Group access
    /// Main app writes state that the widget extension reads
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupContainer.identifier)
    }

    private init() {
        loadRestorationState()
    }

    /// Loads the restoration state from shared UserDefaults
    func loadRestorationState() {
        guard let defaults = sharedDefaults else {
            print("⚠️ StateRestorationManager: sharedDefaults is nil - App Groups may not be configured properly")
            return
        }

        if let characterIDString = defaults.string(forKey: "lastViewedCharacterID"),
           let characterID = UUID(uuidString: characterIDString) {
            self.characterToRestore = characterID
            self.pageIndexToRestore = defaults.integer(forKey: "lastViewedPageIndex")
            self.shouldRestoreState = true
        }
    }

    /// Saves the current state for restoration (accessible by widget)
    func saveState(characterID: UUID, pageIndex: Int) {
        guard let defaults = sharedDefaults else {
            print("⚠️ StateRestorationManager.saveState: sharedDefaults is nil - App Groups may not be configured properly")
            return
        }

        defaults.set(characterID.uuidString, forKey: "lastViewedCharacterID")
        defaults.set(pageIndex, forKey: "lastViewedPageIndex")
    }

    /// Clears the restoration state
    func clearState() {
        guard let defaults = sharedDefaults else {
            print("⚠️ StateRestorationManager.clearState: sharedDefaults is nil - App Groups may not be configured properly")
            return
        }

        defaults.removeObject(forKey: "lastViewedCharacterID")
        defaults.removeObject(forKey: "lastViewedPageIndex")
        self.characterToRestore = nil
        self.pageIndexToRestore = 0
        self.shouldRestoreState = false
    }

    /// Marks that restoration has been completed
    func completeRestoration() {
        self.shouldRestoreState = false
    }
}
