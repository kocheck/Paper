//
//  ImportTemplateView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI
import SwiftData
import PDFKit
import UniformTypeIdentifiers

struct ImportTemplateView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var showingFilePicker = false
    @State private var templateName = ""
    @State private var selectedPDFData: Data?
    @State private var pdfDocument: PDFDocument?
    @State private var isProcessing = false
    @State private var errorMessage: String?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {
                Section("PDF File") {
                    if let pdfDoc = pdfDocument {
                        HStack {
                            Image(systemName: "doc.richtext.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.blue)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("PDF Selected")
                                    .font(.headline)

                                Text("\(pdfDoc.pageCount) page\(pdfDoc.pageCount == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if let data = selectedPDFData {
                                    Text(ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file))
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }

                            Spacer()

                            Button("Change") {
                                showingFilePicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button {
                            showingFilePicker = true
                        } label: {
                            Label("Select PDF File", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if pdfDocument != nil {
                    Section("Template Details") {
                        TextField("Template Name", text: $templateName)
                            .textInputAutocapitalization(.words)

                        if templateName.isEmpty {
                            Text("Please provide a name for this template")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Section("Preview") {
                        if let page = pdfDocument?.page(at: 0) {
                            PDFPagePreview(page: page)
                                .frame(height: 400)
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Import Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        importTemplate()
                    }
                    .disabled(!canImport)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .overlay {
                if isProcessing {
                    ProgressView("Importing...")
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 10)
                }
            }
        }
    }

    // MARK: - Computed Properties
    private var canImport: Bool {
        pdfDocument != nil && !templateName.isEmpty && !isProcessing
    }

    // MARK: - Actions
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            do {
                // Access security scoped resource
                let gotAccess = url.startAccessingSecurityScopedResource()
                defer {
                    if gotAccess {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                // Read PDF data
                let data = try Data(contentsOf: url)
                guard let pdfDoc = PDFDocument(data: data) else {
                    errorMessage = "Failed to load PDF. The file may be corrupted."
                    return
                }

                // Update state
                selectedPDFData = data
                pdfDocument = pdfDoc

                // Auto-fill template name from filename if empty
                if templateName.isEmpty {
                    templateName = url.deletingPathExtension().lastPathComponent
                }

                errorMessage = nil

            } catch {
                errorMessage = "Failed to read PDF: \(error.localizedDescription)"
            }

        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }

    private func importTemplate() {
        guard let pdfData = selectedPDFData,
              let pdfDoc = pdfDocument else {
            return
        }

        isProcessing = true
        errorMessage = nil

        // Generate thumbnail from first page
        let thumbnailData = generateThumbnail(from: pdfDoc)

        // Create template
        let template = Template(
            name: templateName,
            pdfData: pdfData,
            pageCount: pdfDoc.pageCount,
            thumbnailData: thumbnailData
        )

        // Save to context
        modelContext.insert(template)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save template: \(error.localizedDescription)"
            isProcessing = false
        }
    }

    private func generateThumbnail(from document: PDFDocument) -> Data? {
        guard let page = document.page(at: 0) else { return nil }

        let pageRect = page.bounds(for: .mediaBox)
        let targetSize = CGSize(width: 300, height: 300 * (pageRect.height / pageRect.width))

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let image = renderer.image { context in
            UIColor.white.set()
            context.fill(CGRect(origin: .zero, size: targetSize))

            context.cgContext.translateBy(x: 0, y: targetSize.height)
            context.cgContext.scaleBy(x: 1.0, y: -1.0)

            let scale = targetSize.width / pageRect.width
            context.cgContext.scaleBy(x: scale, y: scale)

            page.draw(with: .mediaBox, to: context.cgContext)
        }

        return image.pngData()
    }
}

// MARK: - PDF Page Preview
struct PDFPagePreview: View {
    let page: PDFPage

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let pageRect = page.bounds(for: .mediaBox)
                let scale = min(size.width / pageRect.width, size.height / pageRect.height)

                let scaledWidth = pageRect.width * scale
                let scaledHeight = pageRect.height * scale
                let x = (size.width - scaledWidth) / 2
                let y = (size.height - scaledHeight) / 2

                context.translateBy(x: x, y: y + scaledHeight)
                context.scaleBy(x: scale, y: -scale)

                context.draw(PDFPageRenderer(page: page), at: .zero)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - PDF Page Renderer
struct PDFPageRenderer: View {
    let page: PDFPage

    var body: some View {
        PDFPageRepresentable(page: page)
    }
}

struct PDFPageRepresentable: UIViewRepresentable {
    let page: PDFPage

    func makeUIView(context: Context) -> PDFPageView {
        PDFPageView(page: page)
    }

    func updateUIView(_ uiView: PDFPageView, context: Context) {
        uiView.page = page
    }
}

class PDFPageView: UIView {
    var page: PDFPage? {
        didSet {
            setNeedsDisplay()
        }
    }

    init(page: PDFPage?) {
        self.page = page
        super.init(frame: .zero)
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let page = page else {
            return
        }

        context.saveGState()
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)

        let pageRect = page.bounds(for: .mediaBox)
        let scale = min(bounds.width / pageRect.width, bounds.height / pageRect.height)
        context.scaleBy(x: scale, y: scale)

        page.draw(with: .mediaBox, to: context)
        context.restoreGState()
    }
}

// MARK: - Preview
#Preview {
    ImportTemplateView()
        .modelContainer(for: [Template.self], inMemory: true)
}
