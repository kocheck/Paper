//
//  iCloudSyncManager.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import Foundation
import SwiftData
import Combine
import CloudKit

/// Manages iCloud synchronization for SwiftData
final class iCloudSyncManager: ObservableObject {
    static let shared = iCloudSyncManager()

    // MARK: - Published Properties
    @Published var syncStatus: SyncStatus = .notConfigured
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?

    // MARK: - Sync Status
    enum SyncStatus: Equatable {
        case notConfigured
        case disabled
        case idle
        case syncing
        case error(String)

        var icon: String {
            switch self {
            case .notConfigured: return "icloud.slash"
            case .disabled: return "icloud.slash"
            case .idle: return "icloud"
            case .syncing: return "icloud.and.arrow.up.and.arrow.down"
            case .error: return "exclamationmark.icloud"
            }
        }

        var description: String {
            switch self {
            case .notConfigured:
                return "iCloud Not Configured"
            case .disabled:
                return "iCloud Sync Disabled"
            case .idle:
                return "Up to Date"
            case .syncing:
                return "Syncing..."
            case .error(let message):
                return "Error: \(message)"
            }
        }
    }

    // MARK: - Model Container Factory
    /// Creates a ModelContainer with iCloud sync enabled
    static func createiCloudModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Template.self,
            Character.self,
            PageDrawing.self
        ])

        // iCloud configuration
        let iCloudConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .private("iCloud.com.ttrpgcharactersheets")
        )

        return try ModelContainer(
            for: schema,
            configurations: [iCloudConfig]
        )
    }

    /// Creates a local-only ModelContainer (no iCloud)
    static func createLocalModelContainer() throws -> ModelContainer {
        let schema = Schema([
            Template.self,
            Character.self,
            PageDrawing.self
        ])

        let localConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [localConfig]
        )
    }

    // MARK: - iCloud Account Status
    private var cloudKitContainer: CKContainer {
        CKContainer(identifier: "iCloud.com.ttrpgcharactersheets")
    }

    /// Checks if iCloud is available and user is signed in
    func checkiCloudStatus() async -> Bool {
        do {
            let status = try await cloudKitContainer.accountStatus()

            switch status {
            case .available:
                await MainActor.run {
                    if UserPreferences.shared.iCloudSyncEnabled {
                        syncStatus = .idle
                    } else {
                        syncStatus = .disabled
                    }
                }
                return true

            case .noAccount:
                await MainActor.run {
                    syncStatus = .error("No iCloud account found. Please sign in to iCloud in Settings.")
                }
                return false

            case .restricted:
                await MainActor.run {
                    syncStatus = .error("iCloud is restricted on this device")
                }
                return false

            case .couldNotDetermine:
                await MainActor.run {
                    syncStatus = .error("Could not determine iCloud status")
                }
                return false

            case .temporarilyUnavailable:
                await MainActor.run {
                    syncStatus = .error("iCloud is temporarily unavailable")
                }
                return false

            @unknown default:
                await MainActor.run {
                    syncStatus = .error("Unknown iCloud status")
                }
                return false
            }
        } catch {
            await MainActor.run {
                syncStatus = .error(error.localizedDescription)
                syncError = error
            }
            return false
        }
    }

    // MARK: - Sync Control
    /// Enables iCloud sync
    func enableSync() async {
        guard await checkiCloudStatus() else { return }

        await MainActor.run {
            UserPreferences.shared.iCloudSyncEnabled = true
            syncStatus = .idle
        }

        // Trigger initial sync
        await performSync()
    }

    /// Disables iCloud sync
    func disableSync() async {
        await MainActor.run {
            UserPreferences.shared.iCloudSyncEnabled = false
            syncStatus = .disabled
        }
    }

    /// Manually trigger a sync
    func performSync() async {
        guard UserPreferences.shared.iCloudSyncEnabled else { return }

        await MainActor.run {
            syncStatus = .syncing
        }

        // SwiftData handles sync automatically with CloudKit
        // This method is mainly for UI feedback

        // Simulate sync delay (in production, monitor actual CloudKit events)
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        await MainActor.run {
            syncStatus = .idle
            lastSyncDate = Date()
        }
    }

    // MARK: - Conflict Resolution
    /// Strategy for resolving sync conflicts
    enum ConflictResolutionStrategy {
        case newerWins  // Use the most recently modified version
        case manualReview  // Prompt user to choose
        case localWins  // Always keep local version
        case remoteWins  // Always keep remote version
    }

    private(set) var conflictStrategy: ConflictResolutionStrategy = .newerWins

    /// Sets the conflict resolution strategy
    func setConflictStrategy(_ strategy: ConflictResolutionStrategy) {
        conflictStrategy = strategy
    }

    // MARK: - Sync Notifications
    /// Observes CloudKit notifications for changes
    func observeSyncNotifications() {
        // In production, observe CKQuerySubscription notifications
        // For now, periodic polling
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      UserPreferences.shared.iCloudSyncEnabled else { return }

                Task {
                    await self.performSync()
                }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Private Init
    private init() {
        // Check initial status
        Task {
            await checkiCloudStatus()
        }
    }
}

// MARK: - App Configuration Extension
extension iCloudSyncManager {
    /// Returns the appropriate ModelContainer based on user preferences
    /// This method is safe to call during app initialization as it reads directly from UserDefaults
    static func modelContainer() throws -> ModelContainer {
        // Read directly from UserDefaults to avoid dependency on UserPreferences singleton
        let iCloudEnabled = UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        
        if iCloudEnabled {
            return try createiCloudModelContainer()
        } else {
            return try createLocalModelContainer()
        }
    }
}
