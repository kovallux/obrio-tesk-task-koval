//
//  TransactionStatistics.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation

enum StatisticsPeriod: CaseIterable {
    case week, month, threeMonths, year
    
    var title: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .threeMonths: return "3 Months"
        case .year: return "Year"
        }
    }
    
    var dateRange: DateInterval {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            return DateInterval(start: startOfWeek, end: now)
        case .month:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            return DateInterval(start: startOfMonth, end: now)
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            return DateInterval(start: threeMonthsAgo, end: now)
        case .year:
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return DateInterval(start: oneYearAgo, end: now)
        }
    }
}

struct TransactionStatistics {
    let period: StatisticsPeriod
    let totalTransactions: Int
    let totalIncome: Double
    let totalExpenses: Double
    let netBalance: Double
    let averageTransactionAmount: Double
    let largestTransaction: Double
    let smallestTransaction: Double
    let transactionCount: TransactionCount
    let balanceHistory: [BalanceDataPoint]
    let categoryBreakdown: [CategoryData]
    let monthlyTrends: [MonthlyTrendData]
    let recentTransactions: [Transaction]
    let insights: [StatisticsInsight]
    let bitcoinRate: Double
    
    struct TransactionCount {
        let income: Int
        let expense: Int
        
        var total: Int {
            return income + expense
        }
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
    
    var netBalanceUSD: Double {
        return netBalance * bitcoinRate
    }
    
    var totalIncomeUSD: Double {
        return totalIncome * bitcoinRate
    }
    
    var totalExpensesUSD: Double {
        return totalExpenses * bitcoinRate
    }
    
    var formattedNetBalanceUSD: String {
        return String(format: "$%.2f", netBalanceUSD)
    }
    
    var formattedTotalIncomeUSD: String {
        return String(format: "$%.2f", totalIncomeUSD)
    }
    
    var formattedTotalExpensesUSD: String {
        return String(format: "$%.2f", totalExpensesUSD)
    }
}

struct BalanceDataPoint {
    let date: Date
    let balance: Double
    let balanceUSD: Double
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var formattedBalance: String {
        return String(format: "%.6f BTC", balance)
    }
    
    var formattedBalanceUSD: String {
        return String(format: "$%.2f", balanceUSD)
    }
}

struct CategoryData {
    let category: String
    let totalAmount: Double
    let transactionCount: Int
    let averageAmount: Double
    let percentage: Double
    
    var formattedTotalAmount: String {
        return String(format: "%.6f BTC", totalAmount)
    }
    
    var formattedAverageAmount: String {
        return String(format: "%.6f BTC", averageAmount)
    }
    
    var formattedPercentage: String {
        return String(format: "%.1f%%", percentage)
    }
}

struct MonthlyTrendData {
    let month: Date
    let income: Double
    let expenses: Double
    let netChange: Double
    let transactionCount: Int
    
    var formattedMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: month)
    }
    
    var formattedIncome: String {
        return String(format: "%.6f BTC", income)
    }
    
    var formattedExpenses: String {
        return String(format: "%.6f BTC", expenses)
    }
    
    var formattedNetChange: String {
        let sign = netChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.6f", netChange)) BTC"
    }
    
    var isPositive: Bool {
        return netChange >= 0
    }
}

struct StatisticsInsight {
    let type: InsightType
    let title: String
    let description: String
    let value: Double
    let trend: Trend
    
    enum InsightType {
        case topCategory
        case spendingTrend
        case averageTransaction
        case savingsGoal
        case unusualActivity
    }
    
    enum Trend {
        case increasing
        case decreasing
        case neutral
        
        var color: String {
            switch self {
            case .increasing: return "systemGreen"
            case .decreasing: return "systemRed"
            case .neutral: return "systemBlue"
            }
        }
        
        var icon: String {
            switch self {
            case .increasing: return "arrow.up.circle.fill"
            case .decreasing: return "arrow.down.circle.fill"
            case .neutral: return "minus.circle.fill"
            }
        }
    }
    
    var formattedValue: String {
        return String(format: "%.6f BTC", value)
    }
} 