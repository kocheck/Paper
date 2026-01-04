//
//  CharacterEditorView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI
import SwiftData
import PDFKit
import PencilKit

struct CharacterEditorView: View {
    // MARK: - Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stateRestoration: StateRestorationManager

    // MARK: - Properties
    @Bindable var character: Character

    // MARK: - ViewModel
    @State private var viewModel: CharacterEditorViewModel?

    // MARK: - Initialization
    init(character: Character) {
        self.character = character
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    contentView(vm: vm)
                } else {
                    ProgressView("Initializing...")
                }
            }
        }
        .onAppear {
            initializeViewModel()
        }
    }

    // MARK: - Content View
    @ViewBuilder
    private func contentView(vm: CharacterEditorViewModel) -> some View {
        ZStack {
            if let pdfDoc = vm.pdfDocument {
                // Multi-page PDF + PencilKit view
                if vm.pageTransitionStyle == .pageCurl {
                    // Page curl animation
                    PageCurlView(
                        pdfDocument: pdfDoc,
                        character: character,
                        currentPageIndex: Binding(
                            get: { vm.currentPageIndex },
                            set: { vm.currentPageIndex = $0 }
                        ),
                        hasUnsavedChanges: Binding(
                            get: { vm.hasUnsavedChanges },
                            set: { if $0 { vm.markDrawingChanged() } else { vm.clearUnsavedChanges() } }
                        )
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .environment(\.characterEditorViewModel, vm)
                } else {
                    // Standard TabView
                    PagedPDFCanvasView(
                        pdfDocument: pdfDoc,
                        character: character,
                        currentPageIndex: Binding(
                            get: { vm.currentPageIndex },
                            set: { vm.currentPageIndex = $0 }
                        ),
                        hasUnsavedChanges: Binding(
                            get: { vm.hasUnsavedChanges },
                            set: { if $0 { vm.markDrawingChanged() } else { vm.clearUnsavedChanges() } }
                        )
                    )
                    .environment(\.characterEditorViewModel, vm)
                }
            } else if vm.isLoading {
                // Loading state
                ProgressView("Loading character sheet...")
            } else {
                // Error state
                ContentUnavailableView(
                    "Unable to Load PDF",
                    systemImage: "doc.text.fill",
                    description: Text("The character sheet template could not be loaded.")
                )
            }
        }
        .navigationTitle(character.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    vm.saveAndDismiss { dismiss() }
                } label: {
                    Label("Close", systemImage: "xmark")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    if vm.hasUnsavedChanges {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(.orange)
                            .imageScale(.small)
                    }

                    // Undo/Redo buttons
                    Button {
                        vm.undo()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!vm.canUndo)
                    .keyboardShortcut("z", modifiers: .command)

                    Button {
                        vm.redo()
                    } label: {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
                    .disabled(!vm.canRedo)
                    .keyboardShortcut("z", modifiers: [.command, .shift])

                    Button {
                        vm.showExportView()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        vm.showToolPicker()
                    } label: {
                        Label("Tools", systemImage: "pencil.tip.crop.circle")
                    }
                }
            }

            ToolbarItemGroup(placement: .bottomBar) {
                // Page navigation
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.navigateToPreviousPage()
                    }
                } label: {
                    Label("Previous Page", systemImage: "chevron.left")
                }
                .disabled(!vm.canNavigatePrevious)

                Spacer()

                Text(vm.pageNumberLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        vm.navigateToNextPage()
                    }
                } label: {
                    Label("Next Page", systemImage: "chevron.right")
                }
                .disabled(!vm.canNavigateNext)
            }
        }
        .sheet(isPresented: Binding(
            get: { vm.showingToolPicker },
            set: { if !$0 { vm.hideToolPicker() } }
        )) {
            ToolPickerView()
        }
        .sheet(isPresented: Binding(
            get: { vm.showingExportView },
            set: { if !$0 { vm.hideExportView() } }
        )) {
            PDFExportView(character: character)
        }
    }

    // MARK: - Helper Methods
    private func initializeViewModel() {
        guard viewModel == nil else { return }

        let vm = CharacterEditorViewModel(
            character: character,
            modelContext: modelContext,
            stateRestoration: stateRestoration
        )
        vm.loadPDF()
        viewModel = vm
    }
}

// MARK: - Paged PDF Canvas View
struct PagedPDFCanvasView: View {
    let pdfDocument: PDFDocument
    @Bindable var character: Character
    @Binding var currentPageIndex: Int
    @Binding var hasUnsavedChanges: Bool

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $currentPageIndex) {
            ForEach(0..<pdfDocument.pageCount, id: \.self) { pageIndex in
                if let page = pdfDocument.page(at: pageIndex) {
                    PDFCanvasPageView(
                        page: page,
                        pageIndex: pageIndex,
                        character: character,
                        hasUnsavedChanges: $hasUnsavedChanges
                    )
                    .tag(pageIndex)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - PDF Canvas Page View (Single Page)
struct PDFCanvasPageView: View {
    let page: PDFPage
    let pageIndex: Int
    @Bindable var character: Character
    @Binding var hasUnsavedChanges: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.characterEditorViewModel) private var viewModel

    @State private var canvasView: PKCanvasView?
    @State private var autoSaveTimer: Timer?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // PDF Background
                PDFPageView(page: page)
                    .background(Color.white)

                // PencilKit Canvas Overlay
                PencilKitCanvasView(
                    pageIndex: pageIndex,
                    character: character,
                    canvasView: $canvasView,
                    onDrawingChanged: {
                        hasUnsavedChanges = true
                        scheduleAutoSave()
                    },
                    onUndoManagerChanged: { undoManager in
                        viewModel?.registerUndoManager(undoManager)
                    }
                )
            }
        }
        .onDisappear {
            saveDrawing()
            autoSaveTimer?.invalidate()
        }
    }

    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()

        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            saveDrawing()
        }
    }

    private func saveDrawing() {
        guard let canvas = canvasView else { return }

        let pageDrawing = character.createPageDrawingIfNeeded(for: pageIndex)

        do {
            try pageDrawing.save(drawing: canvas.drawing)
            try modelContext.save()
            hasUnsavedChanges = false
        } catch {
            print("Failed to save drawing: \(error)")
        }
    }
}

// MARK: - PDF Page View (UIKit Bridge)
struct PDFPageView: UIViewRepresentable {
    let page: PDFPage

    func makeUIView(context: Context) -> PDFPageUIView {
        PDFPageUIView(page: page)
    }

    func updateUIView(_ uiView: PDFPageUIView, context: Context) {
        uiView.page = page
    }
}

class PDFPageUIView: UIView {
    var page: PDFPage? {
        didSet {
            setNeedsDisplay()
        }
    }

    init(page: PDFPage?) {
        self.page = page
        super.init(frame: .zero)
        backgroundColor = .white
        isUserInteractionEnabled = false
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

        // White background
        UIColor.white.setFill()
        context.fill(rect)

        // Transform coordinate system for PDF rendering
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)

        // Calculate scale to fit page in view
        let pageRect = page.bounds(for: .mediaBox)
        let scaleX = bounds.width / pageRect.width
        let scaleY = bounds.height / pageRect.height
        let scale = min(scaleX, scaleY)

        // Center the page
        let scaledWidth = pageRect.width * scale
        let scaledHeight = pageRect.height * scale
        let x = (bounds.width - scaledWidth) / 2
        let y = (bounds.height - scaledHeight) / 2

        context.translateBy(x: x, y: y)
        context.scaleBy(x: scale, y: scale)

        // Draw PDF page
        page.draw(with: .mediaBox, to: context)

        context.restoreGState()
    }
}

// MARK: - PencilKit Canvas View (UIKit Bridge)
struct PencilKitCanvasView: UIViewRepresentable {
    let pageIndex: Int
    let character: Character
    @Binding var canvasView: PKCanvasView?
    let onDrawingChanged: () -> Void
    let onUndoManagerChanged: ((UndoManager?) -> Void)?

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput

        // Enable Apple Pencil interactions
        canvas.allowsFingerDrawing = false

        // Load existing drawing for this page
        if let pageDrawing = character.getPageDrawing(for: pageIndex),
           let drawing = pageDrawing.pkDrawing {
            canvas.drawing = drawing
        }

        // Set up delegate
        canvas.delegate = context.coordinator

        // Show tool picker
        let toolPicker = PKToolPicker.shared(for: canvas.window)
        toolPicker?.setVisible(true, forFirstResponder: canvas)
        toolPicker?.addObserver(canvas)
        canvas.becomeFirstResponder()

        // Store reference and expose undo manager
        DispatchQueue.main.async {
            canvasView = canvas
            onUndoManagerChanged?(canvas.undoManager)
        }

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Update drawing if page changed
        if let pageDrawing = character.getPageDrawing(for: pageIndex),
           let drawing = pageDrawing.pkDrawing {
            if uiView.drawing != drawing {
                uiView.drawing = drawing
            }
        } else {
            // Clear canvas if no drawing exists for this page
            if !uiView.drawing.strokes.isEmpty {
                uiView.drawing = PKDrawing()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: () -> Void

        init(onDrawingChanged: @escaping () -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            onDrawingChanged()
        }
    }
}

// MARK: - Tool Picker View
struct ToolPickerView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Use the Apple Pencil to draw directly on the character sheet.")
                        .font(.body)

                    Text("The PencilKit tool picker appears automatically when you start drawing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Tips") {
                    Label("Double-tap Apple Pencil to switch between tools", systemImage: "apple.pencil")
                    Label("Pinch to zoom in and out", systemImage: "hand.pinch")
                    Label("Use two fingers to pan around", systemImage: "hand.tap")
                }
            }
            .navigationTitle("Drawing Tools")
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
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Template.self, Character.self, PageDrawing.self,
        configurations: config
    )

    let template = Template(
        name: "Sample Template",
        pdfData: Data(),
        pageCount: 3
    )

    let character = Character(
        name: "Aragorn",
        template: template
    )

    container.mainContext.insert(template)
    container.mainContext.insert(character)

    return CharacterEditorView(character: character)
        .modelContainer(container)
        .environmentObject(StateRestorationManager.shared)
}
