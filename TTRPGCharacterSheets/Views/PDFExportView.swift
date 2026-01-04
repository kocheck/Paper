//
//  PDFExportView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI

struct PDFExportView: View {
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties
    let character: Character

    // MARK: - State
    @State private var exportOnlyAnnotated = false
    @State private var includeMetadata = true
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showingShareSheet = false
    @State private var errorMessage: String?
    @State private var exportStats: PDFExportService.ExportStatistics?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                // Preview Section
                previewSection

                // Export Options
                optionsSection

                // Statistics
                if let stats = exportStats {
                    statisticsSection(stats)
                }

                // Error Display
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                // Export Button
                Section {
                    Button {
                        exportPDF()
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text(isExporting ? "Exporting..." : "Export PDF")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Export PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadStatistics()
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Preview Section
    private var previewSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.richtext")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(character.name)
                            .font(.headline)

                        Text(character.templateName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Character")
        }
    }

    // MARK: - Options Section
    private var optionsSection: some View {
        Section {
            Toggle("Export Only Annotated Pages", isOn: $exportOnlyAnnotated)

            Toggle("Include Metadata", isOn: $includeMetadata)
        } header: {
            Text("Export Options")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if exportOnlyAnnotated {
                    Text("Only pages with drawings will be included in the export")
                } else {
                    Text("All pages will be included, even those without annotations")
                }
            }
            .font(.caption)
        }
    }

    // MARK: - Statistics Section
    private func statisticsSection(_ stats: PDFExportService.ExportStatistics) -> some View {
        Section {
            HStack {
                Label("Total Pages", systemImage: "doc")
                Spacer()
                Text("\(stats.totalPages)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Annotated Pages", systemImage: "pencil")
                Spacer()
                Text("\(stats.annotatedPages)")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Approximate Size", systemImage: "archivebox")
                Spacer()
                Text(stats.formattedFileSize)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Statistics")
        }
    }

    // MARK: - Actions
    private func loadStatistics() {
        exportStats = PDFExportService.getExportStatistics(for: character)
    }

    private func exportPDF() {
        isExporting = true
        errorMessage = nil

        // Perform export on background thread
        Task {
            do {
                let options = PDFExportService.ExportOptions(
                    exportOnlyAnnotatedPages: exportOnlyAnnotated,
                    fileName: character.name,
                    includeMetadata: includeMetadata
                )

                let fileURL = try PDFExportService.exportCharacter(character, options: options)

                await MainActor.run {
                    exportedFileURL = fileURL
                    showingShareSheet = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

// MARK: - Preview
#Preview {
    let character = Character(
        name: "Gandalf the Grey",
        notes: "Wizard of Middle-earth"
    )

    return PDFExportView(character: character)
}
