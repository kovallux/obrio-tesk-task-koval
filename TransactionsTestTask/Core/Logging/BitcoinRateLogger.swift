//
//  BitcoinRateLogger.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 18.06.2025.
//

import Foundation
import os.log

class BitcoinRateLogger {
    
    // MARK: - Singleton
    static let shared = BitcoinRateLogger()
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "com.transactionstesttask.bitcoinrate", category: "BitcoinRateLogger")
    private let fileManager = FileManager.default
    private let logQueue = DispatchQueue(label: "bitcoin.rate.logger", qos: .utility)
    
    // MARK: - Module Names for Simulation
    private let moduleNames = [
        "DashboardModule", "StatisticsModule", "TransactionModule", "SettingsModule",
        "NotificationModule", "AnalyticsModule", "ReportingModule", "ExportModule",
        "ChartModule", "FilterModule", "SearchModule", "CacheModule",
        "NetworkModule", "DatabaseModule", "SecurityModule", "ValidationModule",
        "FormattingModule", "LocalizationModule", "ThemeModule", "AccessibilityModule",
        "BackupModule", "SyncModule", "AuthModule", "BiometricModule",
        "PushNotificationModule", "WidgetModule", "WatchModule", "ShareModule",
        "PrintModule", "EmailModule", "SMSModule", "CalendarModule",
        "ContactsModule", "PhotosModule", "LocationModule", "HealthModule",
        "PaymentModule", "SubscriptionModule", "RatingModule", "FeedbackModule",
        "HelpModule", "TutorialModule", "OnboardingModule", "UpdateModule",
        "CrashReportingModule", "PerformanceModule", "MemoryModule", "StorageModule",
        "CompressionModule", "EncryptionModule", "HashingModule", "RandomModule"
    ]
    
    // MARK: - Initialization
    private init() {
        setupLogFile()
    }
    
    // MARK: - Public Methods
    
    /// Logs a Bitcoin rate update from multiple simulated modules
    /// - Parameter rate: The Bitcoin rate to log
    /// - Parameter subscriberCount: Number of modules to simulate (default: random 20-50)
    static func log(_ rate: Double, subscriberCount: Int? = nil) {
        shared.logRateUpdate(rate, subscriberCount: subscriberCount)
    }
    
    /// Logs a Bitcoin rate update with specific module name
    /// - Parameters:
    ///   - rate: The Bitcoin rate to log
    ///   - moduleName: The name of the module logging the update
    static func log(_ rate: Double, from moduleName: String) {
        shared.logRateUpdate(rate, from: moduleName)
    }
    
    // MARK: - Private Methods
    
    private func logRateUpdate(_ rate: Double, subscriberCount: Int? = nil) {
        let count = subscriberCount ?? Int.random(in: 20...50)
        let selectedModules = Array(moduleNames.shuffled().prefix(count))
        
        logQueue.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = Date()
            let formattedRate = String(format: "%.2f", rate)
            
            // Log to system logger
            self.logger.info("📊 Bitcoin rate update: $\(formattedRate) - Broadcasting to \(count) modules")
            
            // Log from each simulated module
            for (index, moduleName) in selectedModules.enumerated() {
                let delay = Double(index) * 0.001 // Small delay to simulate real-world timing
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                    self.logFromModule(rate: rate, moduleName: moduleName, timestamp: timestamp)
                }
            }
            
            // Write summary to file
            self.writeToLogFile(rate: rate, moduleCount: count, timestamp: timestamp)
        }
    }
    
    private func logRateUpdate(_ rate: Double, from moduleName: String) {
        logQueue.async { [weak self] in
            guard let self = self else { return }
            self.logFromModule(rate: rate, moduleName: moduleName, timestamp: Date())
        }
    }
    
    private func logFromModule(rate: Double, moduleName: String, timestamp: Date) {
        let formattedRate = String(format: "%.2f", rate)
        let timeString = DateFormatter.logTimeFormatter.string(from: timestamp)
        
        // Log to system logger with module context
        logger.debug("[\(moduleName)] Bitcoin rate received: $\(formattedRate) at \(timeString)")
        
        // Simulate different module behaviors
        simulateModuleBehavior(moduleName: moduleName, rate: rate)
    }
    
    private func simulateModuleBehavior(moduleName: String, rate: Double) {
        // Simulate different actions modules might take with the rate update
        switch moduleName {
        case let name where name.contains("Dashboard"):
            logger.debug("[\(moduleName)] Updating dashboard display with new rate")
        case let name where name.contains("Statistics"):
            logger.debug("[\(moduleName)] Recalculating statistics with new rate")
        case let name where name.contains("Notification"):
            logger.debug("[\(moduleName)] Checking rate thresholds for notifications")
        case let name where name.contains("Cache"):
            logger.debug("[\(moduleName)] Caching new rate value")
        case let name where name.contains("Analytics"):
            logger.debug("[\(moduleName)] Recording rate change for analytics")
        case let name where name.contains("Widget"):
            logger.debug("[\(moduleName)] Updating widget with new rate")
        default:
            logger.debug("[\(moduleName)] Processing rate update")
        }
    }
    
    private func setupLogFile() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.error("Failed to get documents directory for log file")
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent("bitcoin_rate_logs.txt")
        
        // Create log file if it doesn't exist
        if !fileManager.fileExists(atPath: logFileURL.path) {
            let initialContent = "Bitcoin Rate Update Logs\nStarted: \(Date())\n\n"
            do {
                try initialContent.write(to: logFileURL, atomically: true, encoding: .utf8)
                logger.info("Created Bitcoin rate log file at: \(logFileURL.path)")
            } catch {
                logger.error("Failed to create log file: \(error.localizedDescription)")
            }
        }
    }
    
    private func writeToLogFile(rate: Double, moduleCount: Int, timestamp: Date) {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logFileURL = documentsPath.appendingPathComponent("bitcoin_rate_logs.txt")
        let timeString = DateFormatter.logTimeFormatter.string(from: timestamp)
        let formattedRate = String(format: "%.2f", rate)
        
        let logEntry = "[\(timeString)] Rate Update: $\(formattedRate) → Broadcasted to \(moduleCount) modules\n"
        
        do {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            fileHandle.seekToEndOfFile()
            if let data = logEntry.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } catch {
            // If file doesn't exist or can't be opened, try to create/write it
            do {
                let existingContent = (try? String(contentsOf: logFileURL)) ?? ""
                let newContent = existingContent + logEntry
                try newContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            } catch {
                logger.error("Failed to write to log file: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let logTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Log File Management

extension BitcoinRateLogger {
    
    /// Returns the current log file URL
    static var logFileURL: URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("bitcoin_rate_logs.txt")
    }
    
    /// Returns the contents of the log file
    static func getLogContents() -> String? {
        guard let logFileURL = logFileURL else { return nil }
        return try? String(contentsOf: logFileURL)
    }
    
    /// Clears the log file
    static func clearLogs() {
        guard let logFileURL = logFileURL else { return }
        let initialContent = "Bitcoin Rate Update Logs\nCleared: \(Date())\n\n"
        try? initialContent.write(to: logFileURL, atomically: true, encoding: .utf8)
        shared.logger.info("Bitcoin rate logs cleared")
    }
} 
