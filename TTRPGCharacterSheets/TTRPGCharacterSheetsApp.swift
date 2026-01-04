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

        // Expected format: ttrpgcharactersheets://character/{uuid}
        guard url.scheme == "ttrpgcharactersheets",
              url.host == "character" else {
            print("❌ Invalid deep link scheme or host")
            return
        }

        // Extract character ID from path
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        guard let characterIDString = pathComponents.first,
              let characterID = UUID(uuidString: characterIDString) else {
            print("❌ Invalid character ID in deep link")
            return
        }

        print("✅ Opening character: \(characterID)")

        // Update state restoration manager to open this character
        StateRestorationManager.shared.characterToRestore = characterID
        StateRestorationManager.shared.shouldRestoreState = true
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

    /// Shared UserDefaults for App Group access (widget can read this)
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupContainer.identifier)
    }

    private init() {
        loadRestorationState()
    }

    /// Loads the restoration state from shared UserDefaults
    func loadRestorationState() {
        guard let defaults = sharedDefaults else { return }

        if let characterIDString = defaults.string(forKey: "lastViewedCharacterID"),
           let characterID = UUID(uuidString: characterIDString) {
            self.characterToRestore = characterID
            self.pageIndexToRestore = defaults.integer(forKey: "lastViewedPageIndex")
            self.shouldRestoreState = true
        }
    }

    /// Saves the current state for restoration (accessible by widget)
    func saveState(characterID: UUID, pageIndex: Int) {
        guard let defaults = sharedDefaults else { return }

        defaults.set(characterID.uuidString, forKey: "lastViewedCharacterID")
        defaults.set(pageIndex, forKey: "lastViewedPageIndex")
    }

    /// Clears the restoration state
    func clearState() {
        guard let defaults = sharedDefaults else { return }

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
