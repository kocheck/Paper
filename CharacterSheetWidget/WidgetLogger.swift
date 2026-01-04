//
//  WidgetLogger.swift
//  CharacterSheetWidget
//
//  Logging utility for widget extension debugging
//

import Foundation
import os

/// Centralized logging for widget extension
/// Uses OSLog for proper system log integration
enum WidgetLogger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "CharacterSheetWidget"
    private static let category = "Widget"
    
    /// Unified logger instance
    private static let logger = Logger(subsystem: subsystem, category: category)
    
    /// Log informational message
    static func info(_ message: String) {
        logger.info("\(message, privacy: .public)")
    }
    
    /// Log error message
    static func error(_ message: String, error: Error? = nil) {
        if let error = error {
            logger.error("\(message, privacy: .public): \(error.localizedDescription, privacy: .public)")
        } else {
            logger.error("\(message, privacy: .public)")
        }
    }
    
    /// Log warning message
    static func warning(_ message: String) {
        logger.warning("\(message, privacy: .public)")
    }
    
    /// Log debug message (only in debug builds)
    static func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
}
