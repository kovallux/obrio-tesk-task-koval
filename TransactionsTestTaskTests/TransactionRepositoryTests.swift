//
//  TransactionRepositoryTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
import CoreData
@testable import TransactionsTestTask

class TransactionRepositoryTests: XCTestCase {
    
    var sut: TransactionRepository!
    var mockCoreDataStack: MockCoreDataStack!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        sut = TransactionRepository(coreDataStack: mockCoreDataStack)
    }
    
    override func tearDown() {
        sut = nil
        mockCoreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Save Transaction Tests
    
    func testSaveTransaction() throws {
        // Given
        let transaction = Transaction(
            id: UUID(),
            amountBTC: 0.001,
            category: "Food",
            timestamp: Date(),
            type: .expense
        )
        
        // When
        try sut.save(transaction)
        
        // Then
        let savedTransactions = try sut.fetchAllTransactions()
        XCTAssertEqual(savedTransactions.count, 1)
        XCTAssertEqual(savedTransactions.first?.id, transaction.id)
        XCTAssertEqual(savedTransactions.first?.amountBTC, transaction.amountBTC)
        XCTAssertEqual(savedTransactions.first?.category, transaction.category)
        XCTAssertEqual(savedTransactions.first?.type, transaction.type)
    }
    
    func testSaveMultipleTransactions() throws {
        // Given
        let transactions = [
            Transaction(id: UUID(), amountBTC: 0.001, category: "Food", timestamp: Date(), type: .expense),
            Transaction(id: UUID(), amountBTC: 0.002, category: "Transport", timestamp: Date(), type: .expense),
            Transaction(id: UUID(), amountBTC: 0.1, category: "Salary", timestamp: Date(), type: .income)
        ]
        
        // When
        for transaction in transactions {
            try sut.save(transaction)
        }
        
        // Then
        let savedTransactions = try sut.fetchAllTransactions()
        XCTAssertEqual(savedTransactions.count, 3)
    }
    
    func testSaveDuplicateTransaction() throws {
        // Given
        let transaction = Transaction(
            id: UUID(),
            amountBTC: 0.001,
            category: "Food",
            timestamp: Date(),
            type: .expense
        )
        
        // When
        try sut.save(transaction)
        try sut.save(transaction) // Save same transaction again
        
        // Then
        let savedTransactions = try sut.fetchAllTransactions()
        XCTAssertEqual(savedTransactions.count, 1) // Should not create duplicate
    }
    
    // MARK: - Fetch Transactions Tests
    
    func testFetchAllTransactions() throws {
        // Given
        let transactions = createSampleTransactions(count: 5)
        for transaction in transactions {
            try sut.save(transaction)
        }
        
        // When
        let fetchedTransactions = try sut.fetchAllTransactions()
        
        // Then
        XCTAssertEqual(fetchedTransactions.count, 5)
    }
    
    func testFetchTransactionsWithPagination() throws {
        // Given
        let transactions = createSampleTransactions(count: 10)
        for transaction in transactions {
            try sut.save(transaction)
        }
        
        // When
        let firstPage = try sut.fetchTransactions(page: 0, pageSize: 3)
        let secondPage = try sut.fetchTransactions(page: 1, pageSize: 3)
        
        // Then
        XCTAssertEqual(firstPage.count, 3)
        XCTAssertEqual(secondPage.count, 3)
        
        // Verify no overlap
        let firstPageIds = Set(firstPage.map { $0.id })
        let secondPageIds = Set(secondPage.map { $0.id })
        XCTAssertTrue(firstPageIds.isDisjoint(with: secondPageIds))
    }
    
    func testFetchTransactionsEmptyResult() throws {
        // Given - No transactions saved
        
        // When
        let transactions = try sut.fetchAllTransactions()
        
        // Then
        XCTAssertEqual(transactions.count, 0)
    }
    
    // MARK: - Grouped Transactions Tests
    
    func testFetchTransactionsGroupedByDay() throws {
        // Given
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let todayTransactions = [
            Transaction(id: UUID(), amountBTC: 0.001, category: "Food", timestamp: today, type: .expense),
            Transaction(id: UUID(), amountBTC: 0.002, category: "Transport", timestamp: today, type: .expense)
        ]
        
        let yesterdayTransactions = [
            Transaction(id: UUID(), amountBTC: 0.1, category: "Salary", timestamp: yesterday, type: .income)
        ]
        
        for transaction in todayTransactions + yesterdayTransactions {
            try sut.save(transaction)
        }
        
        // When
        let groupedTransactions = try sut.fetchTransactionsGroupedByDay()
        
        // Then
        XCTAssertEqual(groupedTransactions.keys.count, 2)
        
        let todayKey = Transaction.dayKeyFormatter.string(from: today)
        let yesterdayKey = Transaction.dayKeyFormatter.string(from: yesterday)
        
        XCTAssertEqual(groupedTransactions[todayKey]?.count, 2)
        XCTAssertEqual(groupedTransactions[yesterdayKey]?.count, 1)
    }
    
    // MARK: - Balance Tests
    
    func testGetTotalBalance() throws {
        // Given
        let transactions = [
            Transaction(id: UUID(), amountBTC: 0.1, category: "Salary", timestamp: Date(), type: .income),
            Transaction(id: UUID(), amountBTC: 0.05, category: "Freelance", timestamp: Date(), type: .income),
            Transaction(id: UUID(), amountBTC: 0.02, category: "Food", timestamp: Date(), type: .expense),
            Transaction(id: UUID(), amountBTC: 0.01, category: "Transport", timestamp: Date(), type: .expense)
        ]
        
        for transaction in transactions {
            try sut.save(transaction)
        }
        
        // When
        let balance = try sut.getTotalBalance()
        
        // Then
        let expectedBalance = 0.1 + 0.05 - 0.02 - 0.01 // 0.12
        XCTAssertEqual(balance, expectedBalance, accuracy: 0.0001)
    }
    
    func testGetTotalBalanceWithNoTransactions() throws {
        // Given - No transactions
        
        // When
        let balance = try sut.getTotalBalance()
        
        // Then
        XCTAssertEqual(balance, 0.0)
    }
    
    func testGetTotalBalanceWithOnlyExpenses() throws {
        // Given
        let transactions = [
            Transaction(id: UUID(), amountBTC: 0.02, category: "Food", timestamp: Date(), type: .expense),
            Transaction(id: UUID(), amountBTC: 0.01, category: "Transport", timestamp: Date(), type: .expense)
        ]
        
        for transaction in transactions {
            try sut.save(transaction)
        }
        
        // When
        let balance = try sut.getTotalBalance()
        
        // Then
        XCTAssertEqual(balance, -0.03, accuracy: 0.0001)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveTransactionWithInvalidData() {
        // Given
        let transaction = Transaction(
            id: UUID(),
            amountBTC: -1.0, // Invalid negative amount
            category: "",
            timestamp: Date(),
            type: .expense
        )
        
        // When & Then
        XCTAssertThrowsError(try sut.save(transaction)) { error in
            // Verify it's the expected error type
            XCTAssertTrue(error is CoreDataError || error is NSError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testSavePerformance() throws {
        let transactions = createSampleTransactions(count: 100)
        
        measure {
            for transaction in transactions {
                try! sut.save(transaction)
            }
        }
    }
    
    func testFetchPerformance() throws {
        // Given
        let transactions = createSampleTransactions(count: 1000)
        for transaction in transactions {
            try sut.save(transaction)
        }
        
        // When & Then
        measure {
            _ = try! sut.fetchAllTransactions()
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSampleTransactions(count: Int) -> [Transaction] {
        var transactions: [Transaction] = []
        
        for i in 0..<count {
            let transaction = Transaction(
                id: UUID(),
                amountBTC: Double(i) * 0.001,
                category: "Category \(i % 5)",
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)), // Spread over hours
                type: i % 2 == 0 ? .income : .expense
            )
            transactions.append(transaction)
        }
        
        return transactions
    }
}

// MARK: - Mock Core Data Stack

class MockCoreDataStack: CoreDataStack {
    
    override init() {
        super.init()
        setupInMemoryStore()
    }
    
    private func setupInMemoryStore() {
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
    }
}

// MARK: - Core Data Error

enum CoreDataError: Error {
    case invalidData
    case saveFailed
    case fetchFailed
} 