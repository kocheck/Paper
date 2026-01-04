//
//  PageCurlView.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import SwiftUI
import UIKit
import PDFKit
import PencilKit

/// SwiftUI wrapper for UIPageViewController with page curl transition
struct PageCurlView: UIViewControllerRepresentable {
    // MARK: - Properties
    let pdfDocument: PDFDocument
    @Bindable var character: Character
    @Binding var currentPageIndex: Int
    @Binding var hasUnsavedChanges: Bool

    // MARK: - UIViewControllerRepresentable
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [
                UIPageViewController.OptionsKey.spineLocation: UIPageViewController.SpineLocation.min
            ]
        )

        pageViewController.delegate = context.coordinator
        pageViewController.dataSource = context.coordinator

        // Set initial page
        if let initialPage = context.coordinator.viewController(at: currentPageIndex) {
            pageViewController.setViewControllers(
                [initialPage],
                direction: .forward,
                animated: false
            )
        }

        return pageViewController
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        // Update current page if binding changed
        if let currentVC = uiViewController.viewControllers?.first as? PDFPageViewController,
           currentVC.pageIndex != currentPageIndex {

            let direction: UIPageViewController.NavigationDirection = currentVC.pageIndex < currentPageIndex ? .forward : .reverse

            if let newVC = context.coordinator.viewController(at: currentPageIndex) {
                uiViewController.setViewControllers(
                    [newVC],
                    direction: direction,
                    animated: true
                )
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            pdfDocument: pdfDocument,
            character: character,
            currentPageIndex: $currentPageIndex,
            hasUnsavedChanges: $hasUnsavedChanges
        )
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
        let pdfDocument: PDFDocument
        var character: Character
        @Binding var currentPageIndex: Int
        @Binding var hasUnsavedChanges: Bool

        private var viewControllers: [Int: PDFPageViewController] = [:]

        init(
            pdfDocument: PDFDocument,
            character: Character,
            currentPageIndex: Binding<Int>,
            hasUnsavedChanges: Binding<Bool>
        ) {
            self.pdfDocument = pdfDocument
            self.character = character
            _currentPageIndex = currentPageIndex
            _hasUnsavedChanges = hasUnsavedChanges
        }

        // MARK: - UIPageViewControllerDataSource
        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let currentVC = viewController as? PDFPageViewController else { return nil }
            let previousIndex = currentVC.pageIndex - 1

            guard previousIndex >= 0 else { return nil }

            return self.viewController(at: previousIndex)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let currentVC = viewController as? PDFPageViewController else { return nil }
            let nextIndex = currentVC.pageIndex + 1

            guard nextIndex < pdfDocument.pageCount else { return nil }

            return self.viewController(at: nextIndex)
        }

        // MARK: - UIPageViewControllerDelegate
        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let currentVC = pageViewController.viewControllers?.first as? PDFPageViewController else {
                return
            }

            currentPageIndex = currentVC.pageIndex
        }

        // MARK: - View Controller Factory
        func viewController(at index: Int) -> PDFPageViewController? {
            guard index >= 0 && index < pdfDocument.pageCount else { return nil }
            guard let page = pdfDocument.page(at: index) else { return nil }

            // Reuse existing view controller if available
            if let existingVC = viewControllers[index] {
                return existingVC
            }

            // Create new view controller
            let viewController = PDFPageViewController(
                page: page,
                pageIndex: index,
                character: character,
                hasUnsavedChanges: $hasUnsavedChanges
            )

            viewControllers[index] = viewController
            return viewController
        }
    }
}

// MARK: - PDF Page View Controller
class PDFPageViewController: UIViewController {
    // MARK: - Properties
    let page: PDFPage
    let pageIndex: Int
    var character: Character
    @Binding var hasUnsavedChanges: Bool

    private var pdfView: PDFPageUIView!
    private var canvasView: PKCanvasView!
    private var autoSaveTimer: Timer?

    // MARK: - Initialization
    init(
        page: PDFPage,
        pageIndex: Int,
        character: Character,
        hasUnsavedChanges: Binding<Bool>
    ) {
        self.page = page
        self.pageIndex = pageIndex
        self.character = character
        _hasUnsavedChanges = hasUnsavedChanges
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
        loadDrawing()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveDrawing()
        autoSaveTimer?.invalidate()
    }

    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .white

        // PDF Background
        pdfView = PDFPageUIView(page: page)
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pdfView)

        // PencilKit Canvas
        canvasView = PKCanvasView()
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.allowsFingerDrawing = false
        canvasView.delegate = self
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)

        // Constraints
        NSLayoutConstraint.activate([
            pdfView.topAnchor.constraint(equalTo: view.topAnchor),
            pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            canvasView.topAnchor.constraint(equalTo: view.topAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Tool Picker
        let toolPicker = PKToolPicker.shared(for: view.window)
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        toolPicker?.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    private func loadDrawing() {
        if let pageDrawing = character.getPageDrawing(for: pageIndex),
           let drawing = pageDrawing.pkDrawing {
            canvasView.drawing = drawing
        }
    }

    private func saveDrawing() {
        let pageDrawing = character.createPageDrawingIfNeeded(for: pageIndex)

        do {
            try pageDrawing.save(drawing: canvasView.drawing)
            hasUnsavedChanges = false
        } catch {
            print("Failed to save drawing: \(error)")
        }
    }

    private func scheduleAutoSave() {
        autoSaveTimer?.invalidate()

        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.saveDrawing()
        }
    }
}

// MARK: - PKCanvasViewDelegate
extension PDFPageViewController: PKCanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        hasUnsavedChanges = true
        scheduleAutoSave()
    }
}

// MARK: - PDF Page UI View (from CharacterEditorView)
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
