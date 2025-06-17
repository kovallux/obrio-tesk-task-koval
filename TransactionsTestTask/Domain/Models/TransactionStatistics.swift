//
//  TransactionStatistics.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation

struct TransactionStatistics {
    let totalTransactions: Int
    let totalIncome: Double
    let totalExpenses: Double
    let netBalance: Double
    let averageTransactionAmount: Double
    let largestTransaction: Double
    let smallestTransaction: Double
    let transactionCount: TransactionCount
    
    struct TransactionCount {
        let income: Int
        let expense: Int
    }
    
    var formattedNetBalance: String {
        return String(format: "%.8f BTC", netBalance)
    }
    
    var formattedTotalIncome: String {
        return String(format: "%.8f BTC", totalIncome)
    }
    
    var formattedTotalExpenses: String {
        return String(format: "%.8f BTC", totalExpenses)
    }
    
    var formattedAverageAmount: String {
        return String(format: "%.8f BTC", averageTransactionAmount)
    }
} 