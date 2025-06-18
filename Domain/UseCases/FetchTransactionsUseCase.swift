//
//  FetchTransactionsUseCase.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

protocol FetchTransactionsUseCaseProtocol {
    func execute(page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error>
    func executeAll() -> AnyPublisher<[Transaction], Error>
}

class FetchTransactionsUseCase: FetchTransactionsUseCaseProtocol {
    private let repository: TransactionRepositoryProtocol
    
    init(repository: TransactionRepositoryProtocol = TransactionRepository()) {
        self.repository = repository
    }
    
    func execute(page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error> {
        return repository.fetchTransactions(page: page, pageSize: pageSize)
    }
    
    func executeAll() -> AnyPublisher<[Transaction], Error> {
        return repository.fetchAllTransactions()
    }
} 