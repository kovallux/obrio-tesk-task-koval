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
    func executeGroupedByDay() -> AnyPublisher<[String: [Transaction]], Error>
    func getTotalBalance() -> AnyPublisher<Double, Error>
    func executeFiltered(by type: TransactionType, page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error>
    func executeFilteredByCategory(_ category: String, page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error>
    func getTransactionStatistics() -> AnyPublisher<TransactionStatistics, Error>
    func getCategoryBreakdown() -> AnyPublisher<[CategoryBreakdown], Error>
}

final class FetchTransactionsUseCase: FetchTransactionsUseCaseProtocol {
    
    private let repository: TransactionRepositoryProtocol
    
    // MARK: - Init
    
    init(repository: TransactionRepositoryProtocol = TransactionRepository()) {
        self.repository = repository
        print("FetchTransactionsUseCase: Initialized")
    }
    
    // MARK: - Execute Methods
    
    func execute(page: Int, pageSize: Int) -> AnyPublisher<[Transaction], Error> {
        print("FetchTransactionsUseCase: Fetching transactions - Page: \(page), Size: \(pageSize)")
        
        return Future<[Transaction], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.useCaseDeinitialized))
                return
            }
            
            do {
                let transactions = try self.repository.fetchTransactions(page: page, pageSize: pageSize)
                print("FetchTransactionsUseCase: Successfully fetched \(transactions.count) transactions for page \(page)")
                promise(.success(transactions))
            } catch {
                print("FetchTransactionsUseCase: Failed to fetch transactions - Error: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func executeAll() -> AnyPublisher<[Transaction], Error> {
        print("FetchTransactionsUseCase: Fetching all transactions")
        
        return Future<[Transaction], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.useCaseDeinitialized))
                return
            }
            
            do {
                let transactions = try self.repository.fetchAllTransactions()
                print("FetchTransactionsUseCase: Successfully fetched all \(transactions.count) transactions")
                promise(.success(transactions))
            } catch {
                print("FetchTransactionsUseCase: Failed to fetch all transactions - Error: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func executeGroupedByDay() -> AnyPublisher<[String: [Transaction]], Error> {
        print("FetchTransactionsUseCase: Fetching transactions grouped by day")
        
        return Future<[String: [Transaction]], Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.useCaseDeinitialized))
                return
            }
            
            do {
                let groupedTransactions = try self.repository.fetchTransactionsGroupedByDay()
                let totalDays = groupedTransactions.keys.count
                let totalTransactions = groupedTransactions.values.flatMap { $0 }.count
                print("FetchTransactionsUseCase: Successfully fetched transactions grouped by \(totalDays) days, total \(totalTransactions) transactions")
                promise(.success(groupedTransactions))
            } catch {
                print("FetchTransactionsUseCase: Failed to fetch grouped transactions - Error: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTotalBalance() -> AnyPublisher<Double, Error> {
        print("FetchTransactionsUseCase: Calculating total balance")
        
        return Future<Double, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(FetchTransactionsError.useCaseDeinitialized))
                return
            }
            
            do {
                let balance = try self.repository.getTotalBalance()
                print("FetchTransactionsUseCase: Successfully calculated balance - \(balance) BTC")
                promise(.success(balance))
            } catch {
                print("FetchTransactionsUseCase: Failed to calculate balance - Error: \(error)")
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Filtering Methods

extension FetchTransactionsUseCase {
    
    func executeFiltered(by type: TransactionType, page: Int = 0, pageSize: Int = 20) -> AnyPublisher<[Transaction], Error> {
        print("FetchTransactionsUseCase: Fetching \(type.displayName) transactions - Page: \(page), Size: \(pageSize)")
        
        return execute(page: page, pageSize: pageSize)
            .map { transactions in
                let filtered = transactions.filter { $0.type == type }
                print("FetchTransactionsUseCase: Filtered to \(filtered.count) \(type.displayName) transactions")
                return filtered
            }
            .eraseToAnyPublisher()
    }
    
    func executeFilteredByCategory(_ category: String, page: Int = 0, pageSize: Int = 20) -> AnyPublisher<[Transaction], Error> {
        print("FetchTransactionsUseCase: Fetching transactions for category '\(category)' - Page: \(page), Size: \(pageSize)")
        
        return execute(page: page, pageSize: pageSize)
            .map { transactions in
                let filtered = transactions.filter { $0.category.lowercased().contains(category.lowercased()) }
                print("FetchTransactionsUseCase: Filtered to \(filtered.count) transactions for category '\(category)'")
                return filtered
            }
            .eraseToAnyPublisher()
    }
    
    func executeFilteredByDateRange(from startDate: Date, to endDate: Date) -> AnyPublisher<[Transaction], Error> {
        print("FetchTransactionsUseCase: Fetching transactions from \(startDate) to \(endDate)")
        
        return executeAll()
            .map { transactions in
                let filtered = transactions.filter { transaction in
                    transaction.timestamp >= startDate && transaction.timestamp <= endDate
                }
                print("FetchTransactionsUseCase: Filtered to \(filtered.count) transactions in date range")
                return filtered
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Statistics Methods

extension FetchTransactionsUseCase {
    
    func getTransactionStatistics() -> AnyPublisher<TransactionStatistics, Error> {
        print("FetchTransactionsUseCase: Calculating transaction statistics")
        
        return executeAll()
            .map { transactions in
                let incomeTransactions = transactions.filter { $0.type == .income }
                let expenseTransactions = transactions.filter { $0.type == .expense }
                
                let totalIncome = incomeTransactions.reduce(0) { $0 + $1.amountBTC }
                let totalExpenses = expenseTransactions.reduce(0) { $0 + $1.amountBTC }
                let balance = totalIncome - totalExpenses
                
                let categories = Set(transactions.map { $0.category })
                
                let statistics = TransactionStatistics(
                    totalTransactions: transactions.count,
                    totalIncome: totalIncome,
                    totalExpenses: totalExpenses,
                    balance: balance,
                    incomeCount: incomeTransactions.count,
                    expenseCount: expenseTransactions.count,
                    uniqueCategories: categories.count,
                    categories: Array(categories)
                )
                
                print("FetchTransactionsUseCase: Statistics - Total: \(statistics.totalTransactions), Balance: \(statistics.balance) BTC")
                return statistics
            }
            .eraseToAnyPublisher()
    }
    
    func getCategoryBreakdown() -> AnyPublisher<[CategoryBreakdown], Error> {
        print("FetchTransactionsUseCase: Calculating category breakdown")
        
        return executeAll()
            .map { transactions in
                let grouped = Dictionary(grouping: transactions) { $0.category }
                
                let breakdown = grouped.map { category, categoryTransactions in
                    let totalAmount = categoryTransactions.reduce(0) { $0 + $1.amountBTC }
                    let incomeAmount = categoryTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amountBTC }
                    let expenseAmount = categoryTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amountBTC }
                    
                    return CategoryBreakdown(
                        category: category,
                        transactionCount: categoryTransactions.count,
                        totalAmount: totalAmount,
                        incomeAmount: incomeAmount,
                        expenseAmount: expenseAmount
                    )
                }.sorted { $0.totalAmount > $1.totalAmount }
                
                print("FetchTransactionsUseCase: Category breakdown for \(breakdown.count) categories")
                return breakdown
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Data Models

struct TransactionStatistics {
    let totalTransactions: Int
    let totalIncome: Double
    let totalExpenses: Double
    let balance: Double
    let incomeCount: Int
    let expenseCount: Int
    let uniqueCategories: Int
    let categories: [String]
    
    var formattedBalance: String {
        return String(format: "%.8f BTC", balance)
    }
    
    var formattedIncome: String {
        return String(format: "%.8f BTC", totalIncome)
    }
    
    var formattedExpenses: String {
        return String(format: "%.8f BTC", totalExpenses)
    }
}

struct CategoryBreakdown {
    let category: String
    let transactionCount: Int
    let totalAmount: Double
    let incomeAmount: Double
    let expenseAmount: Double
    
    var formattedTotalAmount: String {
        return String(format: "%.8f BTC", totalAmount)
    }
    
    var netAmount: Double {
        return incomeAmount - expenseAmount
    }
    
    var formattedNetAmount: String {
        return String(format: "%.8f BTC", netAmount)
    }
}

// MARK: - Errors

enum FetchTransactionsError: Error, LocalizedError {
    case useCaseDeinitialized
    case repositoryError(Error)
    case noTransactionsFound
    
    var errorDescription: String? {
        switch self {
        case .useCaseDeinitialized:
            return "Use case was deinitialized"
        case .repositoryError(let error):
            return "Repository error: \(error.localizedDescription)"
        case .noTransactionsFound:
            return "No transactions found"
        }
    }
} 