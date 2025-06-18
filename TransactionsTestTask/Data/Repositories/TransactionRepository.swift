//
//  TransactionRepository.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import CoreData
import Combine

// MARK: - Legacy Protocol (for backward compatibility)
protocol TransactionRepositoryLegacyProtocol {
    func save(_ transaction: Transaction) throws
    func fetchAll() throws -> [Transaction]
    func fetchPaginated(page: Int, pageSize: Int) throws -> [Transaction]
    func delete(_ transaction: Transaction) throws
    func getTotalBalance() throws -> Double
}

class TransactionRepository: TransactionRepositoryProtocol, TransactionRepositoryLegacyProtocol {
    private let context = CoreDataStack.shared.context
    
    // MARK: - Combine Methods
    func save(_ transaction: Transaction) -> AnyPublisher<Transaction, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            do {
                let entity = TransactionEntity(context: self.context)
                entity.id = transaction.id
                entity.amountBTC = transaction.amountBTC
                entity.category = transaction.category
                entity.timestamp = transaction.timestamp
                entity.type = transaction.type.rawValue
                
                try self.context.save()
                promise(.success(transaction))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchTransactions(page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            do {
                let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                request.fetchLimit = pageSize
                request.fetchOffset = page * pageSize
                
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                promise(.success(transactions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchAllTransactions() -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(RepositoryError.contextUnavailable))
                return
            }
            
            do {
                let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                promise(.success(transactions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Legacy Synchronous Methods (for backward compatibility)
    func save(_ transaction: Transaction) throws {
        let entity = TransactionEntity(context: context)
        entity.id = transaction.id
        entity.amountBTC = transaction.amountBTC
        entity.category = transaction.category
        entity.timestamp = transaction.timestamp
        entity.type = transaction.type.rawValue
        
        try context.save()
    }
    
    func fetchAll() throws -> [Transaction] {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.map { Transaction(from: $0) }
    }
    
    func fetchPaginated(page: Int, pageSize: Int) throws -> [Transaction] {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = pageSize
        request.fetchOffset = page * pageSize
        
        let entities = try context.fetch(request)
        return entities.map { Transaction(from: $0) }
    }
    
    func delete(_ transaction: Transaction) throws {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", transaction.id as CVarArg)
        
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        
        try context.save()
    }
    
    func getTotalBalance() throws -> Double {
        let transactions = try fetchAll()
        return transactions.reduce(0) { result, transaction in
            switch transaction.type {
            case .income:
                return result + transaction.amountBTC
            case .expense:
                return result - transaction.amountBTC
            }
        }
    }
}

// MARK: - Repository Errors
enum RepositoryError: Error, LocalizedError {
    case contextUnavailable
    case saveFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .contextUnavailable:
            return "Core Data context is unavailable"
        case .saveFailed:
            return "Failed to save transaction"
        case .fetchFailed:
            return "Failed to fetch transactions"
        }
    }
} 