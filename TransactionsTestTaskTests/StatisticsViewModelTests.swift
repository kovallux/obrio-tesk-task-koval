//
//  StatisticsViewModelTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
import Combine
import CoreData
@testable import TransactionsTestTask

final class StatisticsViewModelTests: XCTestCase {
    
    var sut: StatisticsViewModel!
    var mockCoreDataStack: MockCoreDataStack!
    var mockBitcoinRateService: MockBitcoinRateService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        mockBitcoinRateService = MockBitcoinRateService()
        cancellables = Set<AnyCancellable>()
        
        // Replace shared instances for testing
        CoreDataStack.shared = mockCoreDataStack
        BitcoinRateService.shared = mockBitcoinRateService
        
        sut = StatisticsViewModel()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockBitcoinRateService = nil
        mockCoreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Then
        XCTAssertNil(sut.statistics)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.selectedPeriod, .month)
    }
    
    // MARK: - Period Selection Tests
    
    func testChangePeriod() {
        // Given
        let newPeriod = StatisticsPeriod.year
        let expectation = XCTestExpectation(description: "Period should change and trigger loading")
        
        // When
        sut.$selectedPeriod
            .dropFirst()
            .sink { period in
                XCTAssertEqual(period, newPeriod)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.changePeriod(newPeriod)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadStatisticsWithDifferentPeriods() {
        // Test each period
        for period in StatisticsPeriod.allCases {
            // Given
            sut.selectedPeriod = period
            let expectation = XCTestExpectation(description: "Statistics should load for \(period.title)")
            
            // When
            sut.$isLoading
                .dropFirst()
                .sink { isLoading in
                    if !isLoading {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            sut.loadStatistics()
            
            // Then
            wait(for: [expectation], timeout: 2.0)
        }
    }
    
    // MARK: - Loading States Tests
    
    func testLoadStatisticsSetsLoadingState() {
        // Given
        let expectation = XCTestExpectation(description: "Loading state should be set")
        
        // When
        sut.$isLoading
            .dropFirst()
            .sink { isLoading in
                XCTAssertTrue(isLoading)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadStatistics()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLoadStatisticsClearsErrorMessage() {
        // Given
        sut.errorMessage = "Previous error"
        let expectation = XCTestExpectation(description: "Error message should be cleared")
        
        // When
        sut.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                XCTAssertNil(errorMessage)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadStatistics()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testLoadStatisticsWithError() {
        // Given
        mockCoreDataStack.shouldThrowError = true
        let expectation = XCTestExpectation(description: "Error should be set")
        
        // When
        sut.$errorMessage
            .compactMap { $0 }
            .sink { errorMessage in
                XCTAssertFalse(errorMessage.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadStatistics()
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Statistics Data Tests
    
    func testLoadStatisticsWithTransactions() {
        // Given
        let transactions = createSampleTransactions()
        saveMockTransactions(transactions)
        let expectation = XCTestExpectation(description: "Statistics should be loaded")
        
        // When
        sut.$statistics
            .compactMap { $0 }
            .sink { statistics in
                XCTAssertNotNil(statistics)
                XCTAssertEqual(statistics.totalTransactions, transactions.count)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadStatistics()
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testStatisticsCalculationWithIncomeAndExpenses() {
        // Given
        let incomeTransaction = createMockTransaction(amount: 1.0, type: .income)
        let expenseTransaction = createMockTransaction(amount: 0.3, type: .expense)
        saveMockTransactions([incomeTransaction, expenseTransaction])
        
        let expectation = XCTestExpectation(description: "Statistics should calculate correctly")
        
        // When
        sut.$statistics
            .compactMap { $0 }
            .sink { statistics in
                XCTAssertEqual(statistics.totalIncome, 1.0, accuracy: 0.0001)
                XCTAssertEqual(statistics.totalExpenses, 0.3, accuracy: 0.0001)
                XCTAssertEqual(statistics.netBalance, 0.7, accuracy: 0.0001)
                XCTAssertEqual(statistics.transactionCount.income, 1)
                XCTAssertEqual(statistics.transactionCount.expense, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.loadStatistics()
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Bitcoin Rate Integration Tests
    
    func testBitcoinRateUpdateTriggersRefresh() {
        // Given
        let expectation = XCTestExpectation(description: "Bitcoin rate change should trigger refresh")
        
        // When
        sut.$isLoading
            .dropFirst()
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockBitcoinRateService.currentRate = 50000.0
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Export Functionality Tests
    
    func testExportStatisticsWithData() {
        // Given
        let transactions = createSampleTransactions()
        saveMockTransactions(transactions)
        sut.loadStatistics()
        
        let expectation = XCTestExpectation(description: "Export should succeed")
        
        // Wait for statistics to load first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // When
            self.sut.exportStatistics { result in
                switch result {
                case .success(let url):
                    XCTAssertNotNil(url)
                    expectation.fulfill()
                case .failure(let error):
                    XCTFail("Export should succeed but got error: \(error)")
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testExportStatisticsWithoutData() {
        // Given - No statistics loaded
        let expectation = XCTestExpectation(description: "Export should fail without data")
        
        // When
        sut.exportStatistics { result in
            switch result {
            case .success:
                XCTFail("Export should fail without data")
            case .failure(let error):
                XCTAssertTrue(error is StatisticsError)
                expectation.fulfill()
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Refresh Data Tests
    
    func testRefreshData() {
        // Given
        let expectation = XCTestExpectation(description: "Refresh should trigger loading")
        
        // When
        sut.$isLoading
            .dropFirst()
            .sink { isLoading in
                if isLoading {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        sut.refreshData()
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createMockTransaction(amount: Double, type: TransactionType, category: String = "Test") -> TransactionEntity {
        let entity = TransactionEntity(context: mockCoreDataStack.context)
        entity.id = UUID()
        entity.amountBTC = amount
        entity.category = category
        entity.type = type.rawValue
        entity.timestamp = Date()
        return entity
    }
    
    private func createSampleTransactions() -> [TransactionEntity] {
        return [
            createMockTransaction(amount: 1.0, type: .income, category: "Salary"),
            createMockTransaction(amount: 0.5, type: .income, category: "Bonus"),
            createMockTransaction(amount: 0.2, type: .expense, category: "Food"),
            createMockTransaction(amount: 0.1, type: .expense, category: "Transport")
        ]
    }
    
    private func saveMockTransactions(_ transactions: [TransactionEntity]) {
        do {
            try mockCoreDataStack.context.save()
        } catch {
            XCTFail("Failed to save mock transactions: \(error)")
        }
    }
}

// MARK: - StatisticsPeriod Tests

final class StatisticsPeriodTests: XCTestCase {
    
    func testAllCases() {
        // When
        let allCases = StatisticsPeriod.allCases
        
        // Then
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.week))
        XCTAssertTrue(allCases.contains(.month))
        XCTAssertTrue(allCases.contains(.threeMonths))
        XCTAssertTrue(allCases.contains(.year))
    }
    
    func testTitles() {
        // Then
        XCTAssertEqual(StatisticsPeriod.week.title, "Week")
        XCTAssertEqual(StatisticsPeriod.month.title, "Month")
        XCTAssertEqual(StatisticsPeriod.threeMonths.title, "3 Months")
        XCTAssertEqual(StatisticsPeriod.year.title, "Year")
    }
    
    func testDateRanges() {
        let now = Date()
        let calendar = Calendar.current
        
        // Week
        let weekRange = StatisticsPeriod.week.dateRange
        XCTAssertTrue(weekRange.end.timeIntervalSince(now) < 60) // Within 1 minute
        XCTAssertTrue(weekRange.duration < 7 * 24 * 60 * 60 + 60) // Less than 7 days + 1 minute
        
        // Month
        let monthRange = StatisticsPeriod.month.dateRange
        XCTAssertTrue(monthRange.end.timeIntervalSince(now) < 60)
        XCTAssertTrue(monthRange.duration < 32 * 24 * 60 * 60) // Less than 32 days
        
        // Three Months
        let threeMonthsRange = StatisticsPeriod.threeMonths.dateRange
        XCTAssertTrue(threeMonthsRange.end.timeIntervalSince(now) < 60)
        XCTAssertTrue(threeMonthsRange.duration > 85 * 24 * 60 * 60) // More than 85 days
        
        // Year
        let yearRange = StatisticsPeriod.year.dateRange
        XCTAssertTrue(yearRange.end.timeIntervalSince(now) < 60)
        XCTAssertTrue(yearRange.duration > 360 * 24 * 60 * 60) // More than 360 days
    }
}

// MARK: - TransactionStatistics Tests

final class TransactionStatisticsTests: XCTestCase {
    
    func testTransactionCount() {
        // Given
        let transactionCount = TransactionStatistics.TransactionCount(income: 5, expense: 3)
        
        // When & Then
        XCTAssertEqual(transactionCount.income, 5)
        XCTAssertEqual(transactionCount.expense, 3)
        XCTAssertEqual(transactionCount.total, 8)
    }
    
    func testFormattedProperties() {
        // Given
        let statistics = TransactionStatistics(
            period: .month,
            totalTransactions: 10,
            totalIncome: 2.5,
            totalExpenses: 1.2,
            netBalance: 1.3,
            averageTransactionAmount: 0.37,
            largestTransaction: 1.5,
            smallestTransaction: 0.1,
            transactionCount: TransactionStatistics.TransactionCount(income: 6, expense: 4),
            balanceHistory: [],
            categoryBreakdown: [],
            monthlyTrends: [],
            recentTransactions: [],
            insights: [],
            bitcoinRate: 50000.0
        )
        
        // When & Then
        XCTAssertEqual(statistics.formattedNetBalance, "1.30000000 BTC")
        XCTAssertEqual(statistics.formattedTotalIncome, "2.50000000 BTC")
        XCTAssertEqual(statistics.formattedTotalExpenses, "1.20000000 BTC")
        
        XCTAssertEqual(statistics.netBalanceUSD, 65000.0)
        XCTAssertEqual(statistics.totalIncomeUSD, 125000.0)
        XCTAssertEqual(statistics.totalExpensesUSD, 60000.0)
        
        XCTAssertEqual(statistics.formattedNetBalanceUSD, "$65000.00")
        XCTAssertEqual(statistics.formattedTotalIncomeUSD, "$125000.00")
        XCTAssertEqual(statistics.formattedTotalExpensesUSD, "$60000.00")
    }
}

// MARK: - BalanceDataPoint Tests

final class BalanceDataPointTests: XCTestCase {
    
    func testFormattedProperties() {
        // Given
        let date = Date()
        let dataPoint = BalanceDataPoint(date: date, balance: 1.23456789, balanceUSD: 61728.39)
        
        // When & Then
        XCTAssertEqual(dataPoint.formattedBalance, "1.234568 BTC")
        XCTAssertEqual(dataPoint.formattedBalanceUSD, "$61728.39")
        XCTAssertFalse(dataPoint.formattedDate.isEmpty)
    }
}

// MARK: - CategoryData Tests

final class CategoryDataTests: XCTestCase {
    
    func testFormattedProperties() {
        // Given
        let categoryData = CategoryData(
            category: "Food",
            totalAmount: 0.123456,
            transactionCount: 5,
            averageAmount: 0.024691,
            percentage: 25.5
        )
        
        // When & Then
        XCTAssertEqual(categoryData.formattedTotalAmount, "0.123456 BTC")
        XCTAssertEqual(categoryData.formattedAverageAmount, "0.024691 BTC")
        XCTAssertEqual(categoryData.formattedPercentage, "25.5%")
    }
}

// MARK: - MonthlyTrendData Tests

final class MonthlyTrendDataTests: XCTestCase {
    
    func testFormattedProperties() {
        // Given
        let date = Date()
        let trendData = MonthlyTrendData(
            month: date,
            income: 2.5,
            expenses: 1.2,
            netChange: 1.3,
            transactionCount: 10
        )
        
        // When & Then
        XCTAssertEqual(trendData.formattedIncome, "2.500000 BTC")
        XCTAssertEqual(trendData.formattedExpenses, "1.200000 BTC")
        XCTAssertEqual(trendData.formattedNetChange, "+1.300000 BTC")
        XCTAssertTrue(trendData.isPositive)
        XCTAssertFalse(trendData.formattedMonth.isEmpty)
    }
    
    func testNegativeNetChange() {
        // Given
        let date = Date()
        let trendData = MonthlyTrendData(
            month: date,
            income: 1.0,
            expenses: 1.5,
            netChange: -0.5,
            transactionCount: 5
        )
        
        // When & Then
        XCTAssertEqual(trendData.formattedNetChange, "-0.500000 BTC")
        XCTAssertFalse(trendData.isPositive)
    }
}

// MARK: - Mock Classes

class MockBitcoinRateService: BitcoinRateService {
    @Published var currentRate: Double = 0.0
    
    var ratePublisher: AnyPublisher<Double, Never> {
        return $currentRate
            .filter { $0 > 0 }
            .eraseToAnyPublisher()
    }
    
    func fetchBitcoinRate() {
        // Mock implementation
    }
    
    func startPeriodicFetch() {
        // Mock implementation
    }
    
    func stopPeriodicFetch() {
        // Mock implementation
    }
}

class MockCoreDataStack: CoreDataStack {
    var shouldThrowError = false
    
    override lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "TransactionsTestTask")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        return container
    }()
    
    override var context: NSManagedObjectContext {
        if shouldThrowError {
            let errorContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            // Make it throw an error when trying to fetch
            return errorContext
        }
        return persistentContainer.viewContext
    }
}

// MARK: - Statistics Error

enum StatisticsError: Error {
    case noDataAvailable
} 