//
//  CharacterSheetWidgetView.swift
//  CharacterSheetWidget
//
//  SwiftUI views for the character sheet widget
//

import SwiftUI
import WidgetKit

/// Main widget view that displays the character sheet snapshot
struct CharacterSheetWidgetView: View {
    let entry: CharacterSheetEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)

            if let characterID = entry.characterID,
               let deepLinkURL = createDeepLinkURL(characterID: characterID) {
                // Character sheet content
                characterSheetContent
                    .widgetURL(deepLinkURL)
            } else if entry.characterID != nil {
                // Character exists but URL creation failed - show without link
                characterSheetContent
            } else {
                // Empty state
                emptyStateView
            }
        }
    }

    // MARK: - Character Sheet Content

    private var characterSheetContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Character sheet snapshot
                if let image = entry.snapshotImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .accessibilityLabel("Character sheet for \(entry.characterName)")
                        .accessibilityHint("Tap to open \(entry.characterName) in the app")
                } else {
                    // Fallback placeholder
                    placeholderView
                }

                // Bottom overlay with character info
                characterInfoOverlay
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Character Info Overlay

    private var characterInfoOverlay: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    // Character name
                    Text(entry.characterName)
                        .font(overlayTitleFont)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(1)

                    // Template/game system
                    Text(entry.templateName)
                        .font(overlaySubtitleFont)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                }

                Spacer()

                // Action indicator
                Image(systemName: "arrow.up.forward.circle.fill")
                    .font(overlayIconFont)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, overlayHorizontalPadding)
            .padding(.vertical, overlayVerticalPadding)
        }
        .background(overlayBackground)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: emptyStateIconSize))
                .foregroundColor(.secondary)
                .accessibilityHidden(true)

            VStack(spacing: 4) {
                Text("No Character")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Open the app to view a character")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No character selected")
        .accessibilityHint("Open the TTRPG Character Sheets app to view a character in this widget")
    }

    // MARK: - Placeholder

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "doc.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
        }
    }

    // MARK: - Dynamic Sizing

    private var overlayTitleFont: Font {
        switch widgetFamily {
        case .systemLarge, .systemExtraLarge:
            return .title3
        default:
            return .body
        }
    }

    private var overlaySubtitleFont: Font {
        switch widgetFamily {
        case .systemLarge, .systemExtraLarge:
            return .subheadline
        default:
            return .caption
        }
    }

    private var overlayIconFont: Font {
        switch widgetFamily {
        case .systemLarge, .systemExtraLarge:
            return .title2
        default:
            return .body
        }
    }

    private var overlayHorizontalPadding: CGFloat {
        switch widgetFamily {
        case .systemLarge, .systemExtraLarge:
            return 16
        default:
            return 12
        }
    }

    private var overlayVerticalPadding: CGFloat {
        switch widgetFamily {
        case .systemLarge, .systemExtraLarge:
            return 12
        default:
            return 8
        }
    }

    private var emptyStateIconSize: CGFloat {
        switch widgetFamily {
        case .systemLarge, .systemExtraLarge:
            return 60
        default:
            return 40
        }
    }

    private var overlayBackground: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.7),
                Color.black.opacity(0.5)
            ],
            startPoint: .bottom,
            endPoint: .top
        )
        .blur(radius: 10)
    }

    // MARK: - Deep Link URL

    private func createDeepLinkURL(characterID: UUID) -> URL? {
        // Create deep link URL for opening the character in the main app
        // Format: ttrpgcharactersheets://character/{characterID}
        URL(string: "ttrpgcharactersheets://character/\(characterID.uuidString)")
    }
}

// MARK: - Widget Configuration

struct CharacterSheetWidget: Widget {
    let kind: String = "CharacterSheetWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCharacterIntent.self,
            provider: CharacterSheetTimelineProvider()
        ) { entry in
            CharacterSheetWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Character Sheet")
        .description("View your TTRPG character sheet at a glance")
        .supportedFamilies([.systemLarge, .systemExtraLarge])
        // Disable WidgetKit content margins so the provided character sheet snapshot can render
        // edge-to-edge for systemLarge and systemExtraLarge widget families. The snapshot image
        // itself must be generated with any required safe area insets and internal padding so that
        // important content is not clipped when displayed without additional widget margins.
        .contentMarginsDisabled()
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    CharacterSheetWidget()
} timeline: {
    CharacterSheetEntry(
        date: Date(),
        characterID: UUID(),
        characterName: "Thorin Stonehammer",
        templateName: "D&D 5E Character Sheet",
        snapshotImage: WidgetImageRenderer.generatePlaceholderImage(),
        configuration: SelectCharacterIntent()
    )

    CharacterSheetEntry(
        date: Date(),
        characterID: nil,
        characterName: "No Character",
        templateName: "Select a character",
        snapshotImage: nil,
        configuration: SelectCharacterIntent()
    )
}
