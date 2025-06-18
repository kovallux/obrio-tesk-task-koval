//
//  ExportService.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

class ExportService {
    
    // MARK: - CSV Export
    func exportToCSV(_ transactions: [Transaction]) -> AnyPublisher<URL, Error> {
        return Future { promise in
            do {
                let csvContent = self.generateCSVContent(from: transactions)
                let fileURL = try self.saveToFile(content: csvContent, fileName: "transactions.csv")
                promise(.success(fileURL))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - JSON Export
    func exportToJSON(_ transactions: [Transaction]) -> AnyPublisher<URL, Error> {
        return Future { promise in
            do {
                let jsonData = try self.generateJSONData(from: transactions)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
                let fileURL = try self.saveToFile(content: jsonString, fileName: "transactions.json")
                promise(.success(fileURL))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - PDF Export
    func exportToPDF(_ transactions: [Transaction], statistics: TransactionStatistics?) -> AnyPublisher<URL, Error> {
        return Future { promise in
            do {
                let pdfContent = self.generatePDFContent(from: transactions, statistics: statistics)
                let fileURL = try self.saveToFile(content: pdfContent, fileName: "transactions_report.txt")
                promise(.success(fileURL))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Backup
    func createBackup() -> AnyPublisher<URL, Error> {
        return Future { promise in
            do {
                let backupContent = self.generateBackupContent()
                let fileURL = try self.saveToFile(content: backupContent, fileName: "app_backup.json")
                promise(.success(fileURL))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    private func generateCSVContent(from transactions: [Transaction]) -> String {
        var csvContent = "Date,Amount (BTC),Category,Type\n"
        
        for transaction in transactions {
            let date = transaction.formattedDate
            let amount = String(format: "%.8f", transaction.amountBTC)
            let category = transaction.category
            let type = transaction.type.displayName
            
            csvContent += "\(date),\(amount),\(category),\(type)\n"
        }
        
        return csvContent
    }
    
    private func generateJSONData(from transactions: [Transaction]) throws -> Data {
        let exportData: [String: Any] = [
            "export_date": ISO8601DateFormatter().string(from: Date()),
            "total_transactions": transactions.count,
            "transactions": transactions.map { transaction in
                return [
                    "id": transaction.id.uuidString,
                    "amount_btc": transaction.amountBTC,
                    "category": transaction.category,
                    "type": transaction.type.rawValue,
                    "timestamp": ISO8601DateFormatter().string(from: transaction.timestamp)
                ]
            }
        ]
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    private func generatePDFContent(from transactions: [Transaction], statistics: TransactionStatistics?) -> String {
        var content = "TRANSACTION REPORT\n"
        content += "Generated: \(Date().formatted())\n\n"
        
        if let stats = statistics {
            content += "STATISTICS:\n"
            content += "Total Transactions: \(stats.totalTransactions)\n"
            content += "Total Income: \(String(format: "%.8f", stats.totalIncome)) BTC\n"
            content += "Total Expenses: \(String(format: "%.8f", stats.totalExpenses)) BTC\n"
            content += "Net Balance: \(String(format: "%.8f", stats.netBalance)) BTC\n\n"
        }
        
        content += "TRANSACTIONS:\n"
        for transaction in transactions {
            content += "\(transaction.formattedTimestamp) - \(transaction.formattedAmount) - \(transaction.category) (\(transaction.type.displayName))\n"
        }
        
        return content
    }
    
    private func generateBackupContent() -> String {
        let backupData: [String: Any] = [
            "backup_date": ISO8601DateFormatter().string(from: Date()),
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "settings": [
                "auto_refresh": UserDefaults.standard.bool(forKey: "auto_refresh"),
                "show_usd": UserDefaults.standard.bool(forKey: "show_usd"),
                "notifications": UserDefaults.standard.bool(forKey: "notifications")
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to create backup\"}"
        }
    }
    
    private func saveToFile(content: String, fileName: String) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        
        print("ExportService: File saved to \(fileURL.path)")
        return fileURL
    }
}

// MARK: - Export Errors
enum ExportError: Error, LocalizedError {
    case fileCreationFailed
    case dataConversionFailed
    case noDataToExport
    
    var errorDescription: String? {
        switch self {
        case .fileCreationFailed:
            return "Failed to create export file"
        case .dataConversionFailed:
            return "Failed to convert data for export"
        case .noDataToExport:
            return "No data available to export"
        }
    }
} 