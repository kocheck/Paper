//
//  UserPreferences.swift
//  TTRPGCharacterSheets
//
//  Created by Claude on 2026-01-04.
//

import Foundation
import SwiftUI

/// Centralized user preferences management
final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    // MARK: - Page Transition Style
    @AppStorage("pageTransitionStyle") var pageTransitionStyle: PageTransitionStyle = .pageCurl

    enum PageTransitionStyle: String, CaseIterable, Identifiable {
        case pageCurl = "Page Curl"
        case standard = "Standard"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .pageCurl: return "book.pages"
            case .standard: return "square.stack"
            }
        }

        var description: String {
            switch self {
            case .pageCurl:
                return "Realistic page curl animation like a physical book"
            case .standard:
                return "Simple swipe transition between pages"
            }
        }
    }

    // MARK: - Export Preferences
    @AppStorage("exportIncludeMetadata") var exportIncludeMetadata: Bool = true
    @AppStorage("exportOnlyAnnotated") var exportOnlyAnnotated: Bool = false

    // MARK: - Drawing Preferences
    @AppStorage("allowFingerDrawing") var allowFingerDrawing: Bool = false
    @AppStorage("autoSaveInterval") var autoSaveInterval: Double = 2.0

    // MARK: - Library Preferences
    @AppStorage("libraryViewStyle") var libraryViewStyle: LibraryViewStyle = .grid

    enum LibraryViewStyle: String, CaseIterable, Identifiable {
        case grid = "Grid"
        case list = "List"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }

    // MARK: - iCloud Sync (for future use)
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled: Bool = false

    private init() {}
}
