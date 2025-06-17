//
//  AddTransactionViewModelTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
import Combine
import CoreData
@testable import TransactionsTestTask

final class AddTransactionViewModelTests: XCTestCase {
    
    var sut: AddTransactionViewModel!
    var mockCoreDataStack: MockCoreDataStack!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockCoreDataStack = MockCoreDataStack()
        CoreDataStack.shared = mockCoreDataStack
        cancellables = Set<AnyCancellable>()
        sut = AddTransactionViewModel()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        mockCoreDataStack = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Then
        XCTAssertEqual(sut.amount, "")
        XCTAssertEqual(sut.category, "")
        XCTAssertEqual(sut.transactionType, .expense)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isValid)
        XCTAssertEqual(sut.amountText, "")
        XCTAssertEqual(sut.customCategory, "")
        XCTAssertEqual(sut.selectedCategory, "")
        XCTAssertNil(sut.amountError)
        XCTAssertNil(sut.categoryError)
        XCTAssertFalse(sut.isTransactionAdded)
    }
    
    // MARK: - Validation Tests
    
    func testValidationWithValidInput() {
        // Given
        let expectation = XCTestExpectation(description: "Validation should pass")
        
        // When
        sut.$isValid
            .dropFirst()
            .sink { isValid in
                XCTAssertTrue(isValid)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.amount = "1.5"
        sut.category = "Food"
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testValidationWithEmptyAmount() {
        // Given
        sut.amount = ""
        sut.category = "Food"
        
        // When & Then
        XCTAssertFalse(sut.isValid)
    }
    
    func testValidationWithInvalidAmount() {
        // Given
        sut.amount = "invalid"
        sut.category = "Food"
        
        // When & Then
        XCTAssertFalse(sut.isValid)
    }
    
    func testValidationWithZeroAmount() {
        // Given
        sut.amount = "0"
        sut.category = "Food"
        
        // When & Then
        XCTAssertFalse(sut.isValid)
    }
    
    func testValidationWithNegativeAmount() {
        // Given
        sut.amount = "-1.5"
        sut.category = "Food"
        
        // When & Then
        XCTAssertFalse(sut.isValid)
    }
    
    func testValidationWithEmptyCategory() {
        // Given
        sut.amount = "1.5"
        sut.category = ""
        
        // When & Then
        XCTAssertFalse(sut.isValid)
    }
    
    // MARK: - Category Management Tests
    
    func testIncomeCategoriesForIncomeType() {
        // Given
        sut.transactionType = .income
        
        // When
        let categories = sut.categories
        
        // Then
        XCTAssertEqual(categories, sut.incomeCategories)
        XCTAssertTrue(categories.contains("Salary"))
        XCTAssertTrue(categories.contains("Bonus"))
        XCTAssertTrue(categories.contains("Investment"))
    }
    
    func testExpenseCategoriesForExpenseType() {
        // Given
        sut.transactionType = .expense
        
        // When
        let categories = sut.categories
        
        // Then
        XCTAssertEqual(categories, sut.expenseCategories)
        XCTAssertTrue(categories.contains("Food"))
        XCTAssertTrue(categories.contains("Transport"))
        XCTAssertTrue(categories.contains("Entertainment"))
    }
    
    func testSelectCategory() {
        // Given
        let testCategory = "Food"
        
        // When
        sut.selectCategory(testCategory)
        
        // Then
        XCTAssertEqual(sut.selectedCategory, testCategory)
        XCTAssertEqual(sut.category, testCategory)
    }
    
    // MARK: - Transaction Type Tests
    
    func testSetTransactionType() {
        // Given
        let initialType = sut.transactionType
        
        // When
        sut.setTransactionType(.income)
        
        // Then
        XCTAssertNotEqual(sut.transactionType, initialType)
        XCTAssertEqual(sut.transactionType, .income)
    }
    
    func testToggleTransactionType() {
        // Given
        sut.transactionType = .expense
        
        // When
        sut.toggleTransactionType()
        
        // Then
        XCTAssertEqual(sut.transactionType, .income)
        
        // When - Toggle again
        sut.toggleTransactionType()
        
        // Then
        XCTAssertEqual(sut.transactionType, .expense)
    }
    
    // MARK: - Input Binding Tests
    
    func testAmountTextBinding() {
        // Given
        let testAmount = "2.5"
        let expectation = XCTestExpectation(description: "Amount should be updated")
        
        // When
        sut.$amount
            .dropFirst()
            .sink { amount in
                XCTAssertEqual(amount, testAmount)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.amountText = testAmount
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCustomCategoryBinding() {
        // Given
        let testCategory = "Custom Category"
        let expectation = XCTestExpectation(description: "Category should be updated")
        
        // When
        sut.$category
            .dropFirst()
            .sink { category in
                XCTAssertEqual(category, testCategory)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.customCategory = testCategory
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Quick Actions Tests
    
    func testAddQuickExpense() {
        // Given
        let amount = 0.05
        let category = "Food"
        let expectation = XCTestExpectation(description: "Quick expense should be added")
        
        // When
        sut.$isTransactionAdded
            .dropFirst()
            .sink { isAdded in
                XCTAssertTrue(isAdded)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.addQuickExpense(amount: amount, category: category)
        
        // Then
        XCTAssertEqual(sut.amount, String(amount))
        XCTAssertEqual(sut.category, category)
        XCTAssertEqual(sut.transactionType, .expense)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddQuickIncome() {
        // Given
        let amount = 1.0
        let category = "Salary"
        let expectation = XCTestExpectation(description: "Quick income should be added")
        
        // When
        sut.$isTransactionAdded
            .dropFirst()
            .sink { isAdded in
                XCTAssertTrue(isAdded)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.addQuickIncome(amount: amount, category: category)
        
        // Then
        XCTAssertEqual(sut.amount, String(amount))
        XCTAssertEqual(sut.category, category)
        XCTAssertEqual(sut.transactionType, .income)
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddRefill() {
        // Given
        let amount = 2.0
        let expectation = XCTestExpectation(description: "Refill should be added")
        
        // When
        sut.$isTransactionAdded
            .dropFirst()
            .sink { isAdded in
                XCTAssertTrue(isAdded)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        sut.addRefill(amount: amount)
        
        // Then
        XCTAssertEqual(sut.amount, String(amount))
        XCTAssertEqual(sut.category, "Refill")
        XCTAssertEqual(sut.transactionType, .income)
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Preset Amounts Tests
    
    func testPresetAmounts() {
        // When
        let presetAmounts = sut.presetAmounts
        
        // Then
        let expectedAmounts = [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0]
        XCTAssertEqual(presetAmounts, expectedAmounts)
    }
    
    func testSelectPresetAmount() {
        // Given
        let presetAmount = 0.05
        
        // When
        sut.selectPresetAmount(presetAmount)
        
        // Then
        XCTAssertEqual(sut.amount, String(presetAmount))
    }
    
    func testFormattedPresetAmounts() {
        // When
        let formattedAmounts = sut.formattedPresetAmounts
        
        // Then
        XCTAssertEqual(formattedAmounts.count, sut.presetAmounts.count)
        XCTAssertEqual(formattedAmounts.first, "0.001 BTC")
        XCTAssertEqual(formattedAmounts.last, "1.000 BTC")
    }
    
    // MARK: - Transaction Creation Tests
    
    func testAddTransactionSuccess() {
        // Given
        sut.amount = "1.5"
        sut.category = "Food"
        sut.transactionType = .expense
        
        let expectation = XCTestExpectation(description: "Transaction should be added successfully")
        
        // When
        sut.addTransaction()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Expected success but got failure")
                    }
                },
                receiveValue: {
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        // Verify transaction was saved
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        do {
            let savedTransactions = try mockCoreDataStack.context.fetch(request)
            XCTAssertEqual(savedTransactions.count, 1)
            XCTAssertEqual(savedTransactions.first?.amountBTC, 1.5)
            XCTAssertEqual(savedTransactions.first?.category, "Food")
            XCTAssertEqual(savedTransactions.first?.type, TransactionType.expense.rawValue)
        } catch {
            XCTFail("Failed to fetch saved transactions: \(error)")
        }
    }
    
    func testAddTransactionWithInvalidInput() {
        // Given
        sut.amount = ""
        sut.category = "Food"
        
        let expectation = XCTestExpectation(description: "Transaction should fail with invalid input")
        
        // When
        sut.addTransaction()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error.localizedDescription.contains("Invalid input"))
                        expectation.fulfill()
                    }
                },
                receiveValue: {
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testAddTransactionWithInvalidAmount() {
        // Given
        sut.amount = "invalid"
        sut.category = "Food"
        
        let expectation = XCTestExpectation(description: "Transaction should fail with invalid amount")
        
        // When
        sut.addTransaction()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error.localizedDescription.contains("Invalid amount"))
                        expectation.fulfill()
                    }
                },
                receiveValue: {
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Setter Methods Tests
    
    func testSetAmount() {
        // Given
        let testAmount = "3.14"
        
        // When
        sut.setAmount(testAmount)
        
        // Then
        XCTAssertEqual(sut.amount, testAmount)
    }
    
    func testSetCategory() {
        // Given
        let testCategory = "Transport"
        
        // When
        sut.setCategory(testCategory)
        
        // Then
        XCTAssertEqual(sut.category, testCategory)
    }
    
    func testSetTransactionTypeMethod() {
        // Given
        let testType = TransactionType.income
        
        // When
        sut.setTransactionType(testType)
        
        // Then
        XCTAssertEqual(sut.transactionType, testType)
    }
}

// MARK: - Mock Classes

class MockCoreDataStack: CoreDataStack {
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
} 