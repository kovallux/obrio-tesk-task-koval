//
//  TransactionRepository.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import CoreData

protocol TransactionRepositoryProtocol {
    func save(_ transaction: Transaction) throws
    func fetchAll() throws -> [Transaction]
    func fetchPaginated(page: Int, pageSize: Int) throws -> [Transaction]
    func delete(_ transaction: Transaction) throws
    func getTotalBalance() throws -> Double
}

class TransactionRepository: TransactionRepositoryProtocol {
    private let context = CoreDataStack.shared.context
    
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