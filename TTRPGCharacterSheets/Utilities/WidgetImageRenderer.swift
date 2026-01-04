//
//  WidgetImageRenderer.swift
//  TTRPGCharacterSheets
//
//  Created for Widget Extension support
//  Renders PDF pages with PencilKit drawings into static images
//

import UIKit
import PDFKit
import PencilKit

/// Service for rendering character sheet snapshots for widgets
/// Combines PDF backgrounds with PencilKit drawings into optimized images
enum WidgetImageRenderer {

    /// Configuration for image rendering
    struct RenderConfiguration {
        /// Target size for the rendered image (widget constraints)
        let targetSize: CGSize

        /// Image scale factor (use device scale for crisp rendering)
        let scale: CGFloat

        /// JPEG compression quality (0.0 to 1.0)
        let compressionQuality: CGFloat

        /// Whether to render the full page or crop to visible content
        let cropToContent: Bool

        static let widgetDefault = RenderConfiguration(
            targetSize: CGSize(width: 600, height: 800),
            scale: UIScreen.main.scale,
            compressionQuality: 0.75,
            cropToContent: false
        )

        static let widgetLarge = RenderConfiguration(
            targetSize: CGSize(width: 800, height: 1000),
            scale: UIScreen.main.scale,
            compressionQuality: 0.8,
            cropToContent: false
        )
    }

    /// Result of a rendering operation
    enum RenderResult {
        case success(UIImage)
        case failure(RenderError)
    }

    /// Errors that can occur during rendering
    enum RenderError: Error, LocalizedError {
        case invalidPDFData
        case invalidPageIndex
        case invalidDrawingData
        case renderingFailed
        case memoryLimitExceeded

        var errorDescription: String? {
            switch self {
            case .invalidPDFData:
                return "PDF data is invalid or corrupted"
            case .invalidPageIndex:
                return "Page index is out of bounds"
            case .invalidDrawingData:
                return "Drawing data could not be decoded"
            case .renderingFailed:
                return "Failed to render image"
            case .memoryLimitExceeded:
                return "Rendering would exceed memory limits"
            }
        }
    }

    // MARK: - Public API

    /// Renders a character sheet page with drawing overlay
    /// - Parameters:
    ///   - pdfData: Raw PDF document data
    ///   - pageIndex: Zero-based page index to render
    ///   - drawingData: Optional PencilKit drawing data to overlay
    ///   - configuration: Rendering configuration (defaults to widget settings)
    /// - Returns: Rendered UIImage or error
    static func renderCharacterSheet(
        pdfData: Data,
        pageIndex: Int,
        drawingData: Data?,
        configuration: RenderConfiguration = .widgetDefault
    ) -> RenderResult {
        // Validate memory constraints before attempting render
        guard isWithinMemoryLimits(for: configuration) else {
            return .failure(.memoryLimitExceeded)
        }

        // Create PDF document from data
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            return .failure(.invalidPDFData)
        }

        // Validate page index
        guard pageIndex >= 0, pageIndex < pdfDocument.pageCount else {
            return .failure(.invalidPageIndex)
        }

        guard let pdfPage = pdfDocument.page(at: pageIndex) else {
            return .failure(.invalidPageIndex)
        }

        // Parse drawing data if provided
        var drawing: PKDrawing?
        if let drawingData = drawingData {
            do {
                drawing = try PKDrawing(data: drawingData)
            } catch {
                return .failure(.invalidDrawingData)
            }
        }

        // Perform the rendering
        guard let renderedImage = renderPageWithDrawing(
            pdfPage: pdfPage,
            drawing: drawing,
            configuration: configuration
        ) else {
            return .failure(.renderingFailed)
        }

        return .success(renderedImage)
    }

    /// Convenience method for rendering with minimal parameters
    /// Returns nil on failure (useful for optional chaining in widgets)
    static func renderCharacterSheetImage(
        pdfData: Data,
        pageIndex: Int,
        drawingData: Data?
    ) -> UIImage? {
        let result = renderCharacterSheet(
            pdfData: pdfData,
            pageIndex: pageIndex,
            drawingData: drawingData
        )

        switch result {
        case .success(let image):
            return image
        case .failure:
            return nil
        }
    }

    // MARK: - Private Rendering Implementation

    private static func renderPageWithDrawing(
        pdfPage: PDFPage,
        drawing: PKDrawing?,
        configuration: RenderConfiguration
    ) -> UIImage? {
        // Get PDF page bounds in points
        let pdfBounds = pdfPage.bounds(for: .mediaBox)

        // Calculate rendering size maintaining aspect ratio
        let renderSize = calculateRenderSize(
            from: pdfBounds.size,
            targetSize: configuration.targetSize
        )

        // Create graphics context with appropriate scale
        let renderer = UIGraphicsImageRenderer(
            size: renderSize,
            format: UIGraphicsImageRendererFormat.default().applying {
                $0.scale = configuration.scale
                $0.opaque = true
                $0.preferredRange = .standard
            }
        )

        let image = renderer.image { context in
            let cgContext = context.cgContext

            // Fill white background
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: renderSize))

            // Save graphics state
            cgContext.saveGState()

            // Transform coordinate system for PDF rendering
            // PDFKit uses bottom-left origin, UIKit uses top-left
            cgContext.translateBy(x: 0, y: renderSize.height)
            cgContext.scaleBy(x: 1.0, y: -1.0)

            // Scale to fit target size
            let scaleX = renderSize.width / pdfBounds.width
            let scaleY = renderSize.height / pdfBounds.height
            let scale = min(scaleX, scaleY)

            // Center the PDF if aspect ratios don't match
            let scaledSize = CGSize(
                width: pdfBounds.width * scale,
                height: pdfBounds.height * scale
            )
            let offsetX = (renderSize.width - scaledSize.width) / 2
            let offsetY = (renderSize.height - scaledSize.height) / 2

            cgContext.translateBy(x: offsetX, y: offsetY)
            cgContext.scaleBy(x: scale, y: scale)

            // Render the PDF page
            pdfPage.draw(with: .mediaBox, to: cgContext)

            // Restore graphics state
            cgContext.restoreGState()

            // Draw PencilKit drawing if present
            if let drawing = drawing {
                // PencilKit drawing uses same coordinate system as UIKit (top-left origin)
                // Scale to match the rendered PDF size
                cgContext.saveGState()

                cgContext.translateBy(x: offsetX, y: offsetY)
                cgContext.scaleBy(x: scale, y: scale)

                // Render the drawing
                let drawingBounds = CGRect(origin: .zero, size: pdfBounds.size)
                drawing.image(from: drawingBounds, scale: configuration.scale).draw(in: drawingBounds)

                cgContext.restoreGState()
            }
        }

        return image
    }

    // MARK: - Helper Methods

    /// Calculates appropriate render size while maintaining aspect ratio
    private static func calculateRenderSize(
        from sourceSize: CGSize,
        targetSize: CGSize
    ) -> CGSize {
        let widthRatio = targetSize.width / sourceSize.width
        let heightRatio = targetSize.height / sourceSize.height
        let scale = min(widthRatio, heightRatio)

        return CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
    }

    /// Validates that rendering won't exceed widget memory limits
    /// Widgets have strict memory limits (typically 30-50MB depending on device)
    private static func isWithinMemoryLimits(for configuration: RenderConfiguration) -> Bool {
        let size = configuration.targetSize
        let scale = configuration.scale

        // Calculate estimated memory usage (bytes per pixel * pixels)
        // RGBA uses 4 bytes per pixel
        let bytesPerPixel: CGFloat = 4
        let estimatedMemory = size.width * size.height * scale * scale * bytesPerPixel

        // Widget memory limit (conservative estimate: 20MB for image rendering)
        let memoryLimit: CGFloat = 20 * 1024 * 1024

        return estimatedMemory < memoryLimit
    }

    /// Generates a placeholder image for error states
    static func generatePlaceholderImage(size: CGSize = CGSize(width: 600, height: 800)) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let cgContext = context.cgContext

            // Draw gradient background
            let colors = [
                UIColor.systemGray5.cgColor,
                UIColor.systemGray6.cgColor
            ]

            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            ) else { return }

            cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: size.height),
                options: []
            )

            // Draw icon or text
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .medium),
                .foregroundColor: UIColor.systemGray
            ]

            let text = "📋"
            let textSize = (text as NSString).size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            (text as NSString).draw(in: textRect, withAttributes: textAttributes)
        }
    }
}

// MARK: - UIGraphicsImageRendererFormat Extension

private extension UIGraphicsImageRendererFormat {
    func applying(_ configure: (UIGraphicsImageRendererFormat) -> Void) -> UIGraphicsImageRendererFormat {
        configure(self)
        return self
    }
}
