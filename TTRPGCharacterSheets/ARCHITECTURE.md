# Architecture Guide

## Overview

This document provides a detailed overview of the TTRPG Character Sheets app architecture, design decisions, and implementation patterns.

## Table of Contents

1. [Architectural Pattern](#architectural-pattern)
2. [Data Layer](#data-layer)
3. [View Layer](#view-layer)
4. [Integration Layer](#integration-layer)
5. [State Management](#state-management)
6. [Performance Considerations](#performance-considerations)
7. [Testing Strategy](#testing-strategy)

---

## Architectural Pattern

### MVVM (Model-View-ViewModel)

The app follows the MVVM architecture pattern, which provides clear separation of concerns:

```
┌─────────────────────────────────────────┐
│              View Layer                  │
│  (SwiftUI Views - User Interface)       │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│          ViewModel Layer                 │
│  (Business Logic & State)                │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│           Model Layer                    │
│  (SwiftData Models - Data & Persistence)│
└─────────────────────────────────────────┘
```

### Why MVVM?

- **Testability**: Business logic in ViewModels can be unit tested without UI
- **Separation**: Clear boundaries between UI, logic, and data
- **SwiftUI Integration**: Natural fit with SwiftUI's reactive paradigm
- **Maintainability**: Changes in one layer don't cascade to others

### ViewModels

#### CharacterEditorViewModel

The `CharacterEditorViewModel` manages the state and business logic for the character editor:

```swift
@MainActor
@Observable
final class CharacterEditorViewModel {
    // State
    var currentPageIndex: Int
    var pdfDocument: PDFDocument?
    var hasUnsavedChanges: Bool
    var canUndo: Bool
    var canRedo: Bool

    // Actions
    func loadPDF()
    func navigateToPage(_ index: Int) -> Bool
    func undo()
    func redo()
    func saveAndDismiss(onDismiss: () -> Void)
}
```

**Key Features:**
- **Page Navigation**: Centralized page index management with validation
- **Undo/Redo**: Integration with PencilKit's UndoManager
- **State Restoration**: Automatic saving of last viewed page
- **PDF Loading**: Asynchronous PDF document initialization
- **Dependency Injection**: Accepts dependencies for testability

**Environment Injection:**
```swift
// Inject into environment
.environment(\.characterEditorViewModel, viewModel)

// Access in child views
@Environment(\.characterEditorViewModel) private var viewModel
```

---

## Data Layer

### SwiftData Models

#### Template
```swift
@Model
final class Template {
    var id: UUID
    var name: String
    var pdfData: Data  // @Attribute(.externalStorage)
    var pageCount: Int
    var thumbnailData: Data?
    var characters: [Character]  // One-to-many
}
```

**Design Decisions:**
- `pdfData` uses external storage to avoid database bloat
- Thumbnail generated on import for quick library display
- Cascade delete to characters (removing template removes all instances)

#### Character
```swift
@Model
final class Character {
    var id: UUID
    var name: String
    var template: Template?  // Many-to-one
    var pageDrawings: [PageDrawing]  // One-to-many
    var lastViewedPageIndex: Int  // State restoration
    var isFavorite: Bool
}
```

**Design Decisions:**
- Optional template reference (allows orphan characters)
- `lastViewedPageIndex` for seamless state restoration
- Cascade delete to pageDrawings

#### PageDrawing
```swift
@Model
final class PageDrawing {
    var id: UUID
    var pageIndex: Int
    var drawingData: Data  // @Attribute(.externalStorage)
    var character: Character?  // Many-to-one
}
```

**Design Decisions:**
- Separate drawing per page for efficient loading
- External storage for large PKDrawing data
- Serializes `PKDrawing` to `Data` for persistence

### Entity Relationships

```
Template ─┬─< Character ─┬─< PageDrawing
          │               │
          │               └─> pageIndex: Int
          │                   drawingData: Data
          │
          └─> pdfData: Data
              pageCount: Int
```

### Data Flow

1. **Import Template**: PDF → Data → SwiftData
2. **Create Character**: User Input → Character Model → SwiftData
3. **Draw on Canvas**: PKDrawing → PageDrawing.drawingData → SwiftData
4. **Load Character**: SwiftData → Character → PDF + Drawings → UI

---

## View Layer

### View Hierarchy

```
TTRPGCharacterSheetsApp
└── MainLibraryView
    ├── CharacterCardView (repeated)
    ├── ImportTemplateView (sheet)
    ├── CreateCharacterView (sheet)
    ├── TemplateLibraryView (sheet)
    └── CharacterEditorView (fullScreenCover)
        └── PagedPDFCanvasView
            └── PDFCanvasPageView (repeated)
                ├── PDFPageView (background)
                └── PencilKitCanvasView (overlay)
```

### Key Views

#### MainLibraryView
- **Purpose**: Character library with grid layout
- **State**: `@Query` for Characters and Templates
- **Navigation**: Sheets for creation, fullScreenCover for editing
- **Features**: Search, favorites, context menus

#### CharacterEditorView
- **Purpose**: Main editing workspace
- **State**: `@Bindable var character: Character`
- **Integration**: PDFKit + PencilKit overlay
- **Features**: Multi-page, auto-save, state restoration

#### PDFCanvasPageView
- **Purpose**: Single page with PDF background and drawing overlay
- **Pattern**: ZStack with layers
- **Performance**: Per-page lazy loading

---

## Integration Layer

### PDFKit + PencilKit Integration

The core innovation of this app is layering PencilKit over PDFKit:

```swift
ZStack {
    // Layer 1: PDF Background (read-only)
    PDFPageView(page: pdfPage)
        .background(Color.white)

    // Layer 2: PencilKit Canvas (interactive)
    PencilKitCanvasView(...)
        .backgroundColor(.clear)
        .isOpaque(false)
}
```

**Key Challenges & Solutions:**

1. **Coordinate System Mismatch**
   - Problem: PDFKit uses flipped Y-axis
   - Solution: Transform context in PDFPageView.draw(_:)

2. **Touch Handling**
   - Problem: Both views want touch events
   - Solution: PencilKit canvas set to `.allowsFingerDrawing = false`

3. **Drawing Alignment**
   - Problem: Drawings must align perfectly with PDF
   - Solution: Both views use same frame, scale PDF to fit

### PencilKit Integration Details

```swift
class PKCanvasView {
    var drawing: PKDrawing  // Main drawing data
    var delegate: PKCanvasViewDelegate  // Drawing change notifications
    var allowsFingerDrawing: Bool  // Pencil-only mode
    var drawingPolicy: PKCanvasViewDrawingPolicy  // Input policy
}
```

**Implementation:**
- `PKCanvasView` wrapped in `UIViewRepresentable`
- Drawing changes trigger auto-save via delegate
- Tool picker automatically shows when canvas is first responder

---

## State Management

### App-Level State

```swift
@AppStorage("lastViewedCharacterID") var lastViewedCharacterID: String?

class StateRestorationManager: ObservableObject {
    @Published var characterToRestore: UUID?
    @Published var pageIndexToRestore: Int
}
```

### View-Level State

- `@Query`: Automatic SwiftData queries (reactive)
- `@State`: View-local state (UI-only)
- `@Bindable`: Two-way binding to SwiftData models
- `@Environment(\.modelContext)`: SwiftData context access

### State Restoration Flow

1. User edits character on page 3
2. App saves: `characterID` + `pageIndex` to UserDefaults
3. App terminates (iOS kills it in background)
4. User reopens app
5. App reads UserDefaults → finds `characterID`
6. App opens CharacterEditorView with that character
7. Editor navigates to page 3

---

## Performance Considerations

### Optimizations

1. **External Storage**
   ```swift
   @Attribute(.externalStorage) var pdfData: Data
   @Attribute(.externalStorage) var drawingData: Data
   ```
   - Keeps database small
   - Efficient for large binary data

2. **Lazy Loading**
   - Drawings loaded per-page, not all at once
   - PDF pages rendered on-demand by PDFKit

3. **Thumbnail Caching**
   - Generated once on import
   - Stored in template for quick library display

4. **Auto-Save Debouncing**
   ```swift
   Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
       saveDrawing()
   }
   ```
   - Prevents excessive saves during active drawing
   - Balances data safety with performance

### Memory Management

- SwiftData handles model lifecycle
- PDFKit uses internal caching for pages
- PencilKit drawings cleared when page changes
- No strong reference cycles (checked via Instruments)

---

## Testing Strategy

### Unit Tests (Models & Logic)

**Template:** 15+ tests
- Initialization
- Persistence
- Relationships
- Computed properties
- Cascade deletes

**Character:** 20+ tests
- CRUD operations
- Page drawing management
- State updates
- Template relationships

**PageDrawing:** 15+ tests
- PencilKit integration
- Data serialization
- Content detection
- External storage

### UI Tests (User Flows)

**CharacterCreationUITests:** 10+ tests
- Template import flow
- Character creation
- Form validation
- Navigation

**CharacterEditorUITests:** 15+ tests
- Editor launch
- Page navigation
- Tool picker
- State restoration
- Performance metrics

### Testing Philosophy

- **Unit Tests**: Fast, isolated, test business logic
- **UI Tests**: Slower, end-to-end, test critical user paths
- **Coverage Goal**: 80%+ for models, 60%+ for views
- **TDD**: Write tests first for new features

---

## Design Patterns

### Patterns Used

1. **Repository Pattern**
   - SwiftData acts as repository
   - Models encapsulate data access

2. **Delegate Pattern**
   - PKCanvasViewDelegate for drawing changes
   - Clean separation of concerns

3. **Coordinator Pattern**
   - StateRestorationManager coordinates state
   - Centralized state restoration logic

4. **Factory Pattern**
   - `createPageDrawingIfNeeded(for:)` creates on-demand
   - Ensures single PageDrawing per page

5. **Observer Pattern**
   - `@Published` properties in StateRestorationManager
   - SwiftUI automatically observes changes

---

## File Organization

```
TTRPGCharacterSheets/
├── Models/                    # Data layer
│   ├── Template.swift
│   ├── Character.swift
│   └── PageDrawing.swift
├── Views/                     # UI layer
│   ├── MainLibraryView.swift
│   ├── CharacterEditorView.swift
│   └── ...
├── ViewModels/                # Business logic layer
│   └── CharacterEditorViewModel.swift
├── Utilities/                 # Helpers & extensions
├── Resources/                 # Assets
└── Tests/
    ├── Unit/                  # Model tests
    ├── UI/                    # Flow tests
    └── Performance/           # Performance benchmarks
        ├── PDFRenderingPerformanceTests.swift
        ├── DrawingSaveLoadPerformanceTests.swift
        └── PaginationPerformanceTests.swift
```

### File Naming Conventions

- **Models**: `{Entity}.swift` (e.g., `Character.swift`)
- **Views**: `{Purpose}View.swift` (e.g., `MainLibraryView.swift`)
- **Tests**: `{What}Tests.swift` (e.g., `CharacterModelTests.swift`)

---

## Testing Strategy

### Test Categories

1. **Unit Tests** (`Tests/Unit/`)
   - Model validation and relationships
   - Business logic in ViewModels
   - Data transformation utilities
   - Coverage: ~85% of models and ViewModels

2. **UI Tests** (`Tests/UI/`)
   - User flow validation
   - State restoration verification
   - Navigation and gestures
   - Accessibility compliance

3. **Performance Tests** (`Tests/Performance/`)
   - PDF rendering benchmarks
   - Drawing save/load performance
   - Pagination and navigation speed
   - Memory usage profiling

**Performance Baselines:**
- PDF load (2-page sheet): < 100ms
- Drawing save (50 strokes): < 50ms
- Page navigation: < 16ms (60 FPS target)

### Performance Testing Infrastructure

Performance tests use XCTest metrics to track regressions:

```swift
func testPDFRenderingPerformance() throws {
    measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
        _ = PDFDocument(data: samplePDFData)
    }
}
```

**CI/CD Integration:**
- Automated on every PR (`.github/workflows/pr-quality.yml`)
- Fails PR if performance regresses > 20%
- Tracks trends over time

---

## Recent Architectural Enhancements

### ✅ Completed Improvements

1. **ViewModels** (2026-01-04)
   - ✅ CharacterEditorViewModel implemented
   - ✅ Extracted business logic from views
   - ✅ Environment-based injection pattern
   - ✅ Improved testability

2. **Undo/Redo System** (2026-01-04)
   - ✅ Integration with PencilKit UndoManager
   - ✅ Keyboard shortcuts (⌘Z, ⌘⇧Z)
   - ✅ Toolbar buttons with state management
   - ✅ Per-page undo stack preservation

3. **Performance Testing** (2026-01-04)
   - ✅ Comprehensive benchmark suite
   - ✅ PDF rendering, drawing, pagination tests
   - ✅ CI/CD integration
   - ✅ Baseline tracking

### Future Architectural Enhancements

#### Planned Improvements

1. **Dependency Injection Container**
   - Protocol abstractions for services
   - Mock implementations for testing
   - See: `ROADMAP.md#CODE-001`

2. **Repository Layer**
   - Abstract SwiftData behind protocols
   - Easier to swap persistence layer

3. **Coordinator Pattern**
   - Navigation coordinator
   - Decouple navigation from views

4. **Service Layer Refactoring**
   - DI-based service injection
   - iCloudSyncProtocol, PDFExportProtocol
   - See: `ROADMAP.md` for details

---

## Conclusion

This architecture prioritizes:
- **Simplicity**: Clear, understandable code
- **Testability**: Comprehensive test coverage
- **Performance**: Efficient data handling
- **Maintainability**: Easy to extend and modify
- **SwiftUI-Native**: Leverages platform strengths

The architecture is designed to scale with future features while maintaining code quality and developer productivity.
