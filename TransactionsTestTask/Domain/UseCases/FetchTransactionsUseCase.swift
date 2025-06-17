//
//  FetchTransactionsUseCase.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine
import CoreData

protocol FetchTransactionsUseCaseProtocol {
    func execute(page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error>
    func executeGroupedByDay() -> AnyPublisher<[String: [Transaction]], Error>
    func executeFiltered(by type: TransactionType, page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error>
    func executeFilteredByCategory(_ category: String, page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error>
    func getTransactionStatistics() -> AnyPublisher<TransactionStatistics, Error>
    func getCategoryBreakdown() -> AnyPublisher<[String: Double], Error>
}

class FetchTransactionsUseCase: FetchTransactionsUseCaseProtocol {
    private let context = CoreDataStack.shared.context
    
    func execute(page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = pageSize
            request.fetchOffset = page * pageSize
            
            do {
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                promise(.success(transactions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func executeGroupedByDay() -> AnyPublisher<[String: [Transaction]], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            
            do {
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let grouped = Dictionary(grouping: transactions) { transaction in
                    dateFormatter.string(from: transaction.timestamp)
                }
                
                promise(.success(grouped))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func executeFiltered(by type: TransactionType, page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "type == %@", type.rawValue)
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = pageSize
            request.fetchOffset = page * pageSize
            
            do {
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                promise(.success(transactions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func executeFilteredByCategory(_ category: String, page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.predicate = NSPredicate(format: "category == %@", category)
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            request.fetchLimit = pageSize
            request.fetchOffset = page * pageSize
            
            do {
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                promise(.success(transactions))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTransactionStatistics() -> AnyPublisher<TransactionStatistics, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            
            do {
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                
                guard !transactions.isEmpty else {
                    let emptyStats = TransactionStatistics(
                        totalTransactions: 0,
                        totalIncome: 0,
                        totalExpenses: 0,
                        netBalance: 0,
                        averageTransactionAmount: 0,
                        largestTransaction: 0,
                        smallestTransaction: 0,
                        transactionCount: TransactionStatistics.TransactionCount(income: 0, expense: 0)
                    )
                    promise(.success(emptyStats))
                    return
                }
                
                let incomeTransactions = transactions.filter { $0.type == .income }
                let expenseTransactions = transactions.filter { $0.type == .expense }
                
                let totalIncome = incomeTransactions.reduce(0) { $0 + $1.amountBTC }
                let totalExpenses = expenseTransactions.reduce(0) { $0 + $1.amountBTC }
                let netBalance = totalIncome - totalExpenses
                
                let amounts = transactions.map { $0.amountBTC }
                let averageAmount = amounts.reduce(0, +) / Double(amounts.count)
                let largestAmount = amounts.max() ?? 0
                let smallestAmount = amounts.min() ?? 0
                
                let statistics = TransactionStatistics(
                    totalTransactions: transactions.count,
                    totalIncome: totalIncome,
                    totalExpenses: totalExpenses,
                    netBalance: netBalance,
                    averageTransactionAmount: averageAmount,
                    largestTransaction: largestAmount,
                    smallestTransaction: smallestAmount,
                    transactionCount: TransactionStatistics.TransactionCount(
                        income: incomeTransactions.count,
                        expense: expenseTransactions.count
                    )
                )
                
                promise(.success(statistics))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCategoryBreakdown() -> AnyPublisher<[String: Double], Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.contextUnavailable))
                return
            }
            
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            
            do {
                let entities = try self.context.fetch(request)
                let transactions = entities.map { Transaction(from: $0) }
                
                let breakdown = Dictionary(grouping: transactions, by: { $0.category })
                    .mapValues { transactions in
                        transactions.reduce(0) { $0 + $1.amountBTC }
                    }
                
                promise(.success(breakdown))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

enum FetchTransactionsError: Error, LocalizedError {
    case contextUnavailable
    case noTransactionsFound
    
    var errorDescription: String? {
        switch self {
        case .contextUnavailable:
            return "Core Data context is unavailable"
        case .noTransactionsFound:
            return "No transactions found"
        }
    }
} 