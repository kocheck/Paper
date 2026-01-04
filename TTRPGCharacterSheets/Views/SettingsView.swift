//
//  SettingsView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI

struct SettingsView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var preferences = UserPreferences.shared
    @StateObject private var syncManager = iCloudSyncManager.shared

    // MARK: - State
    @State private var showingSyncStatus = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // Page Transition Section
                pageTransitionSection

                // Drawing Preferences
                drawingSection

                // Export Preferences
                exportSection

                // Library Preferences
                librarySection

                // iCloud Sync (Coming Soon)
                iCloudSection

                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Page Transition Section
    private var pageTransitionSection: some View {
        Section {
            Picker("Transition Style", selection: $preferences.pageTransitionStyle) {
                ForEach(UserPreferences.PageTransitionStyle.allCases) { style in
                    Label(style.rawValue, systemImage: style.icon)
                        .tag(style)
                }
            }
            .pickerStyle(.inline)

            Text(preferences.pageTransitionStyle.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Page Transition")
        } footer: {
            Text("Page curl provides a more realistic book-turning experience")
        }
    }

    // MARK: - Drawing Section
    private var drawingSection: some View {
        Section {
            Toggle("Allow Finger Drawing", isOn: $preferences.allowFingerDrawing)

            HStack {
                Text("Auto-Save Interval")
                Spacer()
                Text("\(Int(preferences.autoSaveInterval))s")
                    .foregroundStyle(.secondary)
            }

            Slider(value: $preferences.autoSaveInterval, in: 1...10, step: 1)
        } header: {
            Text("Drawing")
        } footer: {
            Text("Auto-save interval determines how often your drawings are saved while you work")
        }
    }

    // MARK: - Export Section
    private var exportSection: some View {
        Section {
            Toggle("Include Metadata", isOn: $preferences.exportIncludeMetadata)

            Toggle("Export Only Annotated Pages", isOn: $preferences.exportOnlyAnnotated)
        } header: {
            Text("Export Defaults")
        } footer: {
            Text("These settings will be used as defaults when exporting PDFs")
        }
    }

    // MARK: - Library Section
    private var librarySection: some View {
        Section {
            Picker("View Style", selection: $preferences.libraryViewStyle) {
                ForEach(UserPreferences.LibraryViewStyle.allCases) { style in
                    Label(style.rawValue, systemImage: style.icon)
                        .tag(style)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Library")
        }
    }

    // MARK: - iCloud Section
    private var iCloudSection: some View {
        Section {
            NavigationLink {
                iCloudSyncStatusView()
            } label: {
                HStack {
                    Label("iCloud Sync", systemImage: syncManager.syncStatus.icon)

                    Spacer()

                    if preferences.iCloudSyncEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
            }

            if preferences.iCloudSyncEnabled {
                HStack {
                    Image(systemName: "icloud")
                        .foregroundStyle(.secondary)
                    Text("Status: ")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(syncManager.syncStatus.description)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Sync your characters across all your Apple devices")
        }
        .sheet(isPresented: $showingSyncStatus) {
            iCloudSyncStatusView()
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text("1")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com")!) {
                HStack {
                    Text("Source Code")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
            }

            Link(destination: URL(string: "https://github.com")!) {
                HStack {
                    Text("Report an Issue")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
