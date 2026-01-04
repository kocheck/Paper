# Contributing Guide

Thank you for your interest in contributing to the TTRPG Character Sheets app! This guide will help you get started.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Setup](#development-setup)
3. [Coding Standards](#coding-standards)
4. [Testing Guidelines](#testing-guidelines)
5. [Pull Request Process](#pull-request-process)
6. [Feature Requests](#feature-requests)
7. [Bug Reports](#bug-reports)

---

## Getting Started

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Git
- Basic knowledge of:
  - Swift 6
  - SwiftUI
  - SwiftData
  - PDFKit and PencilKit

### First-Time Setup

1. **Fork the repository**
   ```bash
   # On GitHub, click "Fork" button
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/ttrpg-character-sheets.git
   cd ttrpg-character-sheets
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/ttrpg-character-sheets.git
   ```

4. **Open in Xcode**
   ```bash
   open TTRPGCharacterSheets.xcodeproj
   ```

5. **Run the app**
   - Select an iPad simulator
   - Press ⌘R or click Run

6. **Run tests**
   - Press ⌘U or Product > Test

---

## Development Setup

### Project Configuration

The project uses:
- **Swift 6** language mode
- **iOS 17.0** minimum deployment target
- **SwiftData** for persistence (no external dependencies)
- **Swift Package Manager** (if adding dependencies)

### Recommended Xcode Settings

1. **Enable Swift Strict Concurrency**
   - Already configured in project settings

2. **Code Formatting**
   - Indentation: 4 spaces
   - Line length: 120 characters (soft limit)

3. **Static Analysis**
   - Enable "Analyze During Build"
   - Fix all warnings before submitting PR

### Useful Xcode Shortcuts

- `⌘B` - Build
- `⌘R` - Run
- `⌘U` - Run tests
- `⌘.` - Stop
- `⌘0` - Show/hide navigator
- `⌘⇧O` - Open quickly

---

## Coding Standards

### Swift Style Guide

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

#### File Structure

```swift
//
//  FileName.swift
//  TTRPGCharacterSheets
//
//  Created by [Name] on [Date].
//

import SwiftUI
import SwiftData

// MARK: - Main Type

struct MyView: View {
    // MARK: - Properties

    // MARK: - Initialization

    // MARK: - Body

    // MARK: - Private Methods
}

// MARK: - Supporting Types

// MARK: - Extensions

// MARK: - Preview
```

#### Naming Conventions

```swift
// ✅ Good
func fetchCharacter(withID id: UUID) -> Character?
var isLoading: Bool = false
let maximumPageCount = 100

// ❌ Bad
func getChar(id: UUID) -> Character?  // Unclear abbreviation
var loading: Bool = false  // Ambiguous
let MAX_PAGE_COUNT = 100  // Wrong case
```

#### SwiftUI Best Practices

```swift
// ✅ Good - Extract subviews
var body: some View {
    VStack {
        headerView
        contentView
        footerView
    }
}

private var headerView: some View {
    Text("Header")
}

// ❌ Bad - Too much in body
var body: some View {
    VStack {
        HStack {
            Image(systemName: "...")
            VStack {
                Text("...")
                Text("...")
            }
        }
        // 50 more lines...
    }
}
```

#### SwiftData Patterns

```swift
// ✅ Good - Use @Query for automatic updates
@Query(sort: \Character.dateModified, order: .reverse)
private var characters: [Character]

// ✅ Good - Use @Bindable for two-way binding
func editCharacter(@Bindable character: Character) {
    TextField("Name", text: $character.name)
}

// ❌ Bad - Manual observation
@State private var characters: [Character] = []
```

### Code Comments

```swift
// Good comments explain WHY, not WHAT

// ✅ Good
// Debounce auto-save to prevent excessive disk writes during active drawing
Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
    saveDrawing()
}

// ❌ Bad
// Schedule a timer that saves the drawing after 2 seconds
Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
    saveDrawing()
}
```

### MARK Comments

Use MARK comments to organize code:

```swift
// MARK: - Properties
// MARK: - Initialization
// MARK: - View Body
// MARK: - Actions
// MARK: - Helper Methods
// MARK: - Computed Properties
```

---

## Testing Guidelines

### Unit Tests

**What to Test:**
- ✅ Model initialization
- ✅ Model persistence
- ✅ Relationships and cascades
- ✅ Business logic
- ✅ Computed properties
- ✅ Edge cases

**What NOT to Test:**
- ❌ SwiftData framework itself
- ❌ SwiftUI rendering
- ❌ Third-party libraries

**Example Test:**

```swift
@MainActor
func testCharacterCreation() throws {
    // Given
    let template = Template(name: "Test", pdfData: Data(), pageCount: 1)
    let character = Character(name: "Gandalf", template: template)

    // When
    modelContext.insert(character)
    try modelContext.save()

    // Then
    let fetchDescriptor = FetchDescriptor<Character>()
    let characters = try modelContext.fetch(fetchDescriptor)

    XCTAssertEqual(characters.count, 1)
    XCTAssertEqual(characters.first?.name, "Gandalf")
}
```

### UI Tests

**What to Test:**
- ✅ Critical user flows (create character, import template)
- ✅ Navigation
- ✅ Form validation
- ✅ Error states

**What NOT to Test:**
- ❌ Visual appearance (use snapshot tests for that)
- ❌ Every possible interaction
- ❌ Implementation details

**Example UI Test:**

```swift
func testCreateCharacter() throws {
    // Given
    XCTAssertTrue(app.navigationBars["Character Library"].exists)

    // When
    app.buttons["plus.circle.fill"].tap()
    app.textFields["Character Name"].tap()
    app.textFields["Character Name"].typeText("Aragorn")
    app.buttons.matching(identifier: "TemplateRow").firstMatch.tap()
    app.buttons["Create"].tap()

    // Then
    XCTAssertTrue(app.navigationBars["Character Library"].waitForExistence(timeout: 2))
}
```

### Test Organization

```
Tests/
├── Unit/
│   ├── Models/
│   │   ├── TemplateModelTests.swift
│   │   ├── CharacterModelTests.swift
│   │   └── PageDrawingModelTests.swift
│   └── ViewModels/
│       └── (Future VM tests)
└── UI/
    ├── CharacterCreationUITests.swift
    └── CharacterEditorUITests.swift
```

### Test Coverage Goals

- **Models**: 90%+ coverage
- **ViewModels**: 80%+ coverage
- **Views**: 60%+ coverage (focus on critical paths)

---

## Pull Request Process

### Before Submitting

1. **Update your fork**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clean, documented code
   - Follow coding standards
   - Add tests for new functionality

4. **Run all tests**
   ```bash
   xcodebuild test -scheme TTRPGCharacterSheets
   ```

5. **Check for warnings**
   - Build with warnings as errors
   - Fix all analyzer issues

6. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: Add [feature description]"
   ```

   Use conventional commits:
   - `feat:` New feature
   - `fix:` Bug fix
   - `docs:` Documentation
   - `test:` Tests
   - `refactor:` Code refactoring
   - `perf:` Performance improvement

### Submitting the PR

1. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create Pull Request on GitHub**
   - Clear title and description
   - Reference related issues
   - Add screenshots/videos if UI changes
   - Mark as draft if work in progress

3. **PR Template**
   ```markdown
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Breaking change
   - [ ] Documentation update

   ## Testing
   - [ ] Unit tests added/updated
   - [ ] UI tests added/updated
   - [ ] Manual testing performed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Comments added for complex code
   - [ ] Documentation updated
   - [ ] No new warnings
   - [ ] Tests pass locally
   ```

### Review Process

1. Maintainers will review your PR
2. Address feedback with new commits
3. Once approved, PR will be merged
4. Delete your feature branch

---

## Feature Requests

### How to Request a Feature

1. **Check existing issues** to avoid duplicates
2. **Create a new issue** with:
   - Clear title
   - Detailed description
   - Use cases
   - Mockups (if applicable)
   - Potential implementation approach

### Feature Request Template

```markdown
**Feature Description**
Clear, concise description of the feature

**Problem It Solves**
What user problem does this address?

**Proposed Solution**
How should this feature work?

**Alternatives Considered**
What other approaches did you consider?

**Additional Context**
Screenshots, mockups, examples
```

---

## Bug Reports

### How to Report a Bug

1. **Search existing issues** first
2. **Reproduce the bug** consistently
3. **Create detailed report** with:
   - Steps to reproduce
   - Expected behavior
   - Actual behavior
   - Screenshots/videos
   - Device info
   - iOS version

### Bug Report Template

```markdown
**Describe the Bug**
Clear, concise description

**To Reproduce**
1. Go to '...'
2. Tap on '...'
3. Scroll down to '...'
4. See error

**Expected Behavior**
What should happen?

**Screenshots**
If applicable

**Environment**
- Device: iPad Pro 12.9" (6th gen)
- iOS Version: 17.0
- App Version: 1.0.0

**Additional Context**
Any other relevant information
```

---

## Code Review Checklist

When reviewing PRs, check for:

- [ ] Code follows style guide
- [ ] Tests are included and pass
- [ ] No new warnings or errors
- [ ] Documentation updated if needed
- [ ] Commit messages are clear
- [ ] No unnecessary files committed
- [ ] Performance implications considered
- [ ] Accessibility considerations
- [ ] Error handling is appropriate

---

## Community Guidelines

### Be Respectful

- Treat everyone with respect
- Welcome newcomers
- Be patient with questions
- Provide constructive feedback

### Communication

- Be clear and concise
- Use inclusive language
- Stay on topic
- Assume good intentions

---

## Questions?

- **Documentation**: Check README.md and ARCHITECTURE.md
- **Issues**: Open a GitHub issue
- **Discussions**: Use GitHub Discussions
- **Email**: [Maintainer email if applicable]

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing! 🎉
