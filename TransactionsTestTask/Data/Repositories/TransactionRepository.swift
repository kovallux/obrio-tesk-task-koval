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
    func fetchTransactions(page: Int, pageSize: Int) throws -> [Transaction]
    func fetchAllTransactions() throws -> [Transaction]
}

final class TransactionRepository: TransactionRepositoryProtocol {
    
    private let coreDataStack: CoreDataStack
    
    // MARK: - Init
    
    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Save Transaction
    
    func save(_ transaction: Transaction) throws {
        let context = coreDataStack.context
        
        // Create new TransactionEntity
        let _ = transaction.toEntity(context: context)
        
        // Save context
        do {
            try context.save()
            print("TransactionRepository: Successfully saved transaction - ID: \(transaction.id), Amount: \(transaction.amountBTC) BTC")
        } catch {
            print("TransactionRepository: Failed to save transaction - Error: \(error)")
            throw error
        }
    }
    
    // MARK: - Fetch Transactions Paginated
    
    func fetchTransactions(page: Int, pageSize: Int) throws -> [Transaction] {
        let context = coreDataStack.context
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        
        // Sort by timestamp descending (newest first)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        // Set pagination
        request.fetchLimit = pageSize
        request.fetchOffset = page * pageSize
        
        do {
            let entities = try context.fetch(request)
            let transactions = entities.map { Transaction(from: $0) }
            
            print("TransactionRepository: Fetched \(transactions.count) transactions for page \(page)")
            return transactions
        } catch {
            print("TransactionRepository: Failed to fetch transactions - Error: \(error)")
            throw error
        }
    }
    
    // MARK: - Fetch All Transactions
    
    func fetchAllTransactions() throws -> [Transaction] {
        let context = coreDataStack.context
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        
        // Sort by timestamp descending (newest first)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            let transactions = entities.map { Transaction(from: $0) }
            
            print("TransactionRepository: Fetched \(transactions.count) total transactions")
            return transactions
        } catch {
            print("TransactionRepository: Failed to fetch all transactions - Error: \(error)")
            throw error
        }
    }
}

// MARK: - Helper Methods

extension TransactionRepository {
    
    func fetchTransactionsGroupedByDay(page: Int, pageSize: Int) throws -> [String: [Transaction]] {
        let transactions = try fetchTransactions(page: page, pageSize: pageSize)
        
        let grouped = Dictionary(grouping: transactions) { transaction in
            transaction.dayKey
        }
        
        print("TransactionRepository: Grouped transactions into \(grouped.keys.count) days")
        return grouped
    }
    
    func getTotalBalance() throws -> Double {
        let transactions = try fetchAllTransactions()
        
        let balance = transactions.reduce(0.0) { result, transaction in
            switch transaction.type {
            case .income:
                return result + transaction.amountBTC
            case .expense:
                return result - transaction.amountBTC
            }
        }
        
        print("TransactionRepository: Calculated total balance: \(balance) BTC")
        return balance
    }
} 