//
//  BitcoinRateLogger.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation

public final class BitcoinRateLogger {
    
    // MARK: - Singleton
    
    static let shared = BitcoinRateLogger()
    
    private init() {
        print("BitcoinRateLogger: Initialized centralized logger")
    }
    
    // MARK: - Properties
    
    private var logEntries: [LogEntry] = []
    private let queue = DispatchQueue(label: "bitcoin.rate.logger", qos: .utility)
    private let maxLogEntries = 1000 // Keep last 1000 entries
    
    // MARK: - Public Logging Methods
    
    public static func log(_ rate: Double, from subscriber: String = "Unknown") {
        shared.logRate(rate, from: subscriber)
    }
    
    public static func log(_ rate: Double) {
        shared.logRate(rate, from: "DefaultSubscriber")
    }
    
    // MARK: - Private Implementation
    
    private func logRate(_ rate: Double, from subscriber: String) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let entry = LogEntry(
                rate: rate,
                subscriber: subscriber,
                timestamp: Date()
            )
            
            // Add new entry
            self.logEntries.append(entry)
            
            // Maintain max entries limit
            if self.logEntries.count > self.maxLogEntries {
                self.logEntries.removeFirst(self.logEntries.count - self.maxLogEntries)
            }
            
            // Log to console with detailed information
            let formattedRate = String(format: "%.2f", rate)
            let timeString = self.formatTimestamp(entry.timestamp)
            
            print("📊 BitcoinRateLogger: [\(timeString)] Rate: $\(formattedRate) | Subscriber: \(subscriber) | Total Logs: \(self.logEntries.count)")
            
            // Additional analytics logging
            self.logAnalytics(entry)
        }
    }
    
    private func logAnalytics(_ entry: LogEntry) {
        // Calculate rate change if we have previous entries
        if logEntries.count >= 2 {
            let previousRate = logEntries[logEntries.count - 2].rate
            let change = entry.rate - previousRate
            let changePercent = (change / previousRate) * 100
            
            if abs(changePercent) > 1.0 { // Log significant changes (>1%)
                let direction = change > 0 ? "📈" : "📉"
                print("📊 BitcoinRateLogger: \(direction) Significant change: \(String(format: "%.2f", changePercent))% (\(change > 0 ? "+" : "")\(String(format: "%.2f", change)))")
            }
        }
        
        // Log statistics every 10 entries
        if logEntries.count % 10 == 0 {
            logStatistics()
        }
    }
    
    private func logStatistics() {
        guard !logEntries.isEmpty else { return }
        
        let rates = logEntries.map { $0.rate }
        let minRate = rates.min() ?? 0
        let maxRate = rates.max() ?? 0
        let avgRate = rates.reduce(0, +) / Double(rates.count)
        
        print("📊 BitcoinRateLogger: 📈 Statistics (last \(logEntries.count) entries):")
        print("📊 BitcoinRateLogger:   • Min: $\(String(format: "%.2f", minRate))")
        print("📊 BitcoinRateLogger:   • Max: $\(String(format: "%.2f", maxRate))")
        print("📊 BitcoinRateLogger:   • Avg: $\(String(format: "%.2f", avgRate))")
        
        // Log subscriber distribution
        let subscriberCounts = Dictionary(grouping: logEntries, by: { $0.subscriber })
            .mapValues { $0.count }
        
        print("📊 BitcoinRateLogger: 👥 Subscriber Distribution:")
        for (subscriber, count) in subscriberCounts.sorted(by: { $0.value > $1.value }) {
            print("📊 BitcoinRateLogger:   • \(subscriber): \(count) logs")
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
    
    // MARK: - Public Query Methods
    
    static func getLogEntries(limit: Int = 100) -> [LogEntry] {
        return shared.queue.sync {
            let startIndex = max(0, shared.logEntries.count - limit)
            return Array(shared.logEntries[startIndex...])
        }
    }
    
    static func getLogCount() -> Int {
        return shared.queue.sync {
            return shared.logEntries.count
        }
    }
    
    static func clearLogs() {
        shared.queue.async {
            shared.logEntries.removeAll()
            print("📊 BitcoinRateLogger: Cleared all log entries")
        }
    }
    
    // MARK: - Export Methods
    
    static func exportLogsToFile() -> URL? {
        return shared.queue.sync {
            do {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsPath.appendingPathComponent("bitcoin_rate_logs.json")
                
                let jsonData = try JSONEncoder().encode(shared.logEntries)
                try jsonData.write(to: fileURL)
                
                print("📊 BitcoinRateLogger: Exported \(shared.logEntries.count) log entries to \(fileURL.path)")
                return fileURL
            } catch {
                print("📊 BitcoinRateLogger: Failed to export logs - \(error)")
                return nil
            }
        }
    }
}

// MARK: - LogEntry Model

public struct LogEntry: Codable {
    let rate: Double
    let subscriber: String
    let timestamp: Date
    
    var formattedRate: String {
        return String(format: "%.2f", rate)
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - Extensions

extension LogEntry: CustomStringConvertible {
    public var description: String {
        return "LogEntry(rate: $\(formattedRate), subscriber: \(subscriber), time: \(formattedTimestamp))"
    }
} 
