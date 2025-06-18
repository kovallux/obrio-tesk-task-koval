//
//  Constants.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit

struct Constants {
    
    // MARK: - Design System
    struct Design {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let buttonHeight: CGFloat = 50
        static let cellHeight: CGFloat = 80
        
        struct Spacing {
            static let tiny: CGFloat = 4
            static let small: CGFloat = 8
            static let medium: CGFloat = 16
            static let large: CGFloat = 24
            static let extraLarge: CGFloat = 32
        }
        
        struct Shadow {
            static let opacity: Float = 0.1
            static let radius: CGFloat = 4
            static let offset = CGSize(width: 0, height: 2)
        }
    }
    
    // MARK: - API
    struct API {
        static let bitcoinRateUpdateInterval: TimeInterval = 180 // 3 minutes
        static let requestTimeout: TimeInterval = 30
    }
    
    // MARK: - Pagination
    struct Pagination {
        static let defaultPageSize = 20
        static let maxPageSize = 100
    }
    
    // MARK: - Transaction Categories
    struct Categories {
        static let incomeCategories = ["Salary", "Bonus", "Investment", "Gift", "Refill", "Other"]
        static let expenseCategories = ["Food", "Transport", "Entertainment", "Shopping", "Bills", "Other"]
    }
    
    // MARK: - Format
    struct Format {
        static let bitcoinDecimalPlaces = 8
        static let usdDecimalPlaces = 2
        static let shortBitcoinDecimalPlaces = 4
    }
} 