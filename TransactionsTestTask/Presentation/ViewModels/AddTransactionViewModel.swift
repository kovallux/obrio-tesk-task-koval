//
//  AddTransactionViewModel.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

final class AddTransactionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var amountText: String = ""
    @Published var selectedCategory: String = ""
    @Published var selectedType: TransactionType = .expense
    @Published var customCategory: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var showingCustomCategory: Bool = false
    
    // MARK: - Validation Properties
    
    @Published var amountError: String?
    @Published var categoryError: String?
    @Published var isFormValid: Bool = false
    @Published var isTransactionAdded: Bool = false
    
    // MARK: - Use Case
    
    private let addTransactionUseCase: AddTransactionUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    
    let predefinedCategories = [
        "Food & Dining",
        "Transportation",
        "Shopping",
        "Entertainment",
        "Bills & Utilities",
        "Healthcare",
        "Education",
        "Travel",
        "Investment",
        "Salary",
        "Freelance",
        "Business",
        "Gift",
        "Other"
    ]
    
    var categories: [String] {
        return predefinedCategories + ["Custom"]
    }
    
    // MARK: - Init
    
    init(addTransactionUseCase: AddTransactionUseCaseProtocol = AddTransactionUseCase()) {
        self.addTransactionUseCase = addTransactionUseCase
        print("AddTransactionViewModel: Initialized")
        setupValidation()
    }
    
    // MARK: - Setup
    
    private func setupValidation() {
        // Validate amount in real-time
        $amountText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] amountText in
                self?.validateAmount(amountText)
            }
            .store(in: &cancellables)
        
        // Validate category in real-time
        Publishers.CombineLatest($selectedCategory, $customCategory)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] (selectedCategory, customCategory) in
                self?.validateCategory(selectedCategory: selectedCategory, customCategory: customCategory)
            }
            .store(in: &cancellables)
        
        // Update form validity
        Publishers.CombineLatest($amountError, $categoryError)
            .map { amountError, categoryError in
                return amountError == nil && categoryError == nil
            }
            .assign(to: \.isFormValid, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Validation Methods
    
    private func validateAmount(_ amountText: String) {
        guard !amountText.isEmpty else {
            amountError = nil
            return
        }
        
        guard let amount = Double(amountText) else {
            amountError = "Please enter a valid number"
            return
        }
        
        if amount <= 0 {
            amountError = "Amount must be greater than 0"
            return
        }
        
        if amount > 1000 {
            amountError = "Amount cannot exceed 1000 BTC"
            return
        }
        
        amountError = nil
    }
    
    private func validateCategory(selectedCategory: String, customCategory: String) {
        let finalCategory = getFinalCategory()
        
        if finalCategory.isEmpty {
            categoryError = "Please select or enter a category"
            return
        }
        
        if finalCategory.count > 50 {
            categoryError = "Category cannot exceed 50 characters"
            return
        }
        
        categoryError = nil
    }
    
    // MARK: - Public Methods
    
    func addTransaction() {
        guard isFormValid else {
            print("AddTransactionViewModel: Form is not valid")
            return
        }
        
        guard let amount = Double(amountText) else {
            errorMessage = "Invalid amount"
            return
        }
        
        let category = getFinalCategory()
        guard !category.isEmpty else {
            errorMessage = "Category is required"
            return
        }
        
        print("AddTransactionViewModel: Adding transaction - Amount: \(amount) BTC, Category: \(category), Type: \(selectedType.displayName)")
        
        isLoading = true
        clearMessages()
        
        let transaction = Transaction(
            amountBTC: amount,
            category: category,
            type: selectedType
        )
        
        addTransactionUseCase.executeWithValidation(transaction)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                        print("AddTransactionViewModel: Failed to add transaction - \(error)")
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.successMessage = "Transaction added successfully!"
                    self?.isTransactionAdded = true
                    self?.resetForm()
                    print("AddTransactionViewModel: Transaction added successfully")
                }
            )
            .store(in: &cancellables)
    }
    
    func resetForm() {
        amountText = ""
        selectedCategory = ""
        customCategory = ""
        selectedType = .expense
        showingCustomCategory = false
        clearMessages()
        clearErrors()
        
        print("AddTransactionViewModel: Form reset")
    }
    
    func selectCategory(_ category: String) {
        if category == "Custom" {
            showingCustomCategory = true
            selectedCategory = ""
        } else {
            showingCustomCategory = false
            selectedCategory = category
            customCategory = ""
        }
        
        print("AddTransactionViewModel: Category selected - \(category)")
    }
    
    func toggleTransactionType() {
        selectedType = selectedType == .income ? .expense : .income
        print("AddTransactionViewModel: Transaction type changed to \(selectedType.displayName)")
    }
    
    // MARK: - Helper Methods
    
    private func getFinalCategory() -> String {
        if showingCustomCategory {
            return customCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return selectedCategory
        }
    }
    
    private func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    private func clearErrors() {
        amountError = nil
        categoryError = nil
    }
    
    // MARK: - Computed Properties
    
    var formattedAmount: String {
        guard let amount = Double(amountText), amount > 0 else {
            return "0.00000000 BTC"
        }
        return String(format: "%.8f BTC", amount)
    }
    
    var displayCategory: String {
        let category = getFinalCategory()
        return category.isEmpty ? "Select Category" : category
    }
    
    var canAddTransaction: Bool {
        return isFormValid && !isLoading
    }
    
    var availableCategories: [String] {
        return predefinedCategories + ["Custom"]
    }
    
    var transactionTypeDisplayName: String {
        return selectedType.displayName
    }
    
    var transactionTypeColor: String {
        return selectedType == .income ? "green" : "red"
    }
}

// MARK: - Quick Actions

extension AddTransactionViewModel {
    
    func addQuickExpense(amount: Double, category: String) {
        amountText = String(amount)
        selectedCategory = category
        selectedType = .expense
        showingCustomCategory = false
        
        print("AddTransactionViewModel: Quick expense added - \(amount) BTC in \(category)")
        addTransaction()
    }
    
    func addQuickIncome(amount: Double, category: String) {
        amountText = String(amount)
        selectedCategory = category
        selectedType = .income
        showingCustomCategory = false
        
        print("AddTransactionViewModel: Quick income added - \(amount) BTC in \(category)")
        addTransaction()
    }
    
    func addRefill(amount: Double) {
        amountText = String(amount)
        selectedCategory = "Refill"
        selectedType = .income
        showingCustomCategory = false
        
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
        amountText = String(amount)
        print("AddTransactionViewModel: Preset amount selected - \(amount) BTC")
    }
    
    var formattedPresetAmounts: [String] {
        return presetAmounts.map { String(format: "%.3f BTC", $0) }
    }
} 