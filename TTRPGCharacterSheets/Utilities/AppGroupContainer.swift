//
//  AppGroupContainer.swift
//  TTRPGCharacterSheets
//
//  Created for App Group data sharing with Widget Extension
//

import Foundation
import SwiftData

/// Manages App Group container access for shared data between app and extensions
enum AppGroupContainer {

    /// App Group identifier (must match entitlements)
    static let identifier = "group.com.ttrpg.charactersheets"

    /// Cached shared ModelContainer for widget use
    /// This reduces overhead from repeatedly creating containers
    private static var cachedModelContainer: ModelContainer?
    private static let containerLock = NSLock()

    /// Shared container URL for the App Group
    /// - Returns: URL to the shared container directory
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    /// URL for the shared SwiftData database
    /// - Returns: URL where SwiftData should store its database
    static var swiftDataStoreURL: URL? {
        containerURL?.appendingPathComponent("SwiftData.sqlite")
    }

    /// Validates that the App Group container is accessible
    /// - Returns: True if container is accessible, false otherwise
    static func validateAccess() -> Bool {
        guard let url = containerURL else {
            print("⚠️ App Group container not accessible. Check entitlements configuration.")
            return false
        }

        // Ensure directory exists
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                print("✅ Created App Group container directory at: \(url.path)")
            } catch {
                print("❌ Failed to create App Group container: \(error)")
                return false
            }
        }

        print("✅ App Group container accessible at: \(url.path)")
        return true
    }

    /// Creates a shared ModelContainer configured for App Group access
    /// - Parameters:
    ///   - schema: SwiftData schema
    ///   - isStoredInMemoryOnly: Whether to use in-memory storage (for testing)
    /// - Returns: Configured ModelContainer
    static func createModelContainer(
        schema: Schema,
        isStoredInMemoryOnly: Bool = false
    ) throws -> ModelContainer {
        // For non-memory containers, return cached instance if available
        if !isStoredInMemoryOnly {
            containerLock.lock()
            defer { containerLock.unlock() }
            
            if let cached = cachedModelContainer {
                return cached
            }
        }
        
        // Validate App Group access
        guard validateAccess() else {
            throw AppGroupError.containerNotAccessible
        }

        // Create configuration
        let configuration: ModelConfiguration

        if isStoredInMemoryOnly {
            // In-memory storage for testing
            configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true
            )
        } else {
            // Persistent storage in App Group container
            guard let storeURL = swiftDataStoreURL else {
                throw AppGroupError.invalidStoreURL
            }

            configuration = ModelConfiguration(
                schema: schema,
                url: storeURL,
                allowsSave: true
            )
        }

        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        // Cache the container for reuse (only for persistent storage)
        if !isStoredInMemoryOnly {
            containerLock.lock()
            cachedModelContainer = container
            containerLock.unlock()
        }
        
        return container
    }

    /// Errors related to App Group container access
    enum AppGroupError: Error, LocalizedError {
        case containerNotAccessible
        case invalidStoreURL

        var errorDescription: String? {
            switch self {
            case .containerNotAccessible:
                return "App Group container is not accessible. Ensure entitlements are properly configured."
            case .invalidStoreURL:
                return "Failed to construct SwiftData store URL."
            }
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension AppGroupContainer {
    /// Prints debug information about App Group container
    static func printDebugInfo() {
        print("\n=== App Group Container Debug Info ===")
        print("Identifier: \(identifier)")

        if let containerURL = containerURL {
            print("Container URL: \(containerURL.path)")

            let fileManager = FileManager.default
            print("Container exists: \(fileManager.fileExists(atPath: containerURL.path))")

            if let storeURL = swiftDataStoreURL {
                print("SwiftData store URL: \(storeURL.path)")
                print("Database exists: \(fileManager.fileExists(atPath: storeURL.path))")

                // Check database size if it exists
                if let attributes = try? fileManager.attributesOfItem(atPath: storeURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    let formatter = ByteCountFormatter()
                    formatter.allowedUnits = [.useKB, .useMB]
                    formatter.countStyle = .file
                    print("Database size: \(formatter.string(fromByteCount: fileSize))")
                }
            }

            // List contents of container
            if let contents = try? fileManager.contentsOfDirectory(atPath: containerURL.path) {
                print("Container contents: \(contents)")
            }
        } else {
            print("❌ Container URL is nil - entitlements not configured")
        }
        print("=====================================\n")
    }
}
#endif
