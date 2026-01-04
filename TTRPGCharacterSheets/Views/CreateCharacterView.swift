//
//  CreateCharacterView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI
import SwiftData

struct CreateCharacterView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties
    let templates: [Template]

    // MARK: - State
    @State private var characterName = ""
    @State private var selectedTemplate: Template?
    @State private var notes = ""
    @State private var isFavorite = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section("Character Details") {
                    TextField("Character Name", text: $characterName)
                        .textInputAutocapitalization(.words)

                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .textInputAutocapitalization(.sentences)

                    Toggle("Add to Favorites", isOn: $isFavorite)
                }

                Section("Select Template") {
                    if templates.isEmpty {
                        ContentUnavailableView(
                            "No Templates Available",
                            systemImage: "doc.badge.plus",
                            description: Text("Import a PDF template first")
                        )
                    } else {
                        ForEach(templates) { template in
                            TemplateSelectionRow(
                                template: template,
                                isSelected: selectedTemplate?.id == template.id
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTemplate = template
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Character")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCharacter()
                    }
                    .disabled(!canCreate)
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var canCreate: Bool {
        !characterName.isEmpty && selectedTemplate != nil
    }

    // MARK: - Actions
    private func createCharacter() {
        guard let template = selectedTemplate else { return }

        let character = Character(
            name: characterName,
            template: template,
            notes: notes.isEmpty ? nil : notes,
            isFavorite: isFavorite
        )

        modelContext.insert(character)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to create character: \(error)")
        }
    }
}

// MARK: - Template Selection Row
struct TemplateSelectionRow: View {
    let template: Template
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .blue : .secondary)
                .imageScale(.large)

            // Template info
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)

                HStack {
                    Text("\(template.pageCount) page\(template.pageCount == 1 ? "" : "s")")

                    Text("•")

                    Text(template.formattedFileSize)

                    if template.characterCount > 0 {
                        Text("•")
                        Text("\(template.characterCount) character\(template.characterCount == 1 ? "" : "s")")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    // Create sample templates
    let template1 = Template(
        name: "D&D 5e Character Sheet",
        pdfData: Data(),
        pageCount: 3
    )

    let template2 = Template(
        name: "Pathfinder 2e Character Sheet",
        pdfData: Data(),
        pageCount: 4
    )

    container.mainContext.insert(template1)
    container.mainContext.insert(template2)

    return CreateCharacterView(templates: [template1, template2])
        .modelContainer(container)
}
