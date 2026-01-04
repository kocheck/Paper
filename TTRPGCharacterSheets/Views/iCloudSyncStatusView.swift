//
//  iCloudSyncStatusView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI

struct iCloudSyncStatusView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var syncManager = iCloudSyncManager.shared
    @StateObject private var preferences = UserPreferences.shared

    // MARK: - State
    @State private var showingConflictOptions = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // Status Section
                statusSection

                // Control Section
                if syncManager.syncStatus != .notConfigured {
                    controlSection
                }

                // Settings Section
                settingsSection

                // Information Section
                infoSection
            }
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await syncManager.checkiCloudStatus()
            }
        }
    }

    // MARK: - Status Section
    private var statusSection: some View {
        Section {
            HStack {
                Image(systemName: syncManager.syncStatus.icon)
                    .foregroundStyle(statusColor)
                    .font(.title2)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(syncManager.syncStatus.description)
                        .font(.headline)

                    if let lastSync = syncManager.lastSyncDate {
                        Text("Last synced: \(lastSync, format: .relative(presentation: .named))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if syncManager.syncStatus == .syncing {
                    ProgressView()
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Status")
        }
    }

    // MARK: - Control Section
    private var controlSection: some View {
        Section {
            if preferences.iCloudSyncEnabled {
                // Sync Now Button
                Button {
                    Task {
                        await syncManager.performSync()
                    }
                } label: {
                    HStack {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        Spacer()
                    }
                }
                .disabled(syncManager.syncStatus == .syncing)

                // Disable Sync
                Button(role: .destructive) {
                    Task {
                        await syncManager.disableSync()
                    }
                } label: {
                    HStack {
                        Label("Disable iCloud Sync", systemImage: "icloud.slash")
                        Spacer()
                    }
                }
            } else {
                // Enable Sync
                Button {
                    Task {
                        await syncManager.enableSync()
                    }
                } label: {
                    HStack {
                        Label("Enable iCloud Sync", systemImage: "icloud")
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        } header: {
            Text("Controls")
        } footer: {
            if !preferences.iCloudSyncEnabled {
                Text("Enable iCloud sync to keep your characters synchronized across all your devices")
            }
        }
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        Section {
            Button {
                showingConflictOptions = true
            } label: {
                HStack {
                    Text("Conflict Resolution")
                    Spacer()
                    Text(syncManager.conflictStrategy.description)
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .imageScale(.small)
                }
            }
        } header: {
            Text("Settings")
        }
        .confirmationDialog("Conflict Resolution Strategy", isPresented: $showingConflictOptions) {
            Button("Newer Wins") {
                syncManager.setConflictStrategy(.newerWins)
            }

            Button("Manual Review") {
                syncManager.setConflictStrategy(.manualReview)
            }

            Button("Local Wins") {
                syncManager.setConflictStrategy(.localWins)
            }

            Button("Remote Wins") {
                syncManager.setConflictStrategy(.remoteWins)
            }

            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Choose how to handle conflicts when the same character is modified on multiple devices")
        }
    }

    // MARK: - Info Section
    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "checkmark.icloud",
                    title: "Automatic Sync",
                    description: "Characters sync automatically when modified"
                )

                Divider()

                InfoRow(
                    icon: "lock.icloud",
                    title: "Private & Secure",
                    description: "All data is encrypted and stored in your private iCloud"
                )

                Divider()

                InfoRow(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Conflict Resolution",
                    description: "Intelligent handling of changes made on multiple devices"
                )
            }
            .padding(.vertical, 4)
        } header: {
            Text("About iCloud Sync")
        } footer: {
            Text("iCloud sync requires an active iCloud account and sufficient storage space")
        }
    }

    // MARK: - Computed Properties
    private var statusColor: Color {
        switch syncManager.syncStatus {
        case .idle:
            return .green
        case .syncing:
            return .blue
        case .disabled, .notConfigured:
            return .gray
        case .error:
            return .red
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Conflict Strategy Extension
extension iCloudSyncManager.ConflictResolutionStrategy {
    var description: String {
        switch self {
        case .newerWins:
            return "Newer Wins"
        case .manualReview:
            return "Manual Review"
        case .localWins:
            return "Local Wins"
        case .remoteWins:
            return "Remote Wins"
        }
    }
}

// MARK: - Preview
#Preview {
    iCloudSyncStatusView()
}
