# Character Sheet Widget Extension - Setup Guide

## Overview

This guide walks you through setting up the Character Sheet Widget Extension for the TTRPGCharacterSheets iPad app. The widget allows users to view a snapshot of their most recently accessed or pinned character sheet directly from the home screen.

## Architecture Summary

### Components Created

1. **WidgetImageRenderer** (`TTRPGCharacterSheets/Utilities/WidgetImageRenderer.swift`)
   - Renders PDF pages with PencilKit drawings into static images
   - Memory-optimized for widget constraints
   - Supports multiple widget sizes with appropriate render configurations

2. **AppGroupContainer** (`TTRPGCharacterSheets/Utilities/AppGroupContainer.swift`)
   - Manages App Group container access
   - Provides shared SwiftData container for main app and widget
   - Validates App Group setup and provides debugging utilities

3. **Widget Extension** (`CharacterSheetWidget/`)
   - `CharacterSheetWidgetBundle.swift` - Main widget entry point
   - `CharacterSelectionIntent.swift` - App Intent for character selection
   - `CharacterSheetTimelineProvider.swift` - Timeline provider for widget updates
   - `CharacterSheetWidgetView.swift` - SwiftUI widget views

4. **Deep Linking Support**
   - URL scheme: `ttrpgcharactersheets://character/{uuid}`
   - Automatically opens specific character when widget is tapped

### Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Home Screen                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Character Sheet Widget                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │     [Character Sheet Snapshot Image]            │  │  │
│  │  │                                                  │  │  │
│  │  │     Character Name: Thorin Stonehammer          │  │  │
│  │  │     Game System: D&D 5E                         │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ (Tap Widget)
                            ▼
                  Deep Link: ttrpgcharactersheets://character/{uuid}
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Main App Opens                           │
│              Character Editor View Displayed                │
└─────────────────────────────────────────────────────────────┘

App Group Container: group.com.ttrpg.charactersheets
├── SwiftData.sqlite (Shared database)
│   ├── Template entities
│   ├── Character entities
│   └── PageDrawing entities
└── Shared UserDefaults
    └── lastViewedCharacterID
```

## Xcode Project Setup

### Step 1: Create Widget Extension Target

1. **Open Xcode Project**
   - Open `TTRPGCharacterSheets.xcodeproj` in Xcode

2. **Add Widget Extension Target**
   - Select the project in the Project Navigator
   - Click the `+` button under "Targets"
   - Choose **"Widget Extension"** template
   - Configure:
     - **Product Name**: `CharacterSheetWidget`
     - **Team**: Your development team
     - **Bundle Identifier**: `com.yourcompany.TTRPGCharacterSheets.CharacterSheetWidget`
     - **Include Configuration Intent**: ✅ (Check this)
   - Click "Finish"
   - When prompted "Activate scheme?", click "Activate"

3. **Delete Template Files**
   - Delete the auto-generated files:
     - `CharacterSheetWidget.swift`
     - `CharacterSheetWidgetLiveActivity.swift` (if present)
     - `CharacterSheetWidgetBundle.swift` (we'll replace it)
     - `AppIntent.swift` (we'll replace it)

4. **Add Widget Extension Files**
   - Drag these files from `CharacterSheetWidget/` folder into the widget target:
     - `CharacterSheetWidgetBundle.swift`
     - `CharacterSelectionIntent.swift`
     - `CharacterSheetTimelineProvider.swift`
     - `CharacterSheetWidgetView.swift`
   - Ensure they are added to the **CharacterSheetWidget target** (check Target Membership)

### Step 2: Add Shared Files to Widget Target

The widget needs access to certain files from the main app:

1. **Select Shared Model Files**
   - Select these files in the Project Navigator:
     - `Models/Template.swift`
     - `Models/Character.swift`
     - `Models/PageDrawing.swift`
     - `Utilities/WidgetImageRenderer.swift`
     - `Utilities/AppGroupContainer.swift`

2. **Add to Widget Target**
   - Open the File Inspector (⌥⌘1)
   - Under "Target Membership", check **both**:
     - ✅ TTRPGCharacterSheets
     - ✅ CharacterSheetWidget

### Step 3: Configure App Groups

App Groups enable data sharing between the main app and widget extension.

#### Main App Configuration

1. **Select Main App Target**
   - Click on the project → Select "TTRPGCharacterSheets" target
   - Go to "Signing & Capabilities" tab

2. **Add App Groups Capability**
   - Click "+ Capability"
   - Add "App Groups"
   - Click "+" under App Groups
   - Enter: `group.com.ttrpg.charactersheets`
   - Make sure it's **checked**

3. **Verify Entitlements**
   - Ensure `TTRPGCharacterSheets.entitlements` exists with:
   ```xml
   <key>com.apple.security.application-groups</key>
   <array>
       <string>group.com.ttrpg.charactersheets</string>
   </array>
   ```

#### Widget Extension Configuration

1. **Select Widget Target**
   - Click on the project → Select "CharacterSheetWidget" target
   - Go to "Signing & Capabilities" tab

2. **Add App Groups Capability**
   - Click "+ Capability"
   - Add "App Groups"
   - Click "+" under App Groups
   - Enter: `group.com.ttrpg.charactersheets` (same as main app)
   - Make sure it's **checked**

3. **Set Entitlements File**
   - Go to "Build Settings" tab
   - Search for "Code Signing Entitlements"
   - Set to: `CharacterSheetWidget/CharacterSheetWidget.entitlements`

### Step 4: Configure Build Settings

#### Widget Extension Settings

1. **Deployment Target**
   - Set "iOS Deployment Target" to **iOS 17.0** (to match main app)

2. **Supported Platforms**
   - Set "Supported Platforms" to **iPad only**
   - Base SDK: iOS

3. **Info.plist Configuration**
   - Ensure `CharacterSheetWidget/Info.plist` contains:
   ```xml
   <key>NSExtension</key>
   <dict>
       <key>NSExtensionPointIdentifier</key>
       <string>com.apple.widgetkit-extension</string>
   </dict>
   <key>UIDeviceFamily</key>
   <array>
       <integer>2</integer>  <!-- iPad only -->
   </array>
   ```

### Step 5: Configure URL Scheme (Deep Linking)

The main app's `Info.plist` should already include the URL scheme:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.ttrpg.charactersheets</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>ttrpgcharactersheets</string>
        </array>
    </dict>
</array>
```

This enables the widget to deep link back to the app.

## Building and Testing

### Building the Project

1. **Select Main App Scheme**
   - Select "TTRPGCharacterSheets" scheme
   - Build (⌘B)

2. **Select Widget Scheme**
   - Select "CharacterSheetWidget" scheme
   - Build (⌘B)

### Testing on Device/Simulator

1. **Run Main App First**
   - Select "TTRPGCharacterSheets" scheme
   - Run on iPad device or simulator
   - Import a template and create at least one character
   - View the character (this saves it as "last viewed")

2. **Add Widget to Home Screen**
   - Long-press on home screen
   - Tap "+" in top-left corner
   - Search for "Character Sheet"
   - Select widget size:
     - **Large Widget** (recommended)
     - **Extra Large Widget** (iPad only, maximum detail)
   - Tap "Add Widget"

3. **Configure Widget**
   - Long-press the widget
   - Tap "Edit Widget"
   - Configure options:
     - **Show Last Viewed**: ON (shows most recently viewed character)
     - **Show Last Viewed**: OFF → Select specific character from list

4. **Test Deep Linking**
   - Tap the widget
   - Main app should open
   - Character editor should display the selected character

### Debugging Widgets

#### Using Widget Debugger

1. **Attach Debugger**
   - Run the widget scheme
   - Xcode will attach to the widget extension process
   - Set breakpoints in timeline provider or widget view

2. **Console Logging**
   - Widget logs appear in Xcode console
   - Look for these prefixes:
     - `✅` - Success messages
     - `❌` - Error messages
     - `⚠️` - Warning messages

#### Common Debug Commands

```swift
// In CharacterSheetTimelineProvider.swift or other widget files
print("🔍 Widget timeline requested")
print("📊 Character ID: \(characterID)")
print("🖼️ Image rendered: \(snapshotImage != nil)")

// Use AppGroupContainer debug info
#if DEBUG
AppGroupContainer.printDebugInfo()
#endif
```

#### Widget Timeline Inspection

Widgets update on a timeline. To force refresh:
- Long-press widget → "Edit Widget" → Change configuration
- Or edit a character in the main app and wait ~15 minutes

## Troubleshooting

### Issue: Widget shows "No Character"

**Causes:**
- No characters exist in the database
- App Group not configured correctly
- SwiftData container not accessible

**Solutions:**
1. Verify App Groups are enabled for both targets
2. Check App Group identifier matches: `group.com.ttrpg.charactersheets`
3. Create at least one character in the main app
4. Check console for error messages

**Debug:**
```bash
# View widget extension logs
xcrun simctl spawn booted log stream --predicate 'subsystem contains "widget"'
```

### Issue: Widget shows old/stale data

**Causes:**
- Timeline not updating
- Main app not saving to shared container

**Solutions:**
1. Verify `StateRestorationManager` is saving to shared UserDefaults
2. Check `AppGroupContainer.createModelContainer()` is used in main app
3. Force widget refresh by editing configuration

### Issue: Tapping widget doesn't open app

**Causes:**
- URL scheme not configured
- Deep link handler not working

**Solutions:**
1. Verify `CFBundleURLTypes` in main app's Info.plist
2. Check URL scheme: `ttrpgcharactersheets`
3. Test deep link manually:
   ```bash
   xcrun simctl openurl booted "ttrpgcharactersheets://character/[UUID]"
   ```

### Issue: Widget crashes with memory error

**Causes:**
- Image rendering too large
- PDF pages too complex

**Solutions:**
1. Reduce `RenderConfiguration.targetSize` in `CharacterSheetTimelineProvider.swift`
2. Lower `compressionQuality` value
3. Render only first page (already default)

**Adjust render config:**
```swift
// In CharacterSheetTimelineProvider.swift, line ~150
let renderConfig = WidgetImageRenderer.RenderConfiguration(
    targetSize: CGSize(width: 600, height: 800),  // Reduce if needed
    scale: 2.0,  // Lower scale if needed
    compressionQuality: 0.6,  // Lower quality for less memory
    cropToContent: false
)
```

### Issue: "App Group container not accessible"

**Solutions:**
1. **Check Provisioning Profile**
   - Ensure your provisioning profile includes App Groups capability
   - Re-download provisioning profile if needed

2. **Clean Build Folder**
   - Product → Clean Build Folder (⇧⌘K)
   - Delete DerivedData: `~/Library/Developer/Xcode/DerivedData`

3. **Verify Entitlements**
   - Ensure both entitlements files have same App Group ID
   - Check Target Membership of entitlements files

## Performance Optimization

### Memory Management

Widgets have strict memory limits (~30-50MB depending on device):

1. **Image Rendering**
   - Default configuration targets 600x800 @ 2x scale
   - Adjust based on widget size
   - Use JPEG compression (0.75 quality)

2. **Timeline Strategy**
   - Update every 15 minutes (configurable in timeline provider)
   - Don't fetch unnecessary data
   - Use read-only SwiftData context

### Best Practices

1. **Minimize Timeline Entries**
   - Return single entry per timeline update
   - Use `.after(date)` refresh policy

2. **Efficient Data Fetching**
   - Fetch only required character
   - Use fetch predicates to limit results
   - Fetch only page 0 drawing data

3. **Error Handling**
   - Always provide fallback placeholder image
   - Handle missing characters gracefully
   - Log errors for debugging

## Widget Features

### Supported Widget Families

- ✅ **systemLarge** - 4x2 grid (recommended)
- ✅ **systemExtraLarge** - iPad full-width (maximum detail)
- ❌ systemSmall - Too small for character sheet
- ❌ systemMedium - Too small for meaningful content

### Configuration Options

Users can long-press the widget to configure:

1. **Show Last Viewed** (Default: ON)
   - Automatically displays most recently viewed character
   - Updates when user opens different character

2. **Select Specific Character** (Show Last Viewed: OFF)
   - Browse list of characters
   - Widget stays pinned to selected character
   - List shows character name + template name

### Widget Updates

The widget refreshes in these scenarios:

1. **Automatic Timeline Refresh**
   - Every 15 minutes (configurable)
   - WidgetKit manages system resources

2. **User Configuration Change**
   - Immediate update when user selects different character

3. **App Launch**
   - Widget may refresh when main app opens

4. **Manual Refresh**
   - User can long-press → Edit Widget to force refresh

## Customization

### Changing Widget Refresh Interval

In `CharacterSheetTimelineProvider.swift`:

```swift
// Line ~140
func timeline(for configuration: SelectCharacterIntent, in context: Context) async -> Timeline<CharacterSheetEntry> {
    let entry = await fetchCharacterEntry(for: configuration, in: context)

    // Change this value (in minutes)
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()

    return Timeline(entries: [entry], policy: .after(nextUpdate))
}
```

### Customizing Widget Appearance

In `CharacterSheetWidgetView.swift`:

1. **Overlay Colors**
   - Modify `overlayBackground` gradient
   - Change text colors in `characterInfoOverlay`

2. **Typography**
   - Adjust fonts in `overlayTitleFont`, `overlaySubtitleFont`
   - Modify padding values

3. **Empty State**
   - Customize `emptyStateView`
   - Change icon and messaging

### Adding Additional Widget Sizes

To support medium or small widgets:

1. Update `CharacterSheetWidget.supportedFamilies()`:
   ```swift
   .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
   ```

2. Add size-specific layouts in `CharacterSheetWidgetView.swift`

3. Adjust render configurations in timeline provider

## File Structure Reference

```
TTRPGCharacterSheets/
├── TTRPGCharacterSheetsApp.swift (Updated with deep linking)
├── TTRPGCharacterSheets.entitlements (App Groups)
├── Info.plist (URL scheme)
├── Models/
│   ├── Template.swift (Shared with widget)
│   ├── Character.swift (Shared with widget)
│   └── PageDrawing.swift (Shared with widget)
├── Utilities/
│   ├── WidgetImageRenderer.swift (Shared with widget)
│   └── AppGroupContainer.swift (Shared with widget)
└── Views/
    └── MainLibraryView.swift

CharacterSheetWidget/
├── CharacterSheetWidgetBundle.swift (Entry point)
├── CharacterSelectionIntent.swift (App Intent)
├── CharacterSheetTimelineProvider.swift (Data provider)
├── CharacterSheetWidgetView.swift (UI)
├── CharacterSheetWidget.entitlements (App Groups)
└── Info.plist (Extension configuration)

App Group Container: group.com.ttrpg.charactersheets
├── SwiftData.sqlite (Shared database)
└── Library/Preferences/group.com.ttrpg.charactersheets.plist (Shared UserDefaults)
```

## Security Considerations

### Data Access

- Widget has **read-only** access to SwiftData
- Cannot modify character data
- Can only read via shared App Group container

### Privacy

- Widget snapshot visible on home screen
- Consider adding blur/privacy mode option
- No sensitive data displayed in widget by default

## Next Steps

1. ✅ Test widget on physical iPad device
2. ✅ Test with multiple characters
3. ✅ Verify deep linking works correctly
4. ✅ Test App Group data sharing
5. ⬜ Submit to App Store (ensure provisioning includes App Groups)

## Additional Resources

- [Apple WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Groups Guide](https://developer.apple.com/documentation/xcode/configuring-app-groups)
- [App Intents Documentation](https://developer.apple.com/documentation/appintents)

## Support

For issues or questions:
1. Check console logs in Xcode
2. Use `AppGroupContainer.printDebugInfo()` for diagnostics
3. Verify all setup steps completed
4. Review troubleshooting section above

---

**Created:** 2026-01-04
**Version:** 1.0
**Minimum iOS:** 17.0
**Target Device:** iPad
