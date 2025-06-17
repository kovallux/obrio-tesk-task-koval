//
//  DashboardViewModelTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 17.06.2025.
//

import XCTest
import Combine
import CoreData
@testable import TransactionsTestTask

final class DashboardViewModelTests: XCTestCase {
    
    var viewModel: DashboardViewModel!
    var cancellables: Set<AnyCancellable>!
    var mockContext: NSManagedObjectContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create in-memory Core Data stack for testing
        let container = NSPersistentContainer(name: "TransactionsTestTask")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        mockContext = container.viewContext
        cancellables = Set<AnyCancellable>()
        
        // Initialize viewModel after setting up context
        viewModel = DashboardViewModel()
    }
    
    override func tearDownWithError() throws {
        viewModel = nil
        cancellables = nil
        mockContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testViewModelInitialization() {
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.transactions.count, 0)
        XCTAssertEqual(viewModel.currentBitcoinRate, 0.0)
        XCTAssertEqual(viewModel.totalBalance, 0.0)
        XCTAssertEqual(viewModel.balanceInUSD, 0.0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.hasMoreTransactions)
    }
    
    // MARK: - Balance Calculation Tests
    
    func testBalanceCalculationWithIncomeOnly() {
        // Given
        let incomeTransactions = [
            Transaction(amountBTC: 1.0, category: "Salary", type: .income),
            Transaction(amountBTC: 0.5, category: "Bonus", type: .income)
        ]
        
        // When
        viewModel.transactions = incomeTransactions
        
        // Then
        XCTAssertEqual(viewModel.totalBalance, 1.5)
    }
    
    func testBalanceCalculationWithExpensesOnly() {
        // Given
        let expenseTransactions = [
            Transaction(amountBTC: 0.3, category: "Food", type: .expense),
            Transaction(amountBTC: 0.2, category: "Transport", type: .expense)
        ]
        
        // When
        viewModel.transactions = expenseTransactions
        
        // Then
        XCTAssertEqual(viewModel.totalBalance, -0.5)
    }
    
    func testBalanceCalculationWithMixedTransactions() {
        // Given
        let mixedTransactions = [
            Transaction(amountBTC: 2.0, category: "Salary", type: .income),
            Transaction(amountBTC: 0.5, category: "Food", type: .expense),
            Transaction(amountBTC: 1.0, category: "Bonus", type: .income),
            Transaction(amountBTC: 0.3, category: "Transport", type: .expense)
        ]
        
        // When
        viewModel.transactions = mixedTransactions
        
        // Then
        XCTAssertEqual(viewModel.totalBalance, 2.2, accuracy: 0.001)
    }
    
    // MARK: - Bitcoin Rate Tests
    
    func testBitcoinRateUpdate() {
        // Given
        let expectation = XCTestExpectation(description: "Bitcoin rate updated")
        let testRate = 45000.0
        
        // When
        viewModel.$currentBitcoinRate
            .dropFirst() // Skip initial value
            .sink { rate in
                XCTAssertEqual(rate, testRate)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.currentBitcoinRate = testRate
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testBalanceInUSDCalculation() {
        // Given
        let bitcoinRate = 50000.0
        let btcBalance = 0.1
        
        // When
        viewModel.currentBitcoinRate = bitcoinRate
        viewModel.totalBalance = btcBalance
        
        // Then
        XCTAssertEqual(viewModel.balanceInUSD, 5000.0)
    }
    
    // MARK: - Formatted Properties Tests
    
    func testFormattedBitcoinRate() {
        // Given
        viewModel.currentBitcoinRate = 45123.67
        
        // When
        let formatted = viewModel.formattedBitcoinRate
        
        // Then
        XCTAssertEqual(formatted, "$45123.67")
    }
    
    func testFormattedBalance() {
        // Given
        viewModel.totalBalance = 1.23456789
        
        // When
        let formatted = viewModel.formattedBalance
        
        // Then
        XCTAssertEqual(formatted, "1.23456789 BTC")
    }
    
    func testFormattedBalanceInUSD() {
        // Given
        viewModel.balanceInUSD = 1234.567
        
        // When
        let formatted = viewModel.formattedBalanceInUSD
        
        // Then
        XCTAssertEqual(formatted, "$1234.57")
    }
    
    // MARK: - Transaction Filtering Tests
    
    func testRecentTransactions() {
        // Given
        let transactions = (1...10).map { i in
            Transaction(amountBTC: Double(i), category: "Test\(i)", type: .income)
        }
        
        // When
        viewModel.transactions = transactions
        let recent = viewModel.recentTransactions
        
        // Then
        XCTAssertEqual(recent.count, 5)
        XCTAssertEqual(recent.first?.amountBTC, 1.0)
    }
    
    func testHasTransactions() {
        // Given - empty transactions
        XCTAssertFalse(viewModel.hasTransactions)
        
        // When - add transaction
        viewModel.transactions = [Transaction(amountBTC: 1.0, category: "Test", type: .income)]
        
        // Then
        XCTAssertTrue(viewModel.hasTransactions)
    }
    
    func testHasError() {
        // Given - no error
        XCTAssertFalse(viewModel.hasError)
        
        // When - set error
        viewModel.errorMessage = "Test error"
        
        // Then
        XCTAssertTrue(viewModel.hasError)
    }
    
    // MARK: - Loading States Tests
    
    func testLoadingState() {
        // Given
        let expectation = XCTestExpectation(description: "Loading state changed")
        
        // When
        viewModel.$isLoading
            .dropFirst() // Skip initial value
            .sink { isLoading in
                XCTAssertTrue(isLoading)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.isLoading = true
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRefreshingState() {
        // Given
        let expectation = XCTestExpectation(description: "Refreshing state changed")
        
        // When
        viewModel.$isRefreshing
            .dropFirst() // Skip initial value
            .sink { isRefreshing in
                XCTAssertTrue(isRefreshing)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.isRefreshing = true
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessage() {
        // Given
        let testError = "Network connection failed"
        let expectation = XCTestExpectation(description: "Error message set")
        
        // When
        viewModel.$errorMessage
            .dropFirst() // Skip initial nil value
            .sink { errorMessage in
                XCTAssertEqual(errorMessage, testError)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.errorMessage = testError
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Pagination Tests
    
    func testHasMoreTransactions() {
        // Given
        let expectation = XCTestExpectation(description: "Has more transactions changed")
        
        // When
        viewModel.$hasMoreTransactions
            .dropFirst() // Skip initial value
            .sink { hasMore in
                XCTAssertTrue(hasMore)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        viewModel.hasMoreTransactions = true
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Performance Tests
    
    func testBalanceCalculationPerformance() {
        // Given
        let largeTransactionSet = (1...1000).map { i in
            Transaction(
                amountBTC: Double(i) * 0.001,
                category: "Category\(i % 10)",
                type: i % 2 == 0 ? .income : .expense
            )
        }
        
        // When & Then
        measure {
            viewModel.transactions = largeTransactionSet
            _ = viewModel.totalBalance
        }
    }
} 