//
//  AddTransactionUseCase.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

protocol AddTransactionUseCaseProtocol {
    func execute(_ transaction: Transaction) -> AnyPublisher<Void, Error>
    func executeWithValidation(_ transaction: Transaction) -> AnyPublisher<Void, Error>
}

final class AddTransactionUseCase: AddTransactionUseCaseProtocol {
    
    private let repository: TransactionRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: TransactionRepositoryProtocol = TransactionRepository()) {
        self.repository = repository
        print("AddTransactionUseCase: Initialized")
    }
    
    // MARK: - Execute
    
    func execute(_ transaction: Transaction) -> AnyPublisher<Void, Error> {
        print("AddTransactionUseCase: Executing add transaction - Amount: \(transaction.amountBTC) BTC, Type: \(transaction.type.displayName)")
        
        return Future<Void, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(AddTransactionError.useCaseDeinitialized))
                return
            }
            
            do {
                try self.repository.save(transaction)
                print("AddTransactionUseCase: Successfully saved transaction - ID: \(transaction.id)")
                promise(.success(()))
            } catch {
                print("AddTransactionUseCase: Failed to save transaction - Error: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func executeWithValidation(_ transaction: Transaction) -> AnyPublisher<Void, Error> {
        let validationResult = validateTransaction(transaction)
        
        switch validationResult {
        case .valid:
            return execute(transaction)
        case .invalid(let errors):
            let errorMessage = errors.map { $0.localizedDescription }.joined(separator: ", ")
            print("AddTransactionUseCase: Validation failed - \(errorMessage)")
            return Fail(error: AddTransactionError.validationFailed(errorMessage))
                .eraseToAnyPublisher()
        }
    }
}

// MARK: - Convenience Methods

extension AddTransactionUseCase {
    
    func addIncome(amount: Double, category: String) -> AnyPublisher<Void, Error> {
        let transaction = Transaction(
            amountBTC: amount,
            category: category,
            type: .income
        )
        
        print("AddTransactionUseCase: Adding income - \(amount) BTC in \(category)")
        return execute(transaction)
    }
    
    func addExpense(amount: Double, category: String) -> AnyPublisher<Void, Error> {
        let transaction = Transaction(
            amountBTC: amount,
            category: category,
            type: .expense
        )
        
        print("AddTransactionUseCase: Adding expense - \(amount) BTC in \(category)")
        return execute(transaction)
    }
    
    func addRefill(amount: Double) -> AnyPublisher<Void, Error> {
        let transaction = Transaction(
            amountBTC: amount,
            category: "Refill",
            type: .income
        )
        
        print("AddTransactionUseCase: Adding refill - \(amount) BTC")
        return execute(transaction)
    }
}

// MARK: - Validation

extension AddTransactionUseCase {
    
    func validateTransaction(_ transaction: Transaction) -> ValidationResult {
        var errors: [ValidationError] = []
        
        // Validate amount
        if transaction.amountBTC <= 0 {
            errors.append(.invalidAmount("Amount must be greater than 0"))
        }
        
        if transaction.amountBTC > 1000 { // Max 1000 BTC per transaction
            errors.append(.invalidAmount("Amount cannot exceed 1000 BTC"))
        }
        
        // Validate category
        if transaction.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.invalidCategory("Category cannot be empty"))
        }
        
        if transaction.category.count > 50 {
            errors.append(.invalidCategory("Category cannot exceed 50 characters"))
        }
        
        return errors.isEmpty ? .valid : .invalid(errors)
    }
}

// MARK: - Errors

enum AddTransactionError: Error, LocalizedError {
    case useCaseDeinitialized
    case validationFailed(String)
    case repositoryError(Error)
    
    var errorDescription: String? {
        switch self {
        case .useCaseDeinitialized:
            return "Use case was deinitialized"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        }
    }
}

enum ValidationError: Error, LocalizedError {
    case invalidAmount(String)
    case invalidCategory(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount(let message):
            return message
        case .invalidCategory(let message):
            return message
        }
    }
}

enum ValidationResult {
    case valid
    case invalid([ValidationError])
} 