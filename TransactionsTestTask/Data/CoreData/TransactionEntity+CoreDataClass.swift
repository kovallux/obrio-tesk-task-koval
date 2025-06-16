//
//  TransactionEntity+CoreDataClass.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import CoreData

@objc(TransactionEntity)
public class TransactionEntity: NSManagedObject {
    
    // MARK: - Convenience Initializer
    
    convenience init(context: NSManagedObjectContext, id: UUID = UUID(), amountBTC: Double, category: String, timestamp: Date = Date(), type: String) {
        self.init(context: context)
        self.id = id
        self.amountBTC = amountBTC
        self.category = category
        self.timestamp = timestamp
        self.type = type
        
        print("TransactionEntity: Created new transaction - ID: \(id), Amount: \(amountBTC) BTC, Category: \(category), Type: \(type)")
    }
}



// MARK: - Helper Methods

extension TransactionEntity {
    
    var isIncome: Bool {
        return type == "in"
    }
    
    var isExpense: Bool {
        return type == "out"
    }
    
    var formattedAmount: String {
        return String(format: "%.8f BTC", amountBTC)
    }
    
    var formattedTimestamp: String {
        guard let timestamp = timestamp else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
} 