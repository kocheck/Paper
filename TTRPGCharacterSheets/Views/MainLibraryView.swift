//
//  MainLibraryView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI
import SwiftData

struct MainLibraryView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var stateRestoration: StateRestorationManager

    // MARK: - Queries
    @Query(sort: \Character.dateModified, order: .reverse) private var characters: [Character]
    @Query(sort: \Template.dateImported, order: .reverse) private var templates: [Template]

    // MARK: - State
    @State private var showingImportTemplatePicker = false
    @State private var showingCreateCharacterSheet = false
    @State private var selectedCharacter: Character?
    @State private var showingCharacterEditor = false
    @State private var searchText = ""
    @State private var showingTemplateLibrary = false

    // MARK: - Grid Layout
    private let columns = [
        GridItem(.adaptive(minimum: 250, maximum: 350), spacing: 20)
    ]

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Section
                        headerSection

                        // Characters Grid
                        if filteredCharacters.isEmpty {
                            emptyStateView
                        } else {
                            charactersGrid
                        }
                    }
                    .padding()
                }

                // Floating Action Buttons
                floatingActionButtons
            }
            .navigationTitle("Character Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTemplateLibrary = true
                    } label: {
                        Label("Templates", systemImage: "doc.on.doc")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search characters...")
            .sheet(isPresented: $showingImportTemplatePicker) {
                ImportTemplateView()
            }
            .sheet(isPresented: $showingCreateCharacterSheet) {
                CreateCharacterView(templates: templates)
            }
            .sheet(isPresented: $showingTemplateLibrary) {
                TemplateLibraryView()
            }
            .fullScreenCover(item: $selectedCharacter) { character in
                CharacterEditorView(character: character)
            }
            .onAppear {
                handleStateRestoration()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Characters")
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Text("\(characters.count) character\(characters.count == 1 ? "" : "s")")
                    .foregroundStyle(.secondary)

                Spacer()

                if !templates.isEmpty {
                    Text("\(templates.count) template\(templates.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
        }
    }

    // MARK: - Characters Grid
    private var charactersGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(filteredCharacters) { character in
                CharacterCardView(character: character)
                    .onTapGesture {
                        selectedCharacter = character
                        showingCharacterEditor = true
                    }
                    .contextMenu {
                        Button {
                            selectedCharacter = character
                        } label: {
                            Label("Open", systemImage: "arrow.up.right.square")
                        }

                        Button {
                            toggleFavorite(character)
                        } label: {
                            Label(
                                character.isFavorite ? "Unfavorite" : "Favorite",
                                systemImage: character.isFavorite ? "star.slash" : "star"
                            )
                        }

                        Divider()

                        Button(role: .destructive) {
                            deleteCharacter(character)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)

            Text("No Characters Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Import a template and create your first character to get started")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)

            Button {
                if templates.isEmpty {
                    showingImportTemplatePicker = true
                } else {
                    showingCreateCharacterSheet = true
                }
            } label: {
                Label(
                    templates.isEmpty ? "Import Template" : "Create Character",
                    systemImage: templates.isEmpty ? "square.and.arrow.down" : "plus.circle.fill"
                )
                .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Floating Action Buttons
    private var floatingActionButtons: some View {
        VStack(spacing: 16) {
            // Create Character Button
            if !templates.isEmpty {
                Button {
                    showingCreateCharacterSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
            }

            // Import Template Button
            Button {
                showingImportTemplatePicker = true
            } label: {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(Color.green)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
        }
        .padding(30)
    }

    // MARK: - Computed Properties
    private var filteredCharacters: [Character] {
        if searchText.isEmpty {
            return characters
        } else {
            return characters.filter { character in
                character.name.localizedCaseInsensitiveContains(searchText) ||
                character.templateName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // MARK: - Actions
    private func toggleFavorite(_ character: Character) {
        withAnimation {
            character.isFavorite.toggle()
            try? modelContext.save()
        }
    }

    private func deleteCharacter(_ character: Character) {
        withAnimation {
            modelContext.delete(character)
            try? modelContext.save()
        }
    }

    private func handleStateRestoration() {
        guard stateRestoration.shouldRestoreState,
              let characterID = stateRestoration.characterToRestore else {
            return
        }

        // Find the character to restore
        if let character = characters.first(where: { $0.id == characterID }) {
            selectedCharacter = character
            showingCharacterEditor = true
            stateRestoration.completeRestoration()
        }
    }
}

// MARK: - Character Card View
struct CharacterCardView: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .aspectRatio(8.5/11, contentMode: .fit)

                Image(systemName: "doc.richtext")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)

                // Favorite indicator
                if character.isFavorite {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(character.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(character.templateName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    Text(character.formattedModificationDate)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    if character.pageCount > 0 {
                        Text("\(character.pageCount) pages")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    MainLibraryView()
        .modelContainer(for: [Template.self, Character.self, PageDrawing.self], inMemory: true)
        .environmentObject(StateRestorationManager.shared)
}
