# TTRPG Character Sheets - iPadOS App

A native iPadOS application for managing and annotating Tabletop RPG character sheets using Apple Pencil and PDFKit integration.

## 📋 Overview

This application serves as a digital library for TTRPG character sheets. Users can import PDF templates and create character instances, then use Apple Pencil to write stats, notes, and drawings directly onto the character sheet. The app provides a seamless, paper-like experience optimized for iPad and Apple Pencil.

## ✨ Key Features

### Core Functionality
- **PDF Template Management**: Import and organize PDF character sheet templates
- **Character Instances**: Create multiple characters from a single template
- **Apple Pencil Integration**: Natural drawing and writing experience using PencilKit
- **Multi-Page Support**: Navigate through multi-page character sheets with swipe gestures
- **Auto-Save**: Automatic saving of all drawings and annotations
- **State Restoration**: Resume exactly where you left off, even after app termination
- **Organized Library**: Grid-based character library with search and favorites

### Advanced Features (NEW!)
- **PDF Export with Annotations**: Export your character sheets with all drawings baked into the PDF
- **Custom Page Curl Animation**: Realistic book-turning effect using UIPageViewController
- **iCloud Sync**: Synchronize characters across all your Apple devices (iPad & Mac)
- **User Preferences**: Customize page transitions, drawing settings, and export options
- **macOS Companion Ready**: Architecture supports future macOS app development

## 🏗️ Architecture

### Tech Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **PDF Rendering**: PDFKit
- **Drawing**: PencilKit
- **Architecture Pattern**: MVVM (Model-View-ViewModel)

### Project Structure

```
TTRPGCharacterSheets/
├── Models/
│   ├── Template.swift           # PDF template model
│   ├── Character.swift          # Character instance model
│   └── PageDrawing.swift        # PencilKit drawing data per page
├── Views/
│   ├── MainLibraryView.swift    # Main character library grid
│   ├── CharacterEditorView.swift # PDF + PencilKit editor
│   ├── ImportTemplateView.swift # PDF import interface
│   ├── CreateCharacterView.swift # Character creation form
│   └── TemplateLibraryView.swift # Template management
├── ViewModels/
│   └── (Future ViewModels if needed)
├── Utilities/
│   └── (Helper classes and extensions)
├── Resources/
│   └── (Assets and resources)
├── Tests/
│   ├── Unit/
│   │   ├── TemplateModelTests.swift
│   │   ├── CharacterModelTests.swift
│   │   └── PageDrawingModelTests.swift
│   └── UI/
│       ├── CharacterCreationUITests.swift
│       └── CharacterEditorUITests.swift
└── TTRPGCharacterSheetsApp.swift # App entry point
```

## 📊 Data Model

### Entity Relationship Diagram

```
Template (1) ──< (N) Character (1) ──< (N) PageDrawing
```

### Template
- Stores the original blank PDF
- Contains metadata (name, page count, import date)
- Includes auto-generated thumbnail
- Cascades delete to all characters

### Character
- Instance of a template with user data
- References the template PDF
- Tracks last viewed page for state restoration
- Supports favorites and notes
- Cascades delete to all page drawings

### PageDrawing
- Stores PencilKit drawing data for a specific page
- Uses external storage for large drawings
- Automatically serializes/deserializes PKDrawing objects
- Tracks modification date for sync purposes

## 🎨 User Interface

### Main Library View
- Adaptive grid layout for character cards
- Search functionality
- Floating Action Buttons (FABs):
  - Green: Import new PDF template
  - Blue: Create new character from template
- Context menu on cards: Open, Favorite, Delete
- Empty state with helpful prompts

### Character Editor View
- PDF rendered as background layer
- Transparent PencilKit canvas overlay
- Multi-page support with TabView and swipe gestures
- Bottom toolbar with page navigation
- Tool picker for Apple Pencil settings
- Auto-save indicator
- Seamless page transitions

### Import Template View
- File picker for PDF selection
- PDF preview before import
- Auto-generated thumbnail
- File size and page count display
- Template naming

### Template Library View
- List of all imported templates
- Shows character count per template
- Swipe to delete with cascade warning
- Quick access to import new templates

## 🔧 Key Technical Implementation

### PDFKit + PencilKit Integration

The app layers a transparent PencilKit canvas over PDFKit views:

```swift
ZStack {
    // PDF Background
    PDFPageView(page: page)
        .background(Color.white)

    // PencilKit Canvas Overlay
    PencilKitCanvasView(
        pageIndex: pageIndex,
        character: character,
        canvasView: $canvasView,
        onDrawingChanged: { /* auto-save */ }
    )
}
```

### Auto-Save Mechanism

- Debounced auto-save (2 second delay after drawing change)
- Saves on page navigation
- Saves when editor is dismissed
- Visual indicator for unsaved changes

### State Restoration

```swift
// Save state
stateRestoration.saveState(characterID: character.id, pageIndex: currentPageIndex)

// Restore state on app launch
if let characterID = stateRestoration.characterToRestore {
    // Re-open character to last viewed page
}
```

### Multi-Page Navigation

- SwiftUI TabView with `.page` style
- Swipe gestures for natural page turning
- Previous/Next buttons for accessibility
- Page indicator (Page X of Y)
- Per-page drawing storage and loading

## 🧪 Testing

### Unit Tests (90+ tests)

**TemplateModelTests.swift**
- Template initialization and persistence
- Character relationships
- Cascade delete behavior
- Computed properties (file size, character count)
- Sorting and queries

**CharacterModelTests.swift**
- Character creation and persistence
- Template relationships
- Page drawing management
- Modification date tracking
- Computed properties
- Favorite functionality

**PageDrawingModelTests.swift**
- PencilKit integration
- Drawing serialization/deserialization
- Stroke counting
- Content detection
- External storage handling
- Large drawing data

### UI Tests

**CharacterCreationUITests.swift**
- Template import flow
- Character creation flow
- Form validation
- Search functionality
- Context menus
- Empty state display

**CharacterEditorUITests.swift**
- Editor launch and display
- Page navigation
- Tool picker
- State restoration
- Close/dismiss behavior
- Performance metrics

## 🚀 Getting Started

### Prerequisites

- Xcode 15.0 or later
- iPadOS 17.0 or later
- Apple Pencil (1st or 2nd generation) recommended

### Building the Project

1. Open the project in Xcode:
   ```bash
   cd TTRPGCharacterSheets
   open TTRPGCharacterSheets.xcodeproj
   ```

2. Select an iPad simulator or device

3. Build and run (⌘R)

### Running Tests

#### Unit Tests
```bash
# Command line
xcodebuild test -scheme TTRPGCharacterSheets -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)'

# Or in Xcode: ⌘U
```

#### UI Tests
```bash
xcodebuild test -scheme TTRPGCharacterSheetsUITests -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)'
```

## 📱 Usage Guide

### Importing a Template

1. Tap the green **Import Template** button (FAB with download icon)
2. Select a PDF file from your device
3. Preview the PDF
4. Enter a template name
5. Tap **Import**

### Creating a Character

1. Tap the blue **Create Character** button (FAB with plus icon)
2. Enter a character name
3. Select a template from the list
4. Optionally add notes or mark as favorite
5. Tap **Create**

### Editing a Character

1. Tap on a character card in the library
2. Use Apple Pencil to draw and write on the character sheet
3. Swipe left/right or use navigation buttons to change pages
4. Tap the **Tools** button to adjust pencil settings
5. Close when done - changes auto-save

### Managing Templates

1. Tap **Templates** in the navigation bar
2. View all imported templates
3. Swipe left to delete (with cascade warning)
4. Tap **+** to import new templates

## 🔒 Data Privacy

- All data stored locally on device by default
- Optional iCloud sync stores data in your private Apple iCloud account (no third-party servers)
- PDF data uses SwiftData external storage for efficiency
- No analytics or tracking

## 🎯 Future Enhancements

### Planned Features
- [x] iCloud sync for cross-device access
- [x] PDF export with annotations baked in
- [ ] Dice roller integration
- [ ] Character templates marketplace
- [ ] Collaborative editing (SharePlay)
- [ ] macOS companion app
- [ ] Custom page curl animation (vs TabView)
- [ ] Zoom and pan for detailed annotations
- [ ] Undo/redo for drawings
- [ ] Layer support for drawings

### Performance Optimizations
- [ ] Lazy loading for large PDFs
- [ ] Thumbnail caching strategy
- [ ] Background PDF processing
- [ ] Drawing data compression

## 📚 References

### Apple Documentation
- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [PencilKit](https://developer.apple.com/documentation/pencilkit)
- [PDFKit](https://developer.apple.com/documentation/pdfkit)
- [SwiftUI](https://developer.apple.com/documentation/swiftui)

### Key Patterns
- MVVM Architecture
- Repository Pattern (SwiftData)
- Coordinator Pattern (State Restoration)
- Delegate Pattern (PencilKit)

## 🤝 Contributing

This is a reference implementation. Key areas for contribution:

1. **Enhanced Animations**: Replace TabView with custom UIPageViewController for true page curl
2. **Zoom Support**: Add pinch-to-zoom on PDF pages
3. **Performance**: Optimize for very large PDFs (100+ pages)
4. **Accessibility**: Enhanced VoiceOver support
5. **Localization**: Multi-language support

## 📄 License

This project is provided as-is for educational and reference purposes.

## 👤 Author

Created as a reference implementation for building native iPadOS apps with SwiftUI, SwiftData, PDFKit, and PencilKit integration.

## 🙏 Acknowledgments

- Apple for excellent frameworks (SwiftUI, SwiftData, PencilKit, PDFKit)
- TTRPG community for inspiration
- iPad Pro and Apple Pencil for amazing hardware capabilities

---

**Built with ❤️ for the TTRPG community**
