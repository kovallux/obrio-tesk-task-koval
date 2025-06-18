//
//  AddTransactionViewModel.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine
import CoreData

class AddTransactionViewModel: ObservableObject {
    @Published var amount: String = ""
    @Published var category: String = ""
    @Published var transactionType: TransactionType = .expense
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isValid: Bool = false
    
    // Additional properties for UI binding
    @Published var amountText: String = ""
    @Published var customCategory: String = ""
    @Published var selectedCategory: String = ""
    @Published var amountError: String? = nil
    @Published var categoryError: String? = nil
    @Published var isTransactionAdded: Bool = false
    
    private let context = CoreDataStack.shared.context
    private var cancellables = Set<AnyCancellable>()
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 0
        return formatter
    }()
    
    let incomeCategories = ["Salary", "Bonus", "Investment", "Gift", "Other"]
    let expenseCategories = ["Food", "Transport", "Entertainment", "Shopping", "Bills", "Other"]
    
    var categories: [String] {
        return transactionType == .income ? incomeCategories : expenseCategories
    }
    
    init() {
        setupValidation()
        setupBindings()
    }
    
    private func setupValidation() {
        Publishers.CombineLatest3($amount, $category, $transactionType)
            .map { [weak self] amount, category, _ in
                guard let self = self else { return false }
                return !amount.isEmpty && 
                       self.parseLocalizedAmount(amount) != nil && 
                       self.parseLocalizedAmount(amount)! > 0 && 
                       !category.isEmpty
            }
            .assign(to: &$isValid)
    }
    
    private func setupBindings() {
        // Sync amountText with amount
        $amountText
            .assign(to: &$amount)
        
        // Sync customCategory with category if it's not empty
        $customCategory
            .filter { !$0.isEmpty }
            .assign(to: &$category)
    }
    
    @discardableResult
    func addTransaction() -> AnyPublisher<Void, Error> {
        guard isValid else {
            return Fail(error: NSError(domain: "ValidationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid input"]))
                .eraseToAnyPublisher()
        }
        
        guard let amountValue = parseLocalizedAmount(amount) else {
            return Fail(error: NSError(domain: "ValidationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid amount"]))
                .eraseToAnyPublisher()
        }
        
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "ViewModelError", code: 0, userInfo: [NSLocalizedDescriptionKey: "ViewModel deallocated"])))
                return
            }
            
            let transaction = TransactionEntity(context: self.context)
            transaction.id = UUID()
            transaction.amountBTC = amountValue
            transaction.category = self.category
            transaction.type = self.transactionType.rawValue
            transaction.timestamp = Date()
            
            do {
                try self.context.save()
                DispatchQueue.main.async {
                    self.isTransactionAdded = true
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func setAmount(_ amount: String) {
        self.amount = amount
    }
    
    func setCategory(_ category: String) {
        self.category = category
    }
    
    func setTransactionType(_ type: TransactionType) {
        self.transactionType = type
    }
    
    func toggleTransactionType() {
        transactionType = transactionType == .income ? .expense : .income
    }
    
    func selectCategory(_ category: String) {
        selectedCategory = category
        self.category = category
    }
    
    // MARK: - Helper Methods
    
    private func parseLocalizedAmount(_ amountString: String) -> Double? {
        // First try with the number formatter (handles localized input)
        if let number = numberFormatter.number(from: amountString) {
            return number.doubleValue
        }
        
        // Fallback: try converting comma to dot and parse
        let normalizedString = amountString.replacingOccurrences(of: ",", with: ".")
        return Double(normalizedString)
    }
}

// MARK: - Quick Actions

extension AddTransactionViewModel {
    
    func addQuickExpense(amount: Double, category: String) {
        self.amount = String(amount)
        self.category = category
        self.transactionType = .expense
        
        print("AddTransactionViewModel: Quick expense added - \(amount) BTC in \(category)")
        addTransaction()
    }
    
    func addQuickIncome(amount: Double, category: String) {
        self.amount = String(amount)
        self.category = category
        self.transactionType = .income
        
        print("AddTransactionViewModel: Quick income added - \(amount) BTC in \(category)")
        addTransaction()
    }
    
    func addRefill(amount: Double) {
        self.amount = String(amount)
        self.category = "Refill"
        self.transactionType = .income
        
        print("AddTransactionViewModel: Refill added - \(amount) BTC")
        addTransaction()
    }
}

// MARK: - Preset Amounts

extension AddTransactionViewModel {
    
    var presetAmounts: [Double] {
        return [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0]
    }
    
    func selectPresetAmount(_ amount: Double) {
        self.amount = String(amount)
        print("AddTransactionViewModel: Preset amount selected - \(amount) BTC")
    }
    
    var formattedPresetAmounts: [String] {
        return presetAmounts.map { String(format: "%.3f BTC", $0) }
    }
} 
