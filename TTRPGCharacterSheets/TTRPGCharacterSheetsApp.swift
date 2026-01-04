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

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
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
        }
    }
}

// MARK: - State Restoration Manager
/// Manages app state restoration for seamless user experience
class StateRestorationManager: ObservableObject {
    static let shared = StateRestorationManager()

    @Published var shouldRestoreState: Bool = false
    @Published var characterToRestore: UUID?
    @Published var pageIndexToRestore: Int = 0

    private init() {
        loadRestorationState()
    }

    /// Loads the restoration state from UserDefaults
    func loadRestorationState() {
        if let characterIDString = UserDefaults.standard.string(forKey: "lastViewedCharacterID"),
           let characterID = UUID(uuidString: characterIDString) {
            self.characterToRestore = characterID
            self.pageIndexToRestore = UserDefaults.standard.integer(forKey: "lastViewedPageIndex")
            self.shouldRestoreState = true
        }
    }

    /// Saves the current state for restoration
    func saveState(characterID: UUID, pageIndex: Int) {
        UserDefaults.standard.set(characterID.uuidString, forKey: "lastViewedCharacterID")
        UserDefaults.standard.set(pageIndex, forKey: "lastViewedPageIndex")
    }

    /// Clears the restoration state
    func clearState() {
        UserDefaults.standard.removeObject(forKey: "lastViewedCharacterID")
        UserDefaults.standard.removeObject(forKey: "lastViewedPageIndex")
        self.characterToRestore = nil
        self.pageIndexToRestore = 0
        self.shouldRestoreState = false
    }

    /// Marks that restoration has been completed
    func completeRestoration() {
        self.shouldRestoreState = false
    }
}
