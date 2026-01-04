# TTRPG Character Sheets - Development Roadmap

**Last Updated:** 2026-01-04
**Project Version:** 1.0.0
**Status:** Production Ready - Enhancement Phase

---

## Overview

This roadmap documents planned improvements for the TTRPG Character Sheets iPad application. Each task is structured with sufficient context for AI agents or developers to implement independently.

**Priority Items (In Progress):**
- ✅ Performance Benchmarking Suite
- ✅ ViewModel Architecture Extraction
- ✅ Undo/Redo Functionality

**Backlog Items:** 6 tasks organized by category

---

## Task Status Legend

- 🔴 Not Started
- 🟡 In Progress
- 🟢 Completed
- ⏸️ Blocked/On Hold

---

# REPOSITORY IMPROVEMENTS

## REPO-001: GitHub Issue and Pull Request Templates
**Status:** 🔴 Not Started
**Priority:** High
**Effort:** 2-3 hours
**Category:** Developer Experience

### Context
The repository currently lacks standardized templates for issues and pull requests. This leads to inconsistent bug reports, missing reproduction steps, and incomplete PR descriptions. Contributors need clear guidance on what information to provide.

### Acceptance Criteria
- [ ] Bug report template with required fields (iOS version, device, steps to reproduce, expected vs actual behavior)
- [ ] Feature request template with use case description and mockups section
- [ ] Pull request template with checklist (tests added, docs updated, screenshots for UI changes)
- [ ] Templates appear automatically when creating issues/PRs on GitHub

### Implementation Details

**Files to Create:**
```
.github/
├── ISSUE_TEMPLATE/
│   ├── bug_report.yml
│   ├── feature_request.yml
│   └── config.yml
└── PULL_REQUEST_TEMPLATE.md
```

**Bug Report Template Structure (bug_report.yml):**
```yaml
name: Bug Report
description: Report a bug or unexpected behavior
title: "[BUG] "
labels: ["bug", "needs-triage"]
body:
  - type: dropdown
    id: ios-version
    attributes:
      label: iOS Version
      options:
        - iPadOS 17.0
        - iPadOS 17.1+
        - iPadOS 18.0+
    validations:
      required: true
  - type: dropdown
    id: device
    attributes:
      label: iPad Model
      options:
        - iPad Pro 12.9-inch
        - iPad Pro 11-inch
        - iPad Air
        - iPad (10th generation)
  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
      placeholder: |
        1. Import D&D 5e character sheet
        2. Create new character "Test"
        3. Navigate to page 2
        4. Draw with Apple Pencil
        5. App crashes
    validations:
      required: true
  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
  - type: textarea
    id: actual
    attributes:
      label: Actual Behavior
  - type: textarea
    id: logs
    attributes:
      label: Console Logs or Screenshots
```

**Feature Request Template (feature_request.yml):**
```yaml
name: Feature Request
description: Suggest a new feature
title: "[FEATURE] "
labels: ["enhancement"]
body:
  - type: textarea
    id: problem
    attributes:
      label: Problem Statement
      description: What problem does this solve?
  - type: textarea
    id: solution
    attributes:
      label: Proposed Solution
  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives Considered
  - type: textarea
    id: mockups
    attributes:
      label: Mockups or Examples
      description: Attach screenshots or sketches if applicable
```

**Pull Request Template (PULL_REQUEST_TEMPLATE.md):**
```markdown
## Description
<!-- Brief description of changes -->

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update
- [ ] Performance improvement

## Checklist
- [ ] Tests added/updated (if applicable)
- [ ] Documentation updated (README, ARCHITECTURE, etc.)
- [ ] SwiftLint passes with no warnings
- [ ] UI tests pass for affected flows
- [ ] Screenshots attached for UI changes
- [ ] Accessibility labels verified (if UI change)

## Testing
<!-- How did you test this? -->

## Screenshots (if applicable)
<!-- Add before/after screenshots for UI changes -->

## Related Issues
Closes #<issue_number>
```

**Config Template (config.yml):**
```yaml
blank_issues_enabled: false
contact_links:
  - name: Documentation
    url: https://github.com/kocheck/Paper/blob/main/README.md
    about: Check the README for setup and usage
  - name: Architecture Guide
    url: https://github.com/kocheck/Paper/blob/main/TTRPGCharacterSheets/ARCHITECTURE.md
    about: Understand the codebase architecture
```

### Testing Requirements
- Create test issue/PR to verify templates appear correctly
- Verify required fields prevent submission when empty
- Check labels auto-apply correctly

### Related Files
- None (new files only)

### References
- [GitHub Issue Forms Documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/syntax-for-issue-forms)
- [GitHub PR Template Documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository)

---

## REPO-002: Automated Release Notes and TestFlight Deployment
**Status:** 🔴 Not Started
**Priority:** Medium
**Effort:** 4-6 hours
**Category:** CI/CD Automation

### Context
The project has CI/CD for testing and linting (pr-quality.yml, accessibility-audit.yml) but no automation for releases. Version bumps, changelog generation, and TestFlight uploads are currently manual processes that are error-prone and time-consuming.

### Acceptance Criteria
- [ ] Automated semantic versioning based on conventional commits
- [ ] Changelog generation from PR titles and commit messages
- [ ] GitHub Release created automatically on version tag
- [ ] TestFlight deployment triggered on release
- [ ] Slack/Discord notification on successful release (optional)

### Implementation Details

**Files to Create:**
```
.github/
├── workflows/
│   ├── release.yml              # Main release workflow
│   └── testflight-deploy.yml    # TestFlight upload
└── release-drafter.yml          # Release notes template
```

**Release Workflow (release.yml):**
```yaml
name: Release

on:
  push:
    tags:
      - 'v*.*.*'  # Trigger on version tags (v1.0.0, v1.2.3)

jobs:
  build-and-release:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for changelog

      - name: Setup Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: '15.2'

      - name: Extract Version
        id: version
        run: |
          VERSION=${GITHUB_REF#refs/tags/v}
          echo "version=$VERSION" >> $GITHUB_OUTPUT

      - name: Update Info.plist Version
        run: |
          /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${{ steps.version.outputs.version }}" TTRPGCharacterSheets/Info.plist

      - name: Build Archive
        run: |
          xcodebuild archive \
            -scheme TTRPGCharacterSheets \
            -destination 'generic/platform=iOS' \
            -archivePath build/TTRPGCharacterSheets.xcarchive \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            CODE_SIGNING_ALLOWED=NO

      - name: Generate Changelog
        id: changelog
        uses: mikepenz/release-changelog-builder-action@v4
        with:
          configuration: |
            {
              "categories": [
                {"title": "## 🚀 Features", "labels": ["feature", "enhancement"]},
                {"title": "## 🐛 Bug Fixes", "labels": ["bug", "fix"]},
                {"title": "## 📚 Documentation", "labels": ["docs", "documentation"]},
                {"title": "## 🎨 UI/UX", "labels": ["ui", "ux"]},
                {"title": "## ⚡ Performance", "labels": ["performance"]}
              ],
              "template": "## What's Changed\n\n${{CHANGELOG}}\n\n**Full Changelog**: ${{RELEASE_DIFF}}"
            }
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          body: ${{ steps.changelog.outputs.changelog }}
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      # Optional: Upload to TestFlight (requires App Store Connect API key)
      # - name: Upload to TestFlight
      #   uses: apple-actions/upload-testflight-build@v1
      #   with:
      #     app-path: build/TTRPGCharacterSheets.ipa
      #     issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
      #     api-key-id: ${{ secrets.APPSTORE_KEY_ID }}
      #     api-private-key: ${{ secrets.APPSTORE_PRIVATE_KEY }}
```

**Release Drafter Template (.github/release-drafter.yml):**
```yaml
name-template: 'v$RESOLVED_VERSION'
tag-template: 'v$RESOLVED_VERSION'
categories:
  - title: '🚀 New Features'
    labels:
      - 'feature'
      - 'enhancement'
  - title: '🐛 Bug Fixes'
    labels:
      - 'bug'
      - 'fix'
  - title: '🔧 Maintenance'
    labels:
      - 'chore'
      - 'refactor'
  - title: '📚 Documentation'
    labels:
      - 'docs'
      - 'documentation'
version-resolver:
  major:
    labels:
      - 'breaking'
  minor:
    labels:
      - 'feature'
      - 'enhancement'
  patch:
    labels:
      - 'bug'
      - 'fix'
      - 'chore'
template: |
  ## What's Changed

  $CHANGES

  **Full Changelog**: https://github.com/$OWNER/$REPOSITORY/compare/$PREVIOUS_TAG...v$RESOLVED_VERSION
```

**Semantic Version Bump Script (scripts/bump-version.sh):**
```bash
#!/bin/bash
# Usage: ./scripts/bump-version.sh [major|minor|patch]

CURRENT_VERSION=$(git describe --tags --abbrev=0 | sed 's/v//')
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"

MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

case $1 in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "Usage: $0 [major|minor|patch]"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "Bumping version from $CURRENT_VERSION to $NEW_VERSION"

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $NEW_VERSION" TTRPGCharacterSheets/Info.plist

# Create git tag
git add TTRPGCharacterSheets/Info.plist
git commit -m "chore: bump version to $NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

echo "✅ Version bumped to v$NEW_VERSION. Push with: git push && git push --tags"
```

### Prerequisites
- App Store Connect API credentials (for TestFlight)
- GitHub repository secrets:
  - `APPSTORE_ISSUER_ID`
  - `APPSTORE_KEY_ID`
  - `APPSTORE_PRIVATE_KEY`

### Testing Requirements
- Test release workflow on a test repository first
- Create a beta release (v1.0.1-beta) to verify workflow
- Verify changelog generation includes all merged PRs since last tag
- Confirm GitHub Release appears correctly

### Related Files
- `/TTRPGCharacterSheets/Info.plist` - Version number updates
- `/.github/workflows/pr-quality.yml` - Existing CI/CD reference

### References
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Actions for iOS](https://github.com/apple-actions)

---

# CODE IMPROVEMENTS

## CODE-001: Dependency Injection Container
**Status:** 🔴 Not Started
**Priority:** Medium
**Effort:** 6-8 hours
**Category:** Architecture

### Context
Services like `iCloudSyncManager`, `PDFExportService`, and `WidgetImageRenderer` are currently instantiated directly in views or as singletons. This creates tight coupling, makes unit testing difficult (requires CloudKit/filesystem dependencies), and violates the Dependency Inversion Principle.

### Acceptance Criteria
- [ ] Protocol abstractions created for all services
- [ ] DI container implementation (simple factory pattern or Swift Dependency library)
- [ ] Views updated to accept injected dependencies
- [ ] Mock implementations created for testing
- [ ] Unit tests demonstrating improved testability
- [ ] No singletons remain (except container itself)

### Implementation Details

**Architecture Pattern:**
```
Views (SwiftUI)
    ↓ inject
ViewModels
    ↓ inject
Services (Protocol)
    ↓ implement
Concrete Implementations
```

**Files to Create:**
```
TTRPGCharacterSheets/
├── DependencyInjection/
│   ├── DIContainer.swift
│   ├── ServiceProtocols.swift
│   └── ServiceFactory.swift
├── Services/                      # Rename from Utilities/
│   ├── iCloud/
│   │   ├── iCloudSyncProtocol.swift
│   │   ├── iCloudSyncManager.swift         # Existing, refactor
│   │   └── MockiCloudSyncManager.swift     # New for tests
│   ├── PDF/
│   │   ├── PDFExportProtocol.swift
│   │   ├── PDFExportService.swift          # Existing, refactor
│   │   └── MockPDFExportService.swift
│   └── Widget/
│       ├── WidgetRenderProtocol.swift
│       ├── WidgetImageRenderer.swift       # Existing, refactor
│       └── MockWidgetImageRenderer.swift
```

**Service Protocols (ServiceProtocols.swift):**
```swift
import Foundation
import CloudKit
import PDFKit
import PencilKit

// MARK: - iCloud Sync Protocol

protocol iCloudSyncProtocol: Sendable {
    var syncStatus: AsyncStream<iCloudSyncStatus> { get }

    func startSync() async throws
    func stopSync()
    func forceFetch() async throws
}

enum iCloudSyncStatus: Sendable {
    case idle
    case syncing
    case success(Date)
    case error(Error)
}

// MARK: - PDF Export Protocol

protocol PDFExportProtocol: Sendable {
    func exportCharacter(
        _ character: Character,
        withAnnotations: Bool
    ) async throws -> URL

    func exportPage(
        pdf: PDFDocument,
        pageIndex: Int,
        drawing: PKDrawing?
    ) async throws -> Data
}

// MARK: - Widget Rendering Protocol

protocol WidgetRenderProtocol: Sendable {
    func renderCharacterSnapshot(
        _ character: Character,
        size: CGSize
    ) async throws -> Data

    func generateThumbnail(
        from pdf: PDFDocument,
        pageIndex: Int,
        size: CGSize
    ) async throws -> Data
}
```

**DI Container (DIContainer.swift):**
```swift
import Foundation
import SwiftUI

@MainActor
final class DIContainer: ObservableObject {
    static let shared = DIContainer()

    // MARK: - Services

    private(set) lazy var iCloudSync: iCloudSyncProtocol = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return MockiCloudSyncManager()
        }
        #endif
        return iCloudSyncManager()
    }()

    private(set) lazy var pdfExport: PDFExportProtocol = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return MockPDFExportService()
        }
        #endif
        return PDFExportService()
    }()

    private(set) lazy var widgetRenderer: WidgetRenderProtocol = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return MockWidgetImageRenderer()
        }
        #endif
        return WidgetImageRenderer()
    }()

    // MARK: - Testing Overrides

    #if DEBUG
    func override(iCloudSync: iCloudSyncProtocol) {
        self.iCloudSync = iCloudSync
    }

    func override(pdfExport: PDFExportProtocol) {
        self.pdfExport = pdfExport
    }

    func override(widgetRenderer: WidgetRenderProtocol) {
        self.widgetRenderer = widgetRenderer
    }
    #endif
}

// MARK: - Environment Key

struct DIContainerKey: EnvironmentKey {
    static let defaultValue = DIContainer.shared
}

extension EnvironmentValues {
    var diContainer: DIContainer {
        get { self[DIContainerKey.self] }
        set { self[DIContainerKey.self] = newValue }
    }
}
```

**Usage in Views (Example - CharacterEditorView.swift):**
```swift
struct CharacterEditorView: View {
    @Environment(\.diContainer) private var container

    var body: some View {
        // Use container.pdfExport, container.iCloudSync, etc.
        Button("Export PDF") {
            Task {
                try await container.pdfExport.exportCharacter(
                    character,
                    withAnnotations: true
                )
            }
        }
    }
}
```

**Mock Implementation Example (MockiCloudSyncManager.swift):**
```swift
import Foundation

final class MockiCloudSyncManager: iCloudSyncProtocol {
    var shouldThrowError = false
    var syncCallCount = 0

    var syncStatus: AsyncStream<iCloudSyncStatus> {
        AsyncStream { continuation in
            continuation.yield(.idle)
            continuation.finish()
        }
    }

    func startSync() async throws {
        syncCallCount += 1
        if shouldThrowError {
            throw MockError.syncFailed
        }
    }

    func stopSync() {
        // No-op for mock
    }

    func forceFetch() async throws {
        if shouldThrowError {
            throw MockError.fetchFailed
        }
    }

    enum MockError: Error {
        case syncFailed
        case fetchFailed
    }
}
```

### Migration Steps
1. Create protocol definitions for existing services
2. Update concrete implementations to conform to protocols
3. Create DIContainer with lazy service instantiation
4. Add environment key for SwiftUI injection
5. Update views to use `@Environment(\.diContainer)`
6. Create mock implementations
7. Update unit tests to use mocks
8. Remove singleton patterns from services
9. Update documentation (ARCHITECTURE.md)

### Testing Requirements
- Unit tests demonstrating mock injection
- Verify previews work with mock services
- Integration tests with real services still pass
- Performance test: ensure DI doesn't add significant overhead

### Related Files
- `/TTRPGCharacterSheets/Utilities/iCloudSyncManager.swift`
- `/TTRPGCharacterSheets/Utilities/PDFExportService.swift`
- `/TTRPGCharacterSheets/Utilities/WidgetImageRenderer.swift`
- `/TTRPGCharacterSheets/Views/CharacterEditorView.swift`
- `/TTRPGCharacterSheets/Views/PDFExportView.swift`
- `/TTRPGCharacterSheets/ARCHITECTURE.md`

### References
- [Swift Dependency Injection Patterns](https://www.swiftbysundell.com/articles/dependency-injection-using-the-factory-pattern/)
- [Point-Free Dependencies Library](https://github.com/pointfreeco/swift-dependencies)

---

## CODE-002: Drawing Data Compression
**Status:** 🔴 Not Started
**Priority:** Medium
**Effort:** 3-4 hours
**Category:** Performance, Storage Optimization

### Context
`PageDrawing.drawingData` stores PencilKit PKDrawing objects as uncompressed Data blobs. For character sheets with detailed maps, spell effects, or extensive notes, drawings can exceed 5-10MB per page. With multi-page PDFs (D&D character sheets are often 2-4 pages), this leads to:
- High storage usage (10+ characters = hundreds of MB)
- Slow iCloud sync (large data transfers)
- High memory footprint when loading multiple drawings
- Increased SwiftData database size

PencilKit drawing data is highly compressible (vector paths, metadata) and can achieve 60-80% size reduction with LZFSE compression.

### Acceptance Criteria
- [ ] Compression/decompression layer added to PageDrawing model
- [ ] Automatic migration for existing uncompressed drawings
- [ ] Compression algorithm benchmarked (LZFSE vs LZMA vs zlib)
- [ ] Drawing save/load performance impact measured (<10% overhead acceptable)
- [ ] iCloud sync bandwidth reduction verified (50%+ target)
- [ ] Unit tests for compression edge cases (empty drawings, corrupt data)

### Implementation Details

**Files to Modify:**
- `/TTRPGCharacterSheets/Models/PageDrawing.swift`

**Updated PageDrawing Model:**
```swift
import Foundation
import SwiftData
import PencilKit
import Compression

@Model
final class PageDrawing {
    var id: UUID
    var pageIndex: Int

    // MARK: - Compressed Storage

    /// Compressed drawing data using LZFSE algorithm
    /// - Note: Automatically compressed on write, decompressed on read
    @Attribute(.externalStorage)
    private var compressedDrawingData: Data

    /// Compression algorithm version for future migration
    private var compressionVersion: Int = 1

    @Relationship(deleteRule: .nullify, inverse: \Character.pageDrawings)
    var character: Character?

    // MARK: - Computed Property

    /// Transparently handles compression/decompression
    var drawing: PKDrawing {
        get {
            do {
                let decompressed = try compressedDrawingData.decompress(
                    using: .lzfse
                )
                return try PKDrawing(data: decompressed)
            } catch {
                print("⚠️ Failed to decompress drawing: \(error)")
                // Return empty drawing on corruption
                return PKDrawing()
            }
        }
        set {
            do {
                let rawData = newValue.dataRepresentation()
                compressedDrawingData = try rawData.compress(using: .lzfse)

                #if DEBUG
                let compressionRatio = Double(rawData.count) / Double(compressedDrawingData.count)
                print("📊 Drawing compressed: \(rawData.count) → \(compressedDrawingData.count) bytes (\(String(format: "%.1f", compressionRatio))x)")
                #endif
            } catch {
                print("⚠️ Failed to compress drawing: \(error)")
                // Fallback to uncompressed on error
                compressedDrawingData = newValue.dataRepresentation()
            }
        }
    }

    init(pageIndex: Int) {
        self.id = UUID()
        self.pageIndex = pageIndex
        self.compressedDrawingData = Data()
        self.compressionVersion = 1
    }
}

// MARK: - Compression Extensions

extension Data {
    enum CompressionAlgorithm {
        case lzfse
        case lzma
        case zlib
        case lz4

        var algorithm: compression_algorithm {
            switch self {
            case .lzfse: return COMPRESSION_LZFSE
            case .lzma: return COMPRESSION_LZMA
            case .zlib: return COMPRESSION_ZLIB
            case .lz4: return COMPRESSION_LZ4
            }
        }
    }

    func compress(using algorithm: CompressionAlgorithm = .lzfse) throws -> Data {
        var destinationBuffer = [UInt8](
            repeating: 0,
            count: count
        )

        let compressedSize = compression_encode_buffer(
            &destinationBuffer,
            destinationBuffer.count,
            [UInt8](self),
            count,
            nil,
            algorithm.algorithm
        )

        guard compressedSize > 0 else {
            throw CompressionError.encodingFailed
        }

        return Data(destinationBuffer[..<compressedSize])
    }

    func decompress(using algorithm: CompressionAlgorithm = .lzfse) throws -> Data {
        // Estimate decompressed size (assume 5x compression ratio)
        var destinationBuffer = [UInt8](
            repeating: 0,
            count: count * 5
        )

        let decompressedSize = compression_decode_buffer(
            &destinationBuffer,
            destinationBuffer.count,
            [UInt8](self),
            count,
            nil,
            algorithm.algorithm
        )

        guard decompressedSize > 0 else {
            throw CompressionError.decodingFailed
        }

        return Data(destinationBuffer[..<decompressedSize])
    }

    enum CompressionError: Error {
        case encodingFailed
        case decodingFailed
    }
}
```

**Migration for Existing Data:**
```swift
// Add to app startup (TTRPGCharacterSheetsApp.swift)
import SwiftData

@MainActor
func migrateUncompressedDrawings(context: ModelContext) async {
    let descriptor = FetchDescriptor<PageDrawing>()

    do {
        let allDrawings = try context.fetch(descriptor)
        var migratedCount = 0

        for drawing in allDrawings {
            // Check if already compressed (compressionVersion > 0)
            if drawing.compressionVersion == 0 {
                // Trigger compression by re-setting drawing
                let pkDrawing = drawing.drawing
                drawing.drawing = pkDrawing
                drawing.compressionVersion = 1
                migratedCount += 1
            }
        }

        if migratedCount > 0 {
            try context.save()
            print("✅ Migrated \(migratedCount) drawings to compressed format")
        }
    } catch {
        print("⚠️ Migration failed: \(error)")
    }
}
```

**Benchmarking Script (Tests/Performance/CompressionBenchmarks.swift):**
```swift
import XCTest
import PencilKit
@testable import TTRPGCharacterSheets

final class CompressionBenchmarks: XCTestCase {
    func testCompressionAlgorithmPerformance() throws {
        // Create sample drawing with various stroke types
        let drawing = createComplexDrawing()
        let rawData = drawing.dataRepresentation()

        measure {
            _ = try? rawData.compress(using: .lzfse)
        }

        // Compare algorithms
        let algorithms: [Data.CompressionAlgorithm] = [.lzfse, .lzma, .zlib, .lz4]
        for algorithm in algorithms {
            let compressed = try rawData.compress(using: algorithm)
            let ratio = Double(rawData.count) / Double(compressed.count)
            print("\(algorithm): \(compressed.count) bytes (\(String(format: "%.2f", ratio))x)")
        }
    }

    private func createComplexDrawing() -> PKDrawing {
        // Create drawing with 100 strokes
        // (Implementation details...)
        return PKDrawing()
    }
}
```

### Algorithm Selection Criteria

| Algorithm | Compression Ratio | Speed | Use Case |
|-----------|------------------|-------|----------|
| **LZFSE** | 3-5x | Fast | **Recommended** - Apple optimized |
| LZMA | 5-8x | Slow | Best compression, slower |
| zlib | 2-3x | Medium | Balanced |
| LZ4 | 1.5-2x | Very Fast | Low compression |

**Recommendation:** Use LZFSE for optimal balance on Apple hardware.

### Testing Requirements
- Unit tests:
  - Compress/decompress round-trip preserves drawing exactly
  - Empty drawing compression
  - Very large drawing (1000+ strokes)
  - Corrupt compressed data returns empty drawing
- Performance tests:
  - Measure compression/decompression time (target: <100ms for typical drawing)
  - Memory usage during compression
  - SwiftData save/load time impact
- Integration tests:
  - Verify iCloud sync works with compressed data
  - Migration of existing characters completes successfully

### Related Files
- `/TTRPGCharacterSheets/Models/PageDrawing.swift` (primary modification)
- `/TTRPGCharacterSheets/TTRPGCharacterSheetsApp.swift` (migration code)
- `/TTRPGCharacterSheets/Tests/Unit/PageDrawingModelTests.swift` (update tests)

### Performance Targets
- **Compression ratio:** 3-5x reduction in drawing size
- **Compression time:** <100ms for typical drawing (50KB raw)
- **iCloud sync improvement:** 50-70% bandwidth reduction
- **Storage savings:** 200MB → 50MB for typical library (10 characters)

### References
- [Apple Compression Framework](https://developer.apple.com/documentation/compression)
- [LZFSE Overview](https://github.com/lzfse/lzfse)
- [SwiftData External Storage](https://developer.apple.com/documentation/swiftdata/attribute/option/externalStorage)

---

# PRODUCT/UX IMPROVEMENTS

## UX-001: Smart Zoom for Stat Blocks
**Status:** 🔴 Not Started
**Priority:** High
**Effort:** 8-12 hours
**Category:** User Experience

### Context
Character sheets have dense stat blocks, skill lists, and spell tables with small text fields (often 8-10pt font). On iPad, accurately annotating these fields with Apple Pencil is difficult without zooming. Current workaround is manual pinch-to-zoom, which:
- Requires two-handed operation (one hand to zoom, one to draw)
- Interrupts drawing flow
- Doesn't remember zoom level per page
- Users often zoom to wrong region

**User Pain Point:** "I spend more time zooming and panning than actually filling out my character sheet."

### Acceptance Criteria
- [ ] Double-tap gesture on PDF region auto-zooms to that region
- [ ] Predefined zoom regions for common layouts (D&D 5e, Pathfinder)
- [ ] Zoom level persisted per page in PageDrawing model
- [ ] Smooth zoom animation (<300ms)
- [ ] Zoom regions configurable per template (future: ML-detected)
- [ ] Accessibility: VoiceOver announces zoom region

### Implementation Details

**User Flow:**
```
1. User opens character editor
2. User double-taps on "Skills" section
3. App zooms to skills region (2.5x scale, centered)
4. User annotates with Apple Pencil
5. User double-taps page background → zoom out to full page
6. Next time user opens this page → zoom level restored
```

**Files to Create/Modify:**
```
TTRPGCharacterSheets/
├── Models/
│   ├── PageDrawing.swift           # Add zoom state properties
│   └── ZoomRegion.swift            # New model
├── Views/
│   ├── CharacterEditorView.swift  # Add zoom gesture handling
│   └── SmartZoomOverlay.swift     # New overlay view
├── Utilities/
│   └── ZoomRegionDetector.swift   # Future ML implementation
└── Resources/
    └── ZoomPresets/
        ├── dnd-5e-character-sheet.json
        └── pathfinder-2e-sheet.json
```

**Updated PageDrawing Model (PageDrawing.swift):**
```swift
@Model
final class PageDrawing {
    // ... existing properties ...

    // MARK: - Zoom State

    /// Current zoom scale (1.0 = full page view)
    var zoomScale: Double = 1.0

    /// Current zoom center point (normalized 0-1 coordinates)
    var zoomCenterX: Double = 0.5
    var zoomCenterY: Double = 0.5

    /// Last active zoom region (if any)
    var activeZoomRegionID: String?
}
```

**Zoom Region Model (ZoomRegion.swift):**
```swift
import Foundation
import CoreGraphics

struct ZoomRegion: Codable, Identifiable {
    let id: String
    let name: String
    let rect: CGRect  // Normalized coordinates (0-1)
    let scale: Double
    let pageIndex: Int

    init(
        id: String,
        name: String,
        rect: CGRect,
        scale: Double = 2.5,
        pageIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.rect = rect
        self.scale = scale
        self.pageIndex = pageIndex
    }
}

// MARK: - Preset Regions

extension ZoomRegion {
    /// D&D 5e Character Sheet page 1 regions
    static let dnd5ePresets: [ZoomRegion] = [
        ZoomRegion(
            id: "dnd5e-header",
            name: "Character Info",
            rect: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 0.15),
            scale: 2.0,
            pageIndex: 0
        ),
        ZoomRegion(
            id: "dnd5e-stats",
            name: "Ability Scores",
            rect: CGRect(x: 0.0, y: 0.15, width: 0.2, height: 0.5),
            scale: 3.0,
            pageIndex: 0
        ),
        ZoomRegion(
            id: "dnd5e-skills",
            name: "Skills",
            rect: CGRect(x: 0.0, y: 0.65, width: 0.35, height: 0.35),
            scale: 2.5,
            pageIndex: 0
        ),
        ZoomRegion(
            id: "dnd5e-combat",
            name: "Combat Stats",
            rect: CGRect(x: 0.35, y: 0.15, width: 0.3, height: 0.3),
            scale: 2.5,
            pageIndex: 0
        ),
        ZoomRegion(
            id: "dnd5e-features",
            name: "Features & Traits",
            rect: CGRect(x: 0.65, y: 0.15, width: 0.35, height: 0.85),
            scale: 2.0,
            pageIndex: 0
        )
    ]
}
```

**Smart Zoom Overlay (SmartZoomOverlay.swift):**
```swift
import SwiftUI

struct SmartZoomOverlay: View {
    let regions: [ZoomRegion]
    let onRegionTap: (ZoomRegion) -> Void

    @State private var showRegionHints = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Region overlays (visible on long-press hint)
                ForEach(regions) { region in
                    RegionHighlight(
                        region: region,
                        size: geometry.size,
                        isVisible: showRegionHints
                    )
                    .onTapGesture(count: 2) {
                        onRegionTap(region)
                    }
                }
            }
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            // Long press shows zoom region hints
            withAnimation(.easeInOut(duration: 0.3)) {
                showRegionHints.toggle()
            }
        }
    }
}

struct RegionHighlight: View {
    let region: ZoomRegion
    let size: CGSize
    let isVisible: Bool

    var body: some View {
        let rect = denormalizeRect(region.rect, size: size)

        RoundedRectangle(cornerRadius: 8)
            .strokeBorder(Color.blue, lineWidth: 2)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
            .opacity(isVisible ? 1.0 : 0.0)
            .overlay(
                Text(region.name)
                    .font(.caption)
                    .padding(4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                    .position(x: rect.midX, y: rect.minY - 10)
                    .opacity(isVisible ? 1.0 : 0.0)
            )
    }

    private func denormalizeRect(_ normalized: CGRect, size: CGSize) -> CGRect {
        CGRect(
            x: normalized.minX * size.width,
            y: normalized.minY * size.height,
            width: normalized.width * size.width,
            height: normalized.height * size.height
        )
    }
}
```

**Updated CharacterEditorView (CharacterEditorView.swift):**
```swift
struct CharacterEditorView: View {
    @Bindable var character: Character
    @State private var currentPageIndex = 0
    @State private var zoomScale: CGFloat = 1.0
    @State private var zoomOffset: CGSize = .zero

    // Load zoom regions for character template
    private var zoomRegions: [ZoomRegion] {
        // TODO: Load from template configuration
        return ZoomRegion.dnd5ePresets.filter { $0.pageIndex == currentPageIndex }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // PDF + PencilKit layers
                pdfViewLayer
                    .scaleEffect(zoomScale)
                    .offset(zoomOffset)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: zoomScale)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: zoomOffset)

                // Smart zoom overlay
                SmartZoomOverlay(
                    regions: zoomRegions,
                    onRegionTap: { region in
                        zoomToRegion(region, in: geometry.size)
                    }
                )
            }
            .gesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        // Double-tap on background = reset zoom
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            zoomScale = 1.0
                            zoomOffset = .zero
                        }

                        // Save zoom state
                        saveZoomState()
                    }
            )
        }
        .onAppear {
            restoreZoomState()
        }
    }

    private func zoomToRegion(_ region: ZoomRegion, in size: CGSize) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            zoomScale = region.scale

            // Calculate offset to center region
            let normalizedCenter = CGPoint(
                x: region.rect.midX,
                y: region.rect.midY
            )
            let targetCenter = CGPoint(
                x: normalizedCenter.x * size.width,
                y: normalizedCenter.y * size.height
            )
            let viewCenter = CGPoint(x: size.width / 2, y: size.height / 2)

            zoomOffset = CGSize(
                width: (viewCenter.x - targetCenter.x) * zoomScale,
                height: (viewCenter.y - targetCenter.y) * zoomScale
            )
        }

        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        // Accessibility announcement
        UIAccessibility.post(
            notification: .announcement,
            argument: "Zoomed to \(region.name)"
        )

        saveZoomState(regionID: region.id)
    }

    private func saveZoomState(regionID: String? = nil) {
        guard let pageDrawing = character.pageDrawings.first(where: { $0.pageIndex == currentPageIndex }) else {
            return
        }

        pageDrawing.zoomScale = zoomScale
        pageDrawing.zoomCenterX = 0.5 - (zoomOffset.width / (zoomScale * UIScreen.main.bounds.width))
        pageDrawing.zoomCenterY = 0.5 - (zoomOffset.height / (zoomScale * UIScreen.main.bounds.height))
        pageDrawing.activeZoomRegionID = regionID
    }

    private func restoreZoomState() {
        guard let pageDrawing = character.pageDrawings.first(where: { $0.pageIndex == currentPageIndex }) else {
            return
        }

        zoomScale = pageDrawing.zoomScale

        // Restore offset from center coordinates
        let screenSize = UIScreen.main.bounds.size
        zoomOffset = CGSize(
            width: (0.5 - pageDrawing.zoomCenterX) * zoomScale * screenSize.width,
            height: (0.5 - pageDrawing.zoomCenterY) * zoomScale * screenSize.height
        )
    }
}
```

**Zoom Region Configuration (Resources/ZoomPresets/dnd-5e-character-sheet.json):**
```json
{
  "templateID": "dnd-5e-standard",
  "name": "D&D 5th Edition Character Sheet",
  "version": "1.0",
  "regions": [
    {
      "id": "header",
      "name": "Character Info",
      "pageIndex": 0,
      "rect": {
        "x": 0.0,
        "y": 0.0,
        "width": 1.0,
        "height": 0.15
      },
      "scale": 2.0
    },
    {
      "id": "ability-scores",
      "name": "Ability Scores",
      "pageIndex": 0,
      "rect": {
        "x": 0.0,
        "y": 0.15,
        "width": 0.2,
        "height": 0.5
      },
      "scale": 3.0
    }
  ]
}
```

### Future Enhancement: ML-Based Region Detection
```swift
// TODO: Phase 2 - Automatic region detection using Vision framework
import Vision

class ZoomRegionDetector {
    func detectRegions(in pdf: PDFDocument) async throws -> [ZoomRegion] {
        // Use VNRecognizeTextRequest to find text blocks
        // Cluster into semantic regions (headers, tables, lists)
        // Return detected regions
    }
}
```

### Testing Requirements
- Unit tests:
  - Zoom coordinate calculations (normalized ↔ screen coordinates)
  - Zoom state persistence in PageDrawing model
  - Region preset loading from JSON
- UI tests:
  - Double-tap zoom gesture recognition
  - Zoom animation smoothness (measure frame rate)
  - Zoom state restoration on page change
  - Accessibility: VoiceOver announcements
- Performance tests:
  - Zoom animation maintains 60 FPS
  - No memory leaks during repeated zoom operations

### UX Considerations
- **Gesture Conflicts:** Ensure double-tap doesn't interfere with Apple Pencil drawing (pencil touches should be ignored for zoom gesture)
- **Zoom Limits:** Min scale = 1.0 (full page), Max scale = 5.0 (prevent over-zoom)
- **Region Overlap:** If regions overlap, prioritize smaller (more specific) region
- **Feedback:** Haptic feedback on zoom, visual hint on long-press

### Related Files
- `/TTRPGCharacterSheets/Models/PageDrawing.swift`
- `/TTRPGCharacterSheets/Views/CharacterEditorView.swift`
- `/TTRPGCharacterSheets/Tests/UI/CharacterEditorUITests.swift`

### References
- [SwiftUI Gestures](https://developer.apple.com/documentation/swiftui/gestures)
- [Vision Framework Text Detection](https://developer.apple.com/documentation/vision/recognizing_text_in_images)

---

## UX-002: Collaborative Session Sharing (SharePlay)
**Status:** 🔴 Not Started
**Priority:** Low (Differentiator Feature)
**Effort:** 16-24 hours
**Category:** User Experience, Multiplayer

### Context
TTRPG sessions are inherently collaborative - Dungeon Masters need to see player character stats, players want to share their character sheets with the party, and remote play is increasingly common. Currently, users must:
- Manually export PDFs and share via iMessage/AirDrop
- Verbally communicate stats during gameplay
- Use separate screen sharing tools

**Opportunity:** No competitor offers real-time collaborative character sheet viewing on iPad. SharePlay integration would enable:
- DM views player sheets during FaceTime call
- Party members see each other's inventory
- Real-time annotation sync (DM marks damage, player sees it instantly)

**Use Case:** "During our weekly FaceTime D&D session, I want to share my character sheet with the DM so they can see my current HP and spell slots without me reading them aloud every turn."

### Acceptance Criteria
- [ ] SharePlay activity initiated from character editor
- [ ] Read-only view for remote participants (DM/other players)
- [ ] Real-time drawing synchronization (optional: host controls)
- [ ] Session invitation via FaceTime SharePlay picker
- [ ] Participant cursor indicators (show where others are looking)
- [ ] Session ends when FaceTime call ends or host stops sharing
- [ ] Privacy controls: choose which pages to share

### Implementation Details

**SharePlay Architecture:**
```
Host (Character Owner)
    ↓ GroupActivity
SharePlay Session
    ↓ Mesh Network
Participants (Read-Only)
```

**Files to Create:**
```
TTRPGCharacterSheets/
├── SharePlay/
│   ├── CharacterShareActivity.swift        # GroupActivity definition
│   ├── SharePlayCoordinator.swift          # Session management
│   ├── DrawingSyncMessage.swift            # Real-time sync protocol
│   └── ParticipantCursor.swift             # Cursor overlay
├── Views/
│   ├── SharePlayView.swift                 # Read-only participant view
│   └── SharePlayControls.swift             # Host controls
└── Entitlements.plist                      # Add com.apple.developer.group-session
```

**CharacterShareActivity (CharacterShareActivity.swift):**
```swift
import Foundation
import GroupActivities
import SwiftUI

struct CharacterShareActivity: GroupActivity {
    static let activityIdentifier = "com.ttrpg.character-share"

    // MARK: - Activity Metadata

    var metadata: GroupActivityMetadata {
        var metadata = GroupActivityMetadata()
        metadata.title = "Viewing \(characterName)"
        metadata.subtitle = template
        metadata.type = .generic
        metadata.previewImage = characterThumbnail
        metadata.fallbackURL = URL(string: "https://example.com/character/\(characterID)")
        return metadata
    }

    // MARK: - Character Data

    let characterID: UUID
    let characterName: String
    let template: String
    let characterThumbnail: CGImage?
    let sharedPageIndices: [Int]  // Which pages to share (privacy)

    init(
        characterID: UUID,
        characterName: String,
        template: String,
        thumbnail: CGImage?,
        sharedPages: [Int]
    ) {
        self.characterID = characterID
        self.characterName = characterName
        self.template = template
        self.characterThumbnail = thumbnail
        self.sharedPageIndices = sharedPages
    }
}

// MARK: - Drawing Sync Message

struct DrawingSyncMessage: Codable {
    let characterID: UUID
    let pageIndex: Int
    let drawingData: Data  // PKDrawing serialized
    let timestamp: Date
    let senderID: UUID

    enum MessageType: Codable {
        case fullSync       // Initial state
        case incrementalUpdate  // Stroke added/removed
        case cursorMove     // Participant cursor position
    }

    let type: MessageType
}

struct CursorPosition: Codable {
    let participantID: UUID
    let pageIndex: Int
    let x: Double
    let y: Double
    let timestamp: Date
}
```

**SharePlay Coordinator (SharePlayCoordinator.swift):**
```swift
import Foundation
import GroupActivities
import Combine

@MainActor
@Observable
class SharePlayCoordinator {
    // MARK: - Session State

    private(set) var session: GroupSession<CharacterShareActivity>?
    private(set) var messenger: GroupSessionMessenger?

    var isSharing: Bool { session != nil }
    var participants: [Participant] = []

    // MARK: - Subscriptions

    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Start Sharing

    func startSharing(character: Character, sharedPages: [Int]) async throws {
        // Create activity
        let activity = CharacterShareActivity(
            characterID: character.id,
            characterName: character.name,
            template: character.template?.name ?? "Unknown",
            thumbnail: nil,  // TODO: Generate thumbnail
            sharedPages: sharedPages
        )

        // Prepare for activation
        for await session in CharacterShareActivity.sessions() {
            // Configure session
            self.session = session
            self.messenger = GroupSessionMessenger(session: session)

            // Join session
            session.join()

            // Observe participants
            session.$activeParticipants
                .sink { [weak self] participants in
                    self?.participants = participants.map { participant in
                        Participant(id: participant.id)
                    }
                }
                .store(in: &subscriptions)

            // Listen for messages
            listenForMessages()

            // Send initial state to new participants
            try await sendFullSync(character: character, pages: sharedPages)

            return
        }
    }

    func stopSharing() {
        session?.leave()
        session = nil
        messenger = nil
        subscriptions.removeAll()
    }

    // MARK: - Messaging

    private func listenForMessages() {
        Task {
            guard let messenger = messenger else { return }

            for await (message, _) in messenger.messages(of: DrawingSyncMessage.self) {
                handleReceivedMessage(message)
            }
        }
    }

    func sendDrawingUpdate(
        character: Character,
        pageIndex: Int,
        drawing: PKDrawing
    ) async throws {
        guard let messenger = messenger else { return }

        let message = DrawingSyncMessage(
            characterID: character.id,
            pageIndex: pageIndex,
            drawingData: drawing.dataRepresentation(),
            timestamp: Date(),
            senderID: UUID(),  // TODO: Get local participant ID
            type: .incrementalUpdate
        )

        try await messenger.send(message)
    }

    private func sendFullSync(character: Character, pages: [Int]) async throws {
        guard let messenger = messenger else { return }

        for pageIndex in pages {
            guard let pageDrawing = character.pageDrawings.first(where: { $0.pageIndex == pageIndex }) else {
                continue
            }

            let message = DrawingSyncMessage(
                characterID: character.id,
                pageIndex: pageIndex,
                drawingData: pageDrawing.drawing.dataRepresentation(),
                timestamp: Date(),
                senderID: UUID(),
                type: .fullSync
            )

            try await messenger.send(message)
        }
    }

    private func handleReceivedMessage(_ message: DrawingSyncMessage) {
        // Update local view with remote changes
        // TODO: Implement in CharacterEditorView
        NotificationCenter.default.post(
            name: .drawingSyncReceived,
            object: message
        )
    }
}

extension Notification.Name {
    static let drawingSyncReceived = Notification.Name("drawingSyncReceived")
}

struct Participant: Identifiable {
    let id: UUID
}
```

**SharePlay View (SharePlayView.swift):**
```swift
import SwiftUI
import PencilKit

struct SharePlayView: View {
    let activity: CharacterShareActivity
    @State private var coordinator = SharePlayCoordinator()
    @State private var currentPageIndex = 0
    @State private var receivedDrawings: [Int: PKDrawing] = [:]

    var body: some View {
        VStack {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(activity.characterName)
                        .font(.title)
                    Text(activity.template)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(coordinator.participants.count) participants")
                    .font(.caption)
                    .padding(8)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding()

            // PDF + Drawing View (Read-Only)
            GeometryReader { geometry in
                ZStack {
                    // PDF background
                    // (TODO: Fetch PDF from host)

                    // Received drawings overlay
                    if let drawing = receivedDrawings[currentPageIndex] {
                        PKCanvasViewRepresentable(
                            drawing: .constant(drawing),
                            isUserInteractionEnabled: false
                        )
                    }

                    // Participant cursors
                    // (TODO: Show where other participants are looking)
                }
            }
        }
        .task {
            // Listen for drawing updates
            NotificationCenter.default.addObserver(
                forName: .drawingSyncReceived,
                object: nil,
                queue: .main
            ) { notification in
                guard let message = notification.object as? DrawingSyncMessage else {
                    return
                }

                do {
                    let drawing = try PKDrawing(data: message.drawingData)
                    receivedDrawings[message.pageIndex] = drawing
                } catch {
                    print("Failed to decode drawing: \(error)")
                }
            }
        }
    }
}
```

**Updated CharacterEditorView - Add SharePlay Button:**
```swift
struct CharacterEditorView: View {
    @State private var showSharePlaySheet = false
    @State private var shareCoordinator = SharePlayCoordinator()

    var body: some View {
        // ... existing view ...
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSharePlaySheet = true
                } label: {
                    Label("Share via SharePlay", systemImage: "shareplay")
                }
            }
        }
        .sheet(isPresented: $showSharePlaySheet) {
            SharePlayConfigurationView(
                character: character,
                onStart: { selectedPages in
                    Task {
                        try await shareCoordinator.startSharing(
                            character: character,
                            sharedPages: selectedPages
                        )
                    }
                }
            )
        }
        .onChange(of: currentPageDrawing?.drawing) { _, newDrawing in
            // Sync drawing changes to SharePlay participants
            if shareCoordinator.isSharing {
                Task {
                    try await shareCoordinator.sendDrawingUpdate(
                        character: character,
                        pageIndex: currentPageIndex,
                        drawing: newDrawing ?? PKDrawing()
                    )
                }
            }
        }
    }
}
```

**Entitlements Update (TTRPGCharacterSheets.entitlements):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing entitlements -->

    <!-- Add SharePlay / GroupActivities -->
    <key>com.apple.developer.group-session</key>
    <true/>
</dict>
</plist>
```

### Implementation Phases

**Phase 1: Basic SharePlay Integration (8 hours)**
- GroupActivity definition
- Session management (start/stop sharing)
- Read-only participant view with static PDF
- Basic UI for starting SharePlay session

**Phase 2: Real-Time Drawing Sync (6 hours)**
- Drawing sync protocol
- Incremental update messaging
- Conflict resolution (host wins)
- Performance optimization (delta compression)

**Phase 3: Enhanced UX (6 hours)**
- Participant cursor indicators
- Page selection (privacy controls)
- Haptic feedback on participant join/leave
- Session quality indicators (latency, packet loss)

**Phase 4: Advanced Features (Future)**
- Bidirectional drawing (allow participants to annotate)
- Voice chat integration (FaceTime Audio API)
- Session recording/playback
- Multi-character sessions (view entire party)

### Testing Requirements
- Unit tests:
  - GroupActivity serialization
  - Message encoding/decoding
  - Participant list updates
- Integration tests:
  - Two-device SharePlay session (requires physical devices)
  - Drawing sync latency measurement
  - Session persistence across FaceTime interruptions
- UI tests:
  - SharePlay flow (start → share → participants join → stop)
  - Privacy controls (page selection)

### Privacy & Security Considerations
- **Data Minimization:** Only share selected pages, not entire character
- **Encryption:** All SharePlay messages encrypted by iOS (end-to-end)
- **Consent:** Host explicitly starts sharing, can stop anytime
- **Read-Only Default:** Participants can't modify unless host grants permission
- **Audit Log:** Record who viewed character and when (optional)

### Performance Targets
- **Message Latency:** <100ms for drawing updates
- **Frame Rate:** Maintain 60 FPS during real-time sync
- **Bandwidth:** <50 KB/s per participant (aggressive delta compression)
- **Battery Impact:** <5% additional drain during 1-hour session

### Related Files
- New: `/TTRPGCharacterSheets/SharePlay/` (entire directory)
- Modify: `/TTRPGCharacterSheets/Views/CharacterEditorView.swift`
- Modify: `/TTRPGCharacterSheets/TTRPGCharacterSheets.entitlements`
- Update: `/TTRPGCharacterSheets/Info.plist` (NSGroupSessionUsageDescription)

### References
- [GroupActivities Framework](https://developer.apple.com/documentation/groupactivities)
- [SharePlay WWDC Videos](https://developer.apple.com/videos/play/wwdc2021/10183/)
- [Building Collaborative Experiences](https://developer.apple.com/documentation/groupactivities/building-a-collaborative-experience)

---

# IMPLEMENTATION NOTES FOR AI AGENTS

## General Guidelines

### Before Starting Any Task
1. **Read Related Files:** Use Read tool on all files listed in "Related Files"
2. **Check Dependencies:** Verify required frameworks/libraries are available
3. **Review Existing Patterns:** Match code style, naming conventions (see CONTRIBUTING.md)
4. **Run Tests First:** Ensure baseline passes before making changes
5. **Create Feature Branch:** `git checkout -b feature/TASK-ID-description`

### During Implementation
1. **Follow SwiftLint Rules:** Run `swiftlint` frequently (config: .swiftlint.yml)
2. **Add MARK Comments:** Organize code with `// MARK: - Section Name`
3. **Write Tests First:** TDD preferred - write failing test, then implement
4. **Commit Atomically:** One logical change per commit
5. **Update Documentation:** Modify ARCHITECTURE.md or README.md if architecture changes

### After Implementation
1. **Run Full Test Suite:** `swift test` must pass 100%
2. **Verify Accessibility:** Run accessibility-audit workflow
3. **Performance Benchmark:** Compare before/after metrics
4. **Update Roadmap:** Mark task as 🟢 Completed, add completion date
5. **Create Pull Request:** Use PR template, request review

### Code Style (Swift)
- **Indentation:** 4 spaces (no tabs)
- **Line Length:** Max 120 characters (warning), 150 (error)
- **Naming:**
  - Types: PascalCase (`CharacterEditorView`)
  - Functions/vars: camelCase (`saveDrawing()`)
  - Constants: camelCase (`maxZoomScale`)
- **Access Control:** Prefer `private` unless needed externally
- **SwiftUI:** Use `@State`, `@Binding`, `@Observable` appropriately
- **Async/Await:** Prefer over closures for async operations

### Testing Strategy
```swift
// Unit Test Structure
final class FeatureTests: XCTestCase {
    var sut: SystemUnderTest!

    override func setUp() async throws {
        sut = SystemUnderTest()
    }

    override func tearDown() async throws {
        sut = nil
    }

    func testFeature_whenCondition_thenExpectedBehavior() async throws {
        // Given
        let input = ...

        // When
        let result = await sut.performAction(input)

        // Then
        XCTAssertEqual(result, expectedValue)
    }
}
```

### Common Pitfalls
- ❌ Don't use force unwrapping (`!`) - use guard/if-let
- ❌ Don't create singletons (except DIContainer)
- ❌ Don't commit commented-out code
- ❌ Don't hardcode file paths (use `FileManager` or `AppGroupContainer`)
- ❌ Don't skip accessibility labels on custom UI

---

## Project Context

### SwiftData Persistence
```swift
// Fetching models
let descriptor = FetchDescriptor<Character>(
    predicate: #Predicate { $0.isFavorite == true },
    sortBy: [SortDescriptor(\.dateModified, order: .reverse)]
)
let characters = try context.fetch(descriptor)

// Inserting
context.insert(newCharacter)
try context.save()

// Deleting
context.delete(character)
try context.save()
```

### App Groups (Main App ↔ Widget)
```swift
// Shared container
let sharedContainer = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.ttrpg.charactersheets"
)
```

### PencilKit Drawing
```swift
// Save drawing
let drawingData = pkDrawing.dataRepresentation()
pageDrawing.drawingData = drawingData

// Load drawing
let pkDrawing = try PKDrawing(data: pageDrawing.drawingData)
canvasView.drawing = pkDrawing
```

---

## Task Estimation Guide

| Task Complexity | Estimated Hours | Example |
|-----------------|-----------------|---------|
| Trivial | 1-2 | Add property to model |
| Simple | 2-4 | Add button with action |
| Moderate | 4-8 | New view with SwiftUI |
| Complex | 8-16 | New feature with tests |
| Very Complex | 16-24+ | Major architecture change |

---

## Success Criteria Checklist

Before marking any task complete, verify:

- [ ] All acceptance criteria met
- [ ] Unit tests pass (if applicable)
- [ ] UI tests pass (if UI change)
- [ ] SwiftLint passes with 0 warnings
- [ ] Accessibility verified (VoiceOver labels, contrast)
- [ ] Documentation updated (inline comments, ARCHITECTURE.md)
- [ ] Performance benchmarked (if relevant)
- [ ] No force unwraps or unsafe code
- [ ] Git commit messages follow convention
- [ ] Pull request created with screenshots (if UI change)

---

## Contact & Support

- **Repository:** https://github.com/kocheck/Paper
- **Documentation:** See `/TTRPGCharacterSheets/ARCHITECTURE.md`
- **Questions:** Open GitHub Discussion or create issue with `question` label

---

**End of Roadmap** | Last updated: 2026-01-04
