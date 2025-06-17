//
//  TransactionsTestTaskTests.swift
//  TransactionsTestTaskTests
//
//

import XCTest
@testable import TransactionsTestTask

final class TransactionTests: XCTestCase {

    // MARK: - Transaction Model Tests
    
    func testTransactionInitialization() {
        // Given
        let id = UUID()
        let amount = 0.5
        let category = "Food"
        let timestamp = Date()
        let type = TransactionType.expense
        
        // When
        let transaction = Transaction(
            id: id,
            amountBTC: amount,
            category: category,
            timestamp: timestamp,
            type: type
        )
        
        // Then
        XCTAssertEqual(transaction.id, id)
        XCTAssertEqual(transaction.amountBTC, amount)
        XCTAssertEqual(transaction.category, category)
        XCTAssertEqual(transaction.timestamp, timestamp)
        XCTAssertEqual(transaction.type, type)
    }
    
    func testTransactionDefaultValues() {
        // When
        let transaction = Transaction(
            amountBTC: 1.0,
            category: "Test",
            type: .income
        )
        
        // Then
        XCTAssertNotNil(transaction.id)
        XCTAssertTrue(transaction.timestamp.timeIntervalSinceNow < 1.0) // Created recently
    }
    
    func testTransactionTypeProperties() {
        // Given
        let incomeTransaction = Transaction(amountBTC: 1.0, category: "Salary", type: .income)
        let expenseTransaction = Transaction(amountBTC: 0.5, category: "Food", type: .expense)
        
        // Then
        XCTAssertTrue(incomeTransaction.isIncome)
        XCTAssertFalse(incomeTransaction.isExpense)
        XCTAssertFalse(expenseTransaction.isIncome)
        XCTAssertTrue(expenseTransaction.isExpense)
    }
    
    func testTransactionFormattedAmount() {
        // Given
        let transaction = Transaction(amountBTC: 1.23456789, category: "Test", type: .income)
        
        // When
        let formattedAmount = transaction.formattedAmount
        let formattedAmountShort = transaction.formattedAmountShort
        
        // Then
        XCTAssertEqual(formattedAmount, "1.23456789 BTC")
        XCTAssertEqual(formattedAmountShort, "1.2346 BTC")
    }
    
    func testTransactionEquality() {
        // Given
        let id = UUID()
        let transaction1 = Transaction(id: id, amountBTC: 1.0, category: "Test", type: .income)
        let transaction2 = Transaction(id: id, amountBTC: 2.0, category: "Different", type: .expense)
        let transaction3 = Transaction(amountBTC: 1.0, category: "Test", type: .income)
        
        // Then
        XCTAssertEqual(transaction1, transaction2) // Same ID
        XCTAssertNotEqual(transaction1, transaction3) // Different ID
    }
    
    func testTransactionDayKey() {
        // Given
        let calendar = Calendar.current
        let date = calendar.date(from: DateComponents(year: 2024, month: 6, day: 15))!
        let transaction = Transaction(amountBTC: 1.0, category: "Test", timestamp: date, type: .income)
        
        // When
        let dayKey = transaction.dayKey
        
        // Then
        XCTAssertEqual(dayKey, "2024-06-15")
    }
    
    // MARK: - TransactionType Tests
    
    func testTransactionTypeDisplayNames() {
        XCTAssertEqual(TransactionType.income.displayName, "Income")
        XCTAssertEqual(TransactionType.expense.displayName, "Expense")
    }
    
    func testTransactionTypeRawValues() {
        XCTAssertEqual(TransactionType.income.rawValue, "in")
        XCTAssertEqual(TransactionType.expense.rawValue, "out")
    }
    
    func testTransactionTypeFromRawValue() {
        XCTAssertEqual(TransactionType(rawValue: "in"), .income)
        XCTAssertEqual(TransactionType(rawValue: "out"), .expense)
        XCTAssertNil(TransactionType(rawValue: "invalid"))
    }
    
    func testTransactionTypeCaseIterable() {
        let allCases = TransactionType.allCases
        XCTAssertEqual(allCases.count, 2)
        XCTAssertTrue(allCases.contains(.income))
        XCTAssertTrue(allCases.contains(.expense))
    }
}
