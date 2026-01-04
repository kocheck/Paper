# macOS Companion App Architecture

## Overview

This document outlines the architecture for a macOS companion app for TTRPG Character Sheets. The macOS app will share the same data models and business logic with the iPadOS app while providing a Mac-optimized user experience.

## Table of Contents

1. [Project Structure](#project-structure)
2. [Shared Code Architecture](#shared-code-architecture)
3. [Platform-Specific Implementations](#platform-specific-implementations)
4. [User Interface Adaptations](#user-interface-adaptations)
5. [Input Handling](#input-handling)
6. [iCloud Sync](#icloud-sync)
7. [Build Configuration](#build-configuration)

---

## Project Structure

### Recommended Multi-Platform Setup

```
TTRPGCharacterSheets/
├── Shared/                          # Shared between iOS and macOS
│   ├── Models/
│   │   ├── Template.swift
│   │   ├── Character.swift
│   │   └── PageDrawing.swift
│   ├── Utilities/
│   │   ├── PDFExportService.swift
│   │   ├── iCloudSyncManager.swift
│   │   └── UserPreferences.swift
│   └── ViewModels/                  # Business logic
│       ├── CharacterListViewModel.swift
│       └── CharacterEditorViewModel.swift
├── iOS/                             # iPadOS-specific
│   ├── Views/
│   │   ├── MainLibraryView.swift
│   │   ├── CharacterEditorView.swift
│   │   └── PageCurlView.swift
│   ├── Info.plist
│   └── Assets.xcassets
├── macOS/                           # macOS-specific
│   ├── Views/
│   │   ├── MacMainLibraryView.swift
│   │   ├── MacCharacterEditorView.swift
│   │   └── MacSidebarView.swift
│   ├── Info.plist
│   └── Assets.xcassets
└── Tests/
    ├── SharedTests/
    ├── iOSTests/
    └── macOSTests/
```

---

## Shared Code Architecture

### 1. Data Models (100% Shared)

All SwiftData models are identical across platforms:

```swift
// Models/Template.swift
@Model
final class Template {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var pdfData: Data
    var pageCount: Int
    var characters: [Character]

    // Platform-agnostic
}
```

**Why Shared:**
- Ensures data consistency
- Single source of truth
- iCloud sync compatibility

### 2. Business Logic (90% Shared)

Extract business logic into ViewModels:

```swift
// Shared/ViewModels/CharacterEditorViewModel.swift
@Observable
final class CharacterEditorViewModel {
    var character: Character
    var currentPageIndex: Int = 0
    var hasUnsavedChanges: Bool = false

    func saveDrawing(_ drawing: PKDrawing, for pageIndex: Int) {
        // Platform-agnostic saving logic
    }

    func navigateToPage(_ index: Int) {
        // Platform-agnostic navigation logic
    }
}
```

**Benefits:**
- Testable business logic
- Reduced code duplication
- Easier maintenance

### 3. Utilities (100% Shared)

All utility services are platform-independent:

- `PDFExportService` - PDF rendering logic
- `iCloudSyncManager` - CloudKit integration
- `UserPreferences` - Settings management

---

## Platform-Specific Implementations

### iPadOS Unique Features

1. **Apple Pencil**
   - PencilKit with pressure sensitivity
   - Double-tap tool switching
   - Scribble support

2. **Touch Gestures**
   - Multi-touch gestures
   - Page curl animation
   - Swipe navigation

3. **Compact UI**
   - Full-screen editing
   - Modal sheets
   - Bottom toolbars

### macOS Unique Features

1. **Mouse/Trackpad Input**
   - Precision cursor
   - Right-click context menus
   - Hover states

2. **Keyboard Shortcuts**
   - Command-based shortcuts
   - Menu bar integration
   - Quick actions

3. **Window Management**
   - Resizable windows
   - Multiple windows support
   - Sidebar navigation

4. **Menu Bar**
   - File menu (New, Open, Save, Export)
   - Edit menu (Undo, Redo, Copy, Paste)
   - View menu (Zoom, Layout options)
   - Window menu (Minimize, Zoom)

---

## User Interface Adaptations

### 1. Main Library View

#### iPadOS
```swift
// iOS/Views/MainLibraryView.swift
struct MainLibraryView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: adaptiveColumns) {
                    // Character cards
                }
            }
            .toolbar {
                // Top toolbar with settings, templates
            }
        }
    }
}
```

#### macOS
```swift
// macOS/Views/MacMainLibraryView.swift
struct MacMainLibraryView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar: Templates, Characters, Favorites
            MacSidebarView()
        } detail: {
            // Main content: Grid or List view
            MacCharacterGridView()
        }
        .toolbar {
            // macOS-style toolbar with search
        }
    }
}
```

**Key Differences:**
- iPadOS: NavigationStack with full-screen sheets
- macOS: NavigationSplitView with sidebar

### 2. Character Editor

#### iPadOS
```swift
struct CharacterEditorView: View {
    var body: some View {
        ZStack {
            // Full-screen PDF + PencilKit
            if usePageCurl {
                PageCurlView(...)
            } else {
                TabView(...)
            }
        }
        .toolbar {
            // Bottom toolbar for page navigation
        }
    }
}
```

#### macOS
```swift
struct MacCharacterEditorView: View {
    var body: some View {
        HSplitView {
            // Left: Page thumbnails
            MacPageThumbnailList()
                .frame(width: 200)

            // Center: PDF + Drawing canvas
            MacPDFCanvasView()

            // Right: Tools inspector (optional)
            MacToolsInspector()
                .frame(width: 250)
        }
        .toolbar {
            // Top toolbar with zoom, tools
        }
    }
}
```

**Key Differences:**
- iPadOS: Full-screen, gesture-based
- macOS: Split view with side panels

---

## Input Handling

### PencilKit vs Mouse Drawing

#### iPadOS (PencilKit)
```swift
let canvas = PKCanvasView()
canvas.drawingPolicy = .anyInput
canvas.allowsFingerDrawing = false  // Pencil only
canvas.tool = PKInkingTool(.pen, color: .black, width: 5)
```

#### macOS (PencilKit with Mouse)
```swift
let canvas = PKCanvasView()
canvas.drawingPolicy = .anyInput
canvas.allowsFingerDrawing = true  // Allow mouse/trackpad
canvas.tool = PKInkingTool(.pen, color: .black, width: 2) // Thinner for precision

// Add hover effect for cursor
canvas.addCursorRect(canvas.bounds, cursor: .crosshair)
```

### Keyboard Shortcuts (macOS Only)

```swift
struct MacCharacterEditorView: View {
    var body: some View {
        content
            .onCommand(#selector(NSResponder.undo(_:))) {
                viewModel.undo()
            }
            .onCommand(#selector(NSResponder.redo(_:))) {
                viewModel.redo()
            }
            .keyboardShortcut("e", modifiers: [.command]) {
                viewModel.toggleEraser()
            }
            .keyboardShortcut("]", modifiers: [.command]) {
                viewModel.nextPage()
            }
            .keyboardShortcut("[", modifiers: [.command]) {
                viewModel.previousPage()
            }
    }
}
```

**Common Shortcuts:**
- `⌘N` - New character
- `⌘O` - Open character
- `⌘S` - Save (auto-save, for user feedback)
- `⌘E` - Export PDF
- `⌘Z` - Undo
- `⌘⇧Z` - Redo
- `⌘[` / `⌘]` - Previous/Next page
- `Space` - Pan tool (hold)
- `⌘+` / `⌘-` - Zoom in/out

---

## iCloud Sync

### Cross-Platform Sync

Both apps use the same CloudKit container:

```swift
// Shared/Utilities/iCloudSyncManager.swift
static func createiCloudModelContainer() throws -> ModelContainer {
    let schema = Schema([
        Template.self,
        Character.self,
        PageDrawing.self
    ])

    let iCloudConfig = ModelConfiguration(
        schema: schema,
        cloudKitDatabase: .private("iCloud.com.ttrpgcharactersheets")
    )

    return try ModelContainer(for: schema, configurations: [iCloudConfig])
}
```

**Sync Behavior:**
1. User creates character on iPad
2. SwiftData syncs to iCloud automatically
3. macOS app receives CloudKit notification
4. Model updates automatically via SwiftData
5. UI refreshes with @Query reactive binding

### Conflict Resolution

```swift
// Handle conflicts when same character edited on both devices
enum ConflictResolution {
    case newerWins      // Use modification date
    case manualReview   // Prompt user
    case localWins      // Keep local version
    case remoteWins     // Keep cloud version
}
```

---

## Build Configuration

### Xcode Project Setup

#### Targets

1. **TTRPGCharacterSheets (iOS)**
   - Deployment Target: iPadOS 17.0
   - Supported Devices: iPad only
   - Requires: Apple Pencil support

2. **TTRPGCharacterSheets (macOS)**
   - Deployment Target: macOS 14.0 (Sonoma)
   - Supported Architectures: Apple Silicon + Intel
   - Requires: CloudKit capability

#### Shared Framework (Optional)

```swift
// Create a shared framework for common code
TTRPGCharacterSheetsCore.framework
├── Models/
├── ViewModels/
└── Utilities/

// Link to both iOS and macOS targets
```

#### Capabilities Required

**Both Platforms:**
- iCloud (CloudKit)
- Background Modes (Remote notifications for sync)

**iPadOS Only:**
- Apple Pencil interaction

**macOS Only:**
- App Sandbox
- File access (User Selected File - Read/Write)
- Network (for iCloud)

### Info.plist Differences

#### iPadOS
```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>arm64</string>
</array>
<key>NSApplePencilPreferred</key>
<true/>
<key>UIRequiresFullScreen</key>
<false/>
```

#### macOS
```xml
<key>LSMinimumSystemVersion</key>
<string>14.0</string>
<key>NSSupportsAutomaticGraphicsSwitching</key>
<true/>
```

---

## Development Workflow

### Step-by-Step Implementation

#### Phase 1: Setup (1-2 days)
1. Create multi-platform Xcode project
2. Set up shared framework or folder references
3. Configure build targets
4. Enable iCloud capabilities

#### Phase 2: Shared Code (3-5 days)
1. Move models to shared location
2. Extract ViewModels from Views
3. Ensure all utilities are platform-agnostic
4. Write shared unit tests

#### Phase 3: macOS UI (5-7 days)
1. Create MacMainLibraryView with sidebar
2. Implement MacCharacterEditorView with split view
3. Add keyboard shortcuts
4. Implement menu bar commands

#### Phase 4: Input Adaptation (2-3 days)
1. Configure PencilKit for mouse input
2. Add hover states
3. Implement right-click context menus
4. Test drawing precision

#### Phase 5: Testing & Polish (3-5 days)
1. Test iCloud sync between devices
2. Test conflict resolution
3. Performance optimization
4. UI/UX refinements

**Total Estimate: 14-22 days**

---

## UI/UX Design Principles

### macOS Human Interface Guidelines

1. **Window Management**
   - Resizable windows with minimum size
   - Save window position/size
   - Support full-screen mode

2. **Navigation**
   - Sidebar for primary navigation
   - Toolbar for context actions
   - Clear visual hierarchy

3. **Input**
   - Keyboard-first where possible
   - Mouse precision for drawing
   - Touch Bar support (if available)

4. **Feedback**
   - Progress indicators for long operations
   - Tooltips on hover
   - Status bar for sync status

### Accessibility

**Both Platforms:**
- VoiceOver support
- Dynamic Type
- High contrast mode
- Keyboard navigation

**macOS Specific:**
- Full keyboard access
- Reduce motion
- Speak selection

---

## Testing Strategy

### Unit Tests (Shared)
- Model creation/persistence
- ViewModel business logic
- Utility functions
- iCloud sync logic

### UI Tests

#### iPadOS
- Touch navigation
- Apple Pencil drawing
- Page curl animation
- State restoration

#### macOS
- Keyboard shortcuts
- Menu bar commands
- Mouse drawing
- Window management
- Sidebar navigation

### Integration Tests
- Cross-platform iCloud sync
- PDF export on both platforms
- Conflict resolution
- Data migration

---

## Performance Considerations

### macOS Optimizations

1. **Large PDFs**
   - Use thumbnail caching
   - Lazy load PDF pages
   - Render off main thread

2. **Drawing Performance**
   - Debounced auto-save
   - Metal acceleration for rendering
   - Optimize stroke rendering

3. **Memory Management**
   - Dispose of off-screen page views
   - Compress drawing data
   - Monitor memory pressure

---

## Distribution

### App Store Requirements

**iPadOS App:**
- Screenshots: iPad Pro 12.9" (required)
- Privacy Policy (if collecting any data)
- Age Rating: 4+
- Category: Productivity / Entertainment

**macOS App:**
- Screenshots: Multiple window sizes
- Notarization required
- Hardened Runtime enabled
- Code signing certificate

### Universal Purchase

- Single purchase for both iOS and macOS
- Shared App Store listing
- Same Bundle ID prefix

---

## Future Enhancements

1. **Continuity Features**
   - Handoff between iPad and Mac
   - Universal Clipboard for drawings
   - AirDrop support

2. **Collaboration**
   - SharePlay for remote gaming sessions
   - Real-time co-editing
   - Comments and annotations

3. **Advanced Features**
   - OCR for character sheet text
   - AI-assisted stat calculation
   - Template marketplace

---

## Conclusion

The macOS companion app leverages 80%+ of the existing iPadOS codebase while providing a Mac-native experience. By sharing models, ViewModels, and utilities, development time is significantly reduced while maintaining consistency across platforms.

Key success factors:
- Well-architected shared code
- Platform-specific UI adaptations
- Robust iCloud sync
- Comprehensive testing

**Estimated Development Time:** 3-4 weeks for a full-featured macOS app

---

*For questions or contributions, please see CONTRIBUTING.md*
