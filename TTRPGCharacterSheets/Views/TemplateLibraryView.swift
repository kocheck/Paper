//
//  TemplateLibraryView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI
import SwiftData

struct TemplateLibraryView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Queries
    @Query(sort: \Template.dateImported, order: .reverse) private var templates: [Template]

    // MARK: - State
    @State private var showingImportPicker = false
    @State private var selectedTemplate: Template?
    @State private var showingDeleteAlert = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    TemplateRow(template: template)
                        .contentShape(Rectangle())
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                selectedTemplate = template
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Template Library")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import", systemImage: "plus")
                    }
                }
            }
            .overlay {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.on.doc",
                        description: Text("Import a PDF template to get started")
                    )
                }
            }
            .sheet(isPresented: $showingImportPicker) {
                ImportTemplateView()
            }
            .alert("Delete Template?", isPresented: $showingDeleteAlert, presenting: selectedTemplate) { template in
                Button("Cancel", role: .cancel) { }

                Button("Delete", role: .destructive) {
                    deleteTemplate(template)
                }
            } message: { template in
                Text("This will delete '\(template.name)' and all \(template.characterCount) character\(template.characterCount == 1 ? "" : "s") created from it. This action cannot be undone.")
            }
        }
    }

    // MARK: - Actions
    private func deleteTemplate(_ template: Template) {
        modelContext.delete(template)
        try? modelContext.save()
    }
}

// MARK: - Template Row
struct TemplateRow: View {
    let template: Template

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.name)
                .font(.headline)

            HStack {
                Label("\(template.pageCount)", systemImage: "doc")

                Text("•")

                Label(template.formattedFileSize, systemImage: "arrow.down.circle")

                if template.characterCount > 0 {
                    Text("•")

                    Label("\(template.characterCount)", systemImage: "person")
                }

                Spacer()

                Text(template.dateImported.formatted(date: .abbreviated, time: .omitted))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Template.self, configurations: config)

    let template = Template(
        name: "D&D 5e Character Sheet",
        pdfData: Data(count: 1_500_000),
        pageCount: 3
    )

    container.mainContext.insert(template)

    return TemplateLibraryView()
        .modelContainer(container)
}
