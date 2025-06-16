//
//  Transaction.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import CoreData

struct Transaction {
    let id: UUID
    let amountBTC: Double
    let category: String
    let timestamp: Date
    let type: TransactionType
    
    init(id: UUID = UUID(), amountBTC: Double, category: String, timestamp: Date = Date(), type: TransactionType) {
        self.id = id
        self.amountBTC = amountBTC
        self.category = category
        self.timestamp = timestamp
        self.type = type
    }
}

// MARK: - TransactionType

enum TransactionType: String, CaseIterable {
    case income = "in"
    case expense = "out"
    
    var displayName: String {
        switch self {
        case .income:
            return "Income"
        case .expense:
            return "Expense"
        }
    }
}

// MARK: - Computed Properties

extension Transaction {
    
    var isIncome: Bool {
        return type == .income
    }
    
    var isExpense: Bool {
        return type == .expense
    }
    
    var formattedAmount: String {
        return String(format: "%.8f BTC", amountBTC)
    }
    
    var formattedAmountShort: String {
        return String(format: "%.4f BTC", amountBTC)
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Identifiable

extension Transaction: Identifiable {
    
}

// MARK: - Equatable

extension Transaction: Equatable {
    static func == (lhs: Transaction, rhs: Transaction) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - CoreData Conversion

extension Transaction {
    
    init(from entity: TransactionEntity) {
        self.id = entity.id ?? UUID()
        self.amountBTC = entity.amountBTC
        self.category = entity.category ?? ""
        self.timestamp = entity.timestamp ?? Date()
        self.type = TransactionType(rawValue: entity.type ?? "out") ?? .expense
    }
    
    func toEntity(context: NSManagedObjectContext) -> TransactionEntity {
        return TransactionEntity(
            context: context,
            id: id,
            amountBTC: amountBTC,
            category: category,
            timestamp: timestamp,
            type: type.rawValue
        )
    }
} 