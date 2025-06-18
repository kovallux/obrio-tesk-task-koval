//
//  AddTransactionUseCase.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine
import CoreData

protocol AddTransactionUseCaseProtocol {
    func execute(amount: Double, category: String, type: TransactionType) -> AnyPublisher<Void, Error>
}

class AddTransactionUseCase: AddTransactionUseCaseProtocol {
    private let repository: TransactionRepositoryProtocol
    
    init(repository: TransactionRepositoryProtocol = TransactionRepository()) {
        self.repository = repository
    }
    
    func execute(amount: Double, category: String, type: TransactionType) -> AnyPublisher<Void, Error> {
        let transaction = Transaction(
            amountBTC: amount,
            category: category,
            type: type
        )
        
        return repository.save(transaction)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}

// MARK: - Repository Protocol
protocol TransactionRepositoryProtocol {
    func save(_ transaction: Transaction) -> AnyPublisher<Transaction, Error>
    func fetchTransactions(page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error>
    func fetchAllTransactions() -> AnyPublisher<[Transaction], Error>
} 