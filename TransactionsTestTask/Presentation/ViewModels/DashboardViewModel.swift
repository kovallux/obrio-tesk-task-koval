//
//  DashboardViewModel.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

final class DashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentBitcoinRate: Double = 0.0
    @Published var transactions: [Transaction] = []
    @Published var groupedTransactions: [String: [Transaction]] = [:]
    @Published var totalBalance: Double = 0.0
    @Published var balanceInUSD: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isRefreshing: Bool = false
    
    // MARK: - Pagination Properties
    
    @Published var currentPage: Int = 0
    @Published var hasMoreTransactions: Bool = true
    private let pageSize: Int = 20
    
    // MARK: - Statistics Properties
    
    @Published var transactionStatistics: TransactionStatistics?
    @Published var categoryBreakdown: [CategoryBreakdown] = []
    
    // MARK: - Use Cases
    
    private let fetchTransactionsUseCase: FetchTransactionsUseCaseProtocol
    private let updateBitcoinRateUseCase: UpdateBitcoinRateUseCaseProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(
        fetchTransactionsUseCase: FetchTransactionsUseCaseProtocol = FetchTransactionsUseCase(),
        updateBitcoinRateUseCase: UpdateBitcoinRateUseCaseProtocol = UpdateBitcoinRateUseCase()
    ) {
        self.fetchTransactionsUseCase = fetchTransactionsUseCase
        self.updateBitcoinRateUseCase = updateBitcoinRateUseCase
        
        print("DashboardViewModel: Initialized")
        setupBindings()
        loadInitialData()
    }
    
    deinit {
        updateBitcoinRateUseCase.stopPeriodicUpdates()
        print("DashboardViewModel: Deinitialized")
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        print("DashboardViewModel: Setting up bindings")
        
        // Bind Bitcoin rate updates
        updateBitcoinRateUseCase.startPeriodicUpdates()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] rate in
                    self?.currentBitcoinRate = rate
                    print("DashboardViewModel: Bitcoin rate updated to $\(String(format: "%.2f", rate))")
                }
            )
            .store(in: &cancellables)
        
        // Bind balance in USD calculation
        Publishers.CombineLatest($totalBalance, $currentBitcoinRate)
            .map { balance, rate in
                return balance * rate
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$balanceInUSD)
    }
    
    private func loadInitialData() {
        print("DashboardViewModel: Loading initial data")
        isLoading = true
        
        let fetchTransactionsPublisher = fetchTransactionsUseCase.execute(page: 0, pageSize: pageSize)
        let fetchBalancePublisher = fetchTransactionsUseCase.getTotalBalance()
        let getCurrentRatePublisher = updateBitcoinRateUseCase.getCurrentRate()
        
        Publishers.Zip3(fetchTransactionsPublisher, fetchBalancePublisher, getCurrentRatePublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] (transactions, balance, rate) in
                    self?.transactions = transactions
                    self?.totalBalance = balance
                    self?.currentBitcoinRate = rate
                    self?.hasMoreTransactions = transactions.count == self?.pageSize
                    
                    print("DashboardViewModel: Initial data loaded - \(transactions.count) transactions, balance: \(balance) BTC, rate: $\(String(format: "%.2f", rate))")
                    
                    // Load additional data
                    self?.loadGroupedTransactions()
                    self?.loadStatistics()
                }
            )
            .store(in: &cancellables)
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
        isLoading = true
        
        fetchTransactionsUseCase.execute(page: currentPage + 1, pageSize: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error, context: "Loading more transactions")
                    }
                },
                receiveValue: { [weak self] newTransactions in
                    guard let self = self else { return }
                    
                    self.transactions.append(contentsOf: newTransactions)
                    self.currentPage += 1
                    self.hasMoreTransactions = newTransactions.count == self.pageSize
                    
                    print("DashboardViewModel: Loaded \(newTransactions.count) more transactions, total: \(self.transactions.count)")
                }
            )
            .store(in: &cancellables)
    }
    
    func refreshBitcoinRate() {
        print("DashboardViewModel: Manually refreshing Bitcoin rate")
        
        updateBitcoinRateUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error, context: "Manual Bitcoin rate refresh")
                    }
                },
                receiveValue: { [weak self] rate in
                    self?.currentBitcoinRate = rate
                    print("DashboardViewModel: Bitcoin rate manually refreshed to $\(String(format: "%.2f", rate))")
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Private Methods

extension DashboardViewModel {
    
    private func loadGroupedTransactions() {
        print("DashboardViewModel: Loading grouped transactions")
        
        fetchTransactionsUseCase.executeGroupedByDay()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error, context: "Loading grouped transactions")
                    }
                },
                receiveValue: { [weak self] grouped in
                    self?.groupedTransactions = grouped
                    print("DashboardViewModel: Grouped transactions loaded - \(grouped.keys.count) days")
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadStatistics() {
        print("DashboardViewModel: Loading statistics")
        
        let statisticsPublisher = fetchTransactionsUseCase.getTransactionStatistics()
        let categoryBreakdownPublisher = fetchTransactionsUseCase.getCategoryBreakdown()
        
        Publishers.Zip(statisticsPublisher, categoryBreakdownPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.handleError(error, context: "Loading statistics")
                    }
                },
                receiveValue: { [weak self] (statistics, breakdown) in
                    self?.transactionStatistics = statistics
                    self?.categoryBreakdown = breakdown
                    print("DashboardViewModel: Statistics loaded - \(statistics.totalTransactions) transactions, \(breakdown.count) categories")
                }
            )
            .store(in: &cancellables)
    }
    
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
    
    var sortedGroupedTransactionKeys: [String] {
        return groupedTransactions.keys.sorted(by: >)
    }
}

// MARK: - Filtering Methods

extension DashboardViewModel {
    
    func filterTransactions(by type: TransactionType) {
        print("DashboardViewModel: Filtering transactions by \(type.displayName)")
        isLoading = true
        
        fetchTransactionsUseCase.executeFiltered(by: type, page: 0, pageSize: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error, context: "Filtering transactions by type")
                    }
                },
                receiveValue: { [weak self] filteredTransactions in
                    self?.transactions = filteredTransactions
                    self?.currentPage = 0
                    self?.hasMoreTransactions = filteredTransactions.count == self?.pageSize
                    print("DashboardViewModel: Filtered to \(filteredTransactions.count) \(type.displayName) transactions")
                }
            )
            .store(in: &cancellables)
    }
    
    func filterTransactions(by category: String) {
        print("DashboardViewModel: Filtering transactions by category '\(category)'")
        isLoading = true
        
        fetchTransactionsUseCase.executeFilteredByCategory(category, page: 0, pageSize: pageSize)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.handleError(error, context: "Filtering transactions by category")
                    }
                },
                receiveValue: { [weak self] filteredTransactions in
                    self?.transactions = filteredTransactions
                    self?.currentPage = 0
                    self?.hasMoreTransactions = filteredTransactions.count == self?.pageSize
                    print("DashboardViewModel: Filtered to \(filteredTransactions.count) transactions for category '\(category)'")
                }
            )
            .store(in: &cancellables)
    }
    
    func clearFilters() {
        print("DashboardViewModel: Clearing filters")
        currentPage = 0
        loadInitialData()
    }
} 