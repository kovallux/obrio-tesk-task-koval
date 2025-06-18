//
//  StatisticsViewModel.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine
import CoreData

class StatisticsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var statistics: TransactionStatistics?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedPeriod: StatisticsPeriod = .month
    
    // MARK: - Private Properties
    private let context = CoreDataStack.shared.context
    private let bitcoinRateService = BitcoinRateService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Listen to Bitcoin rate changes for USD calculations
        bitcoinRateService.$currentRate
            .sink { [weak self] _ in
                self?.refreshData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadStatistics() {
        print("StatisticsViewModel: Loading statistics for period: \(selectedPeriod.title)")
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let stats = try self.calculateStatistics(for: self.selectedPeriod)
                
                DispatchQueue.main.async {
                    self.statistics = stats
                    self.isLoading = false
                    print("StatisticsViewModel: Statistics loaded successfully")
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    print("StatisticsViewModel: Error loading statistics: \(error)")
                }
            }
        }
    }
    
    func refreshData() {
        loadStatistics()
    }
    
    func changePeriod(_ period: StatisticsPeriod) {
        print("StatisticsViewModel: Changing period to: \(period.title)")
        selectedPeriod = period
        loadStatistics()
    }
    
    func exportStatistics(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let statistics = statistics else {
            completion(.failure(StatisticsError.noDataAvailable))
            return
        }
        
        DispatchQueue.global(qos: .utility).async {
            do {
                let url = try self.generateStatisticsReport(statistics)
                completion(.success(url))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Private Methods
    private func calculateStatistics(for period: StatisticsPeriod) throws -> TransactionStatistics {
        let dateRange = period.dateRange
        let transactions = try fetchTransactions(in: dateRange)
        
        print("StatisticsViewModel: Calculating statistics for \(transactions.count) transactions")
        
        let totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amountBTC }
        let totalExpenses = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amountBTC }
        let netBalance = totalIncome - totalExpenses
        
        let balanceHistory = calculateBalanceHistory(transactions: transactions, period: period)
        let categoryBreakdown = calculateCategoryBreakdown(transactions: transactions)
        let monthlyTrends = calculateMonthlyTrends(transactions: transactions, period: period)
        let insights = generateInsights(transactions: transactions, period: period)
        
        return TransactionStatistics(
            period: period,
            totalTransactions: transactions.count,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses,
            netBalance: netBalance,
            averageTransactionAmount: transactions.isEmpty ? 0 : transactions.reduce(0) { $0 + abs($1.amountBTC) } / Double(transactions.count),
            largestTransaction: transactions.map { abs($0.amountBTC) }.max() ?? 0,
            smallestTransaction: transactions.map { abs($0.amountBTC) }.min() ?? 0,
            transactionCount: TransactionStatistics.TransactionCount(
                income: transactions.filter { $0.type == .income }.count,
                expense: transactions.filter { $0.type == .expense }.count
            ),
            balanceHistory: balanceHistory,
            categoryBreakdown: categoryBreakdown,
            monthlyTrends: monthlyTrends,
            recentTransactions: Array(transactions.prefix(10)),
            insights: insights,
            bitcoinRate: bitcoinRateService.currentRate
        )
    }
    
    private func fetchTransactions(in dateRange: DateInterval) throws -> [Transaction] {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            dateRange.start as NSDate,
            dateRange.end as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        let entities = try context.fetch(request)
        return entities.compactMap { Transaction(from: $0) }
    }
    
    private func calculateBalanceHistory(transactions: [Transaction], period: StatisticsPeriod) -> [BalanceDataPoint] {
        let calendar = Calendar.current
        let dateRange = period.dateRange
        var dataPoints: [BalanceDataPoint] = []
        var runningBalance: Double = 0
        
        // Group transactions by day
        let groupedTransactions = Dictionary(grouping: transactions) { transaction in
            calendar.startOfDay(for: transaction.timestamp)
        }
        
        // Generate data points for each day in the period
        var currentDate = dateRange.start
        while currentDate <= dateRange.end {
            let dayStart = calendar.startOfDay(for: currentDate)
            
            if let dayTransactions = groupedTransactions[dayStart] {
                let dayBalance = dayTransactions.reduce(0) { result, transaction in
                    return result + (transaction.type == .income ? transaction.amountBTC : -transaction.amountBTC)
                }
                runningBalance += dayBalance
            }
            
            dataPoints.append(BalanceDataPoint(
                date: currentDate,
                balance: runningBalance,
                balanceUSD: runningBalance * bitcoinRateService.currentRate
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return dataPoints
    }
    
    private func calculateCategoryBreakdown(transactions: [Transaction]) -> [CategoryData] {
        let groupedByCategory = Dictionary(grouping: transactions) { $0.category }
        let totalAmount = transactions.reduce(0) { $0 + abs($1.amountBTC) }
        
        return groupedByCategory.map { category, categoryTransactions in
            let categoryTotal = categoryTransactions.reduce(0) { $0 + abs($1.amountBTC) }
            let percentage = totalAmount > 0 ? (categoryTotal / totalAmount) * 100 : 0
            
            return CategoryData(
                category: category,
                totalAmount: categoryTotal,
                transactionCount: categoryTransactions.count,
                averageAmount: categoryTotal / Double(categoryTransactions.count),
                percentage: percentage
            )
        }.sorted { $0.totalAmount > $1.totalAmount }
    }
    
    private func calculateMonthlyTrends(transactions: [Transaction], period: StatisticsPeriod) -> [MonthlyTrendData] {
        let calendar = Calendar.current
        let groupedByMonth = Dictionary(grouping: transactions) { transaction in
            calendar.dateInterval(of: .month, for: transaction.timestamp)?.start ?? transaction.timestamp
        }
        
        return groupedByMonth.map { month, monthTransactions in
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amountBTC }
            let expenses = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amountBTC }
            
            return MonthlyTrendData(
                month: month,
                income: income,
                expenses: expenses,
                netChange: income - expenses,
                transactionCount: monthTransactions.count
            )
        }.sorted { $0.month < $1.month }
    }
    
    private func generateInsights(transactions: [Transaction], period: StatisticsPeriod) -> [StatisticsInsight] {
        var insights: [StatisticsInsight] = []
        
        // Top spending category
        let categoryBreakdown = calculateCategoryBreakdown(transactions: transactions)
        if let topCategory = categoryBreakdown.first {
            insights.append(StatisticsInsight(
                type: .topCategory,
                title: "Top Category",
                description: "\(topCategory.category) accounts for \(topCategory.formattedPercentage) of your transactions",
                value: topCategory.totalAmount,
                trend: .neutral
            ))
        }
        
        // Average transaction insight
        let averageAmount = transactions.isEmpty ? 0 : transactions.reduce(0) { $0 + abs($1.amountBTC) } / Double(transactions.count)
        insights.append(StatisticsInsight(
            type: .averageTransaction,
            title: "Average Transaction",
            description: "Your average transaction amount this \(period.title.lowercased())",
            value: averageAmount,
            trend: .neutral
        ))
        
        // Spending trend (simplified)
        let expenses = transactions.filter { $0.type == .expense }
        let trend: StatisticsInsight.Trend = expenses.count > transactions.count / 2 ? .increasing : .decreasing
        
        insights.append(StatisticsInsight(
            type: .spendingTrend,
            title: "Spending Trend",
            description: expenses.count > transactions.count / 2 ? "You've been spending more frequently" : "Your spending has decreased",
            value: expenses.reduce(0) { $0 + $1.amountBTC },
            trend: trend
        ))
        
        return insights
    }
    
    private func generateStatisticsReport(_ statistics: TransactionStatistics) throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "statistics_\(Date().timeIntervalSince1970).txt"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        var reportContent = """
        Transaction Statistics Report
        Generated: \(Date())
        Period: \(statistics.period.title)
        
        SUMMARY
        -------
        Total Transactions: \(statistics.totalTransactions)
        Net Balance: \(statistics.formattedNetBalance) (\(statistics.formattedNetBalanceUSD))
        Total Income: \(statistics.formattedTotalIncome) (\(statistics.formattedTotalIncomeUSD))
        Total Expenses: \(statistics.formattedTotalExpenses) (\(statistics.formattedTotalExpensesUSD))
        Average Transaction: \(String(format: "%.6f BTC", statistics.averageTransactionAmount))
        
        CATEGORY BREAKDOWN
        ------------------
        """
        
        for category in statistics.categoryBreakdown {
            reportContent += "\n\(category.category): \(category.formattedTotalAmount) (\(category.formattedPercentage))"
        }
        
        reportContent += "\n\nINSIGHTS\n--------"
        for insight in statistics.insights {
            reportContent += "\n\(insight.title): \(insight.description)"
        }
        
        try reportContent.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
}

// MARK: - Errors
enum StatisticsError: Error, LocalizedError {
    case noDataAvailable
    case calculationFailed
    case exportFailed
    
    var errorDescription: String? {
        switch self {
        case .noDataAvailable:
            return "No statistics data available"
        case .calculationFailed:
            return "Failed to calculate statistics"
        case .exportFailed:
            return "Failed to export statistics"
        }
    }
} 