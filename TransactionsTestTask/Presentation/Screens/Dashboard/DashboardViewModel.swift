//
//  DashboardViewModel.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine
import CoreData

class DashboardViewModel: ViewModelProtocol {
    @Published var transactions: [Transaction] = []
    @Published var currentBitcoinRate: Double = 0.0
    @Published var totalBalance: Double = 0.0
    @Published var balanceInUSD: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasMoreTransactions: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private let bitcoinRateService = BitcoinRateService.shared
    private let context = CoreDataStack.shared.context
    
    private var currentPage = 0
    private let pageSize = 20
    
    init() {
        setupBindings()
        loadInitialData()
    }
    
    private func setupBindings() {
        // Bitcoin rate updates
        bitcoinRateService.$currentRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.currentBitcoinRate = rate
                self?.updateBalanceInUSD()
            }
            .store(in: &cancellables)
    }
    
    func loadTransactions() {
        isLoading = true
        errorMessage = nil
        
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = pageSize
        request.fetchOffset = currentPage * pageSize
        
        do {
            let entities = try context.fetch(request)
            let newTransactions = entities.map { Transaction(from: $0) }
            
            if currentPage == 0 {
                transactions = newTransactions
            } else {
                transactions.append(contentsOf: newTransactions)
            }
            
            hasMoreTransactions = newTransactions.count == pageSize
            calculateBalance()
            
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    

    

    
    private func calculateBalance() {
        totalBalance = transactions.reduce(0) { result, transaction in
            switch transaction.type {
            case .income:
                return result + transaction.amountBTC
            case .expense:
                return result - transaction.amountBTC
            }
        }
        updateBalanceInUSD()
    }
    
    private func updateBalanceInUSD() {
        balanceInUSD = totalBalance * currentBitcoinRate
    }
    
    private func loadInitialData() {
        print("DashboardViewModel: Loading initial data")
        loadTransactions()
    }
}

// MARK: - Public Methods

extension DashboardViewModel {
    
    func refresh() {
        print("DashboardViewModel: Refreshing data")
        isRefreshing = true
        currentPage = 0
        
        loadInitialData()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isRefreshing = false
        }
    }
    
    func loadMoreTransactions() {
        guard hasMoreTransactions && !isLoading else {
            print("DashboardViewModel: Cannot load more transactions - hasMore: \(hasMoreTransactions), isLoading: \(isLoading)")
            return
        }
        
        print("DashboardViewModel: Loading more transactions - page \(currentPage + 1)")
        currentPage += 1
        loadTransactions()
    }
    
    func refreshBitcoinRate() {
        print("DashboardViewModel: Manually refreshing Bitcoin rate")
        bitcoinRateService.fetchBitcoinRate()
    }
}

// MARK: - Private Methods

extension DashboardViewModel {
    
    private func handleError(_ error: Error, context: String) {
        let message = "\(context): \(error.localizedDescription)"
        errorMessage = message
        print("DashboardViewModel: Error - \(message)")
        
        // Clear error message after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.errorMessage == message {
                self?.errorMessage = nil
            }
        }
    }
}

// MARK: - Computed Properties

extension DashboardViewModel {
    
    var formattedBitcoinRate: String {
        return "$\(String(format: "%.2f", currentBitcoinRate))"
    }
    
    var formattedBalance: String {
        return String(format: "%.8f BTC", totalBalance)
    }
    
    // balanceInUSD is now a @Published property that gets automatically updated
    
    var formattedBalanceInUSD: String {
        return "$\(String(format: "%.2f", balanceInUSD))"
    }
    
    var recentTransactions: [Transaction] {
        return Array(transactions.prefix(5))
    }
    
    var hasTransactions: Bool {
        return !transactions.isEmpty
    }
    
    var hasError: Bool {
        return errorMessage != nil
    }
}

// MARK: - Filtering Methods

extension DashboardViewModel {
    
    func filterTransactions(by type: TransactionType) {
        print("DashboardViewModel: Filtering transactions by \(type.displayName)")
        // TODO: Implement filtering when use cases are available
        loadTransactions()
    }
    
    func filterTransactions(by category: String) {
        print("DashboardViewModel: Filtering transactions by category '\(category)'")
        // TODO: Implement filtering when use cases are available
        loadTransactions()
    }
    
    func clearFilters() {
        print("DashboardViewModel: Clearing filters")
        currentPage = 0
        loadInitialData()
    }
} 