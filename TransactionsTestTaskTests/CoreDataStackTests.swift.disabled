//
//  CoreDataStackTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
import CoreData
@testable import TransactionsTestTask

final class CoreDataStackTests: XCTestCase {
    
    var sut: CoreDataStack!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        sut = CoreDataStack()
        
        // Use in-memory store for testing
        let container = NSPersistentContainer(name: "TransactionsTestTask")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        
        let expectation = XCTestExpectation(description: "Core Data stack should load")
        container.loadPersistentStores { _, error in
            if let error = error {
                XCTFail("Failed to load in-memory store: \(error)")
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        
        testContext = container.viewContext
        
        // Replace the persistent container for testing
        sut.persistentContainer = container
    }
    
    override func tearDown() {
        testContext = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Singleton Tests
    
    func testSingletonInstance() {
        // Given & When
        let instance1 = CoreDataStack.shared
        let instance2 = CoreDataStack.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Initialization Tests
    
    func testCoreDataStackInitialization() {
        // Then
        XCTAssertNotNil(sut.persistentContainer)
        XCTAssertNotNil(sut.context)
        XCTAssertEqual(sut.context, sut.persistentContainer.viewContext)
    }
    
    // MARK: - Entity Creation Tests
    
    func testCreateTransactionEntity() {
        // Given
        let transactionId = UUID()
        let amount = 1.5
        let category = "Food"
        let type = TransactionType.expense.rawValue
        let timestamp = Date()
        
        // When
        let entity = TransactionEntity(context: testContext)
        entity.id = transactionId
        entity.amountBTC = amount
        entity.category = category
        entity.type = type
        entity.timestamp = timestamp
        
        // Then
        XCTAssertEqual(entity.id, transactionId)
        XCTAssertEqual(entity.amountBTC, amount)
        XCTAssertEqual(entity.category, category)
        XCTAssertEqual(entity.type, type)
        XCTAssertEqual(entity.timestamp, timestamp)
    }
    
    // MARK: - Save Context Tests
    
    func testSaveContext() throws {
        // Given
        let entity = createTestTransactionEntity()
        
        // When
        try testContext.save()
        
        // Then
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let savedEntities = try testContext.fetch(request)
        XCTAssertEqual(savedEntities.count, 1)
        XCTAssertEqual(savedEntities.first?.id, entity.id)
    }
    
    func testSaveContextWithoutChanges() {
        // Given - No changes made
        XCTAssertFalse(testContext.hasChanges)
        
        // When & Then - Should not throw
        XCTAssertNoThrow(try testContext.save())
    }
    
    func testSaveContextWithMultipleEntities() throws {
        // Given
        let entities = (0..<5).map { _ in createTestTransactionEntity() }
        
        // When
        try testContext.save()
        
        // Then
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let savedEntities = try testContext.fetch(request)
        XCTAssertEqual(savedEntities.count, entities.count)
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAllEntities() throws {
        // Given
        let entities = (0..<3).map { _ in createTestTransactionEntity() }
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, entities.count)
    }
    
    func testFetchWithPredicate() throws {
        // Given
        let incomeEntity = createTestTransactionEntity(type: .income, category: "Salary")
        let expenseEntity = createTestTransactionEntity(type: .expense, category: "Food")
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", TransactionType.income.rawValue)
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, 1)
        XCTAssertEqual(fetchedEntities.first?.id, incomeEntity.id)
    }
    
    func testFetchWithSortDescriptor() throws {
        // Given
        let oldDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let newDate = Date()
        
        let oldEntity = createTestTransactionEntity(timestamp: oldDate)
        let newEntity = createTestTransactionEntity(timestamp: newDate)
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, 2)
        XCTAssertEqual(fetchedEntities.first?.id, newEntity.id) // Newest first
        XCTAssertEqual(fetchedEntities.last?.id, oldEntity.id)
    }
    
    func testFetchWithLimit() throws {
        // Given
        let entities = (0..<10).map { _ in createTestTransactionEntity() }
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.fetchLimit = 5
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, 5)
    }
    
    func testFetchWithOffset() throws {
        // Given
        let entities = (0..<10).map { index in
            createTestTransactionEntity(amount: Double(index))
        }
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "amountBTC", ascending: true)]
        request.fetchOffset = 3
        request.fetchLimit = 3
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, 3)
        XCTAssertEqual(fetchedEntities.first?.amountBTC, 3.0)
    }
    
    // MARK: - Update Tests
    
    func testUpdateEntity() throws {
        // Given
        let entity = createTestTransactionEntity()
        try testContext.save()
        
        let newCategory = "Updated Category"
        
        // When
        entity.category = newCategory
        try testContext.save()
        
        // Then
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let updatedEntities = try testContext.fetch(request)
        XCTAssertEqual(updatedEntities.first?.category, newCategory)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteEntity() throws {
        // Given
        let entity = createTestTransactionEntity()
        try testContext.save()
        
        // Verify entity exists
        var request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        var entities = try testContext.fetch(request)
        XCTAssertEqual(entities.count, 1)
        
        // When
        testContext.delete(entity)
        try testContext.save()
        
        // Then
        request = TransactionEntity.fetchRequest()
        entities = try testContext.fetch(request)
        XCTAssertEqual(entities.count, 0)
    }
    
    func testDeleteMultipleEntities() throws {
        // Given
        let entities = (0..<5).map { _ in createTestTransactionEntity() }
        try testContext.save()
        
        // When
        entities.forEach { testContext.delete($0) }
        try testContext.save()
        
        // Then
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let remainingEntities = try testContext.fetch(request)
        XCTAssertEqual(remainingEntities.count, 0)
    }
    
    // MARK: - Complex Query Tests
    
    func testComplexPredicateQuery() throws {
        // Given
        let highAmountIncome = createTestTransactionEntity(amount: 2.0, type: .income)
        let lowAmountIncome = createTestTransactionEntity(amount: 0.1, type: .income)
        let highAmountExpense = createTestTransactionEntity(amount: 1.5, type: .expense)
        try testContext.save()
        
        // When - Find income transactions with amount > 1.0
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "type == %@ AND amountBTC > %@",
            TransactionType.income.rawValue,
            NSNumber(value: 1.0)
        )
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, 1)
        XCTAssertEqual(fetchedEntities.first?.id, highAmountIncome.id)
    }
    
    func testDateRangeQuery() throws {
        // Given
        let startDate = Date().addingTimeInterval(-86400) // 1 day ago
        let endDate = Date()
        let middleDate = Date().addingTimeInterval(-43200) // 12 hours ago
        
        let oldEntity = createTestTransactionEntity(timestamp: Date().addingTimeInterval(-172800)) // 2 days ago
        let recentEntity = createTestTransactionEntity(timestamp: middleDate)
        let newEntity = createTestTransactionEntity(timestamp: Date())
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "timestamp >= %@ AND timestamp <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, 2) // recentEntity and newEntity
        let fetchedIds = Set(fetchedEntities.compactMap { $0.id })
        XCTAssertTrue(fetchedIds.contains(recentEntity.id))
        XCTAssertTrue(fetchedIds.contains(newEntity.id))
        XCTAssertFalse(fetchedIds.contains(oldEntity.id))
    }
    
    func testCategoryFilterQuery() throws {
        // Given
        let foodEntity = createTestTransactionEntity(category: "Food")
        let transportEntity = createTestTransactionEntity(category: "Transport")
        let salaryEntity = createTestTransactionEntity(category: "Salary")
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "category IN %@", ["Food", "Transport"])
        let fetchedEntities = try testContext.fetch(request)
        
        // Then
        XCTAssertEqual(fetchedEntities.count, 2)
        let fetchedIds = Set(fetchedEntities.compactMap { $0.id })
        XCTAssertTrue(fetchedIds.contains(foodEntity.id))
        XCTAssertTrue(fetchedIds.contains(transportEntity.id))
        XCTAssertFalse(fetchedIds.contains(salaryEntity.id))
    }
    
    // MARK: - Aggregate Tests
    
    func testCountQuery() throws {
        // Given
        let entities = (0..<10).map { _ in createTestTransactionEntity() }
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let count = try testContext.count(for: request)
        
        // Then
        XCTAssertEqual(count, entities.count)
    }
    
    func testCountWithPredicate() throws {
        // Given
        let incomeEntities = (0..<3).map { _ in createTestTransactionEntity(type: .income) }
        let expenseEntities = (0..<7).map { _ in createTestTransactionEntity(type: .expense) }
        try testContext.save()
        
        // When
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "type == %@", TransactionType.income.rawValue)
        let incomeCount = try testContext.count(for: request)
        
        // Then
        XCTAssertEqual(incomeCount, incomeEntities.count)
    }
    
    // MARK: - Performance Tests
    
    func testLargeDataSetPerformance() throws {
        // Given
        let entityCount = 1000
        
        // When & Then - Measure creation and saving time
        measure {
            let entities = (0..<entityCount).map { index in
                createTestTransactionEntity(amount: Double(index))
            }
            
            do {
                try testContext.save()
            } catch {
                XCTFail("Failed to save entities: \(error)")
            }
        }
        
        // Verify all entities were saved
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        let savedEntities = try testContext.fetch(request)
        XCTAssertEqual(savedEntities.count, entityCount)
    }
    
    func testFetchPerformance() throws {
        // Given
        let entityCount = 1000
        let entities = (0..<entityCount).map { index in
            createTestTransactionEntity(amount: Double(index))
        }
        try testContext.save()
        
        // When & Then - Measure fetch time
        measure {
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            do {
                let fetchedEntities = try testContext.fetch(request)
                XCTAssertEqual(fetchedEntities.count, entityCount)
            } catch {
                XCTFail("Failed to fetch entities: \(error)")
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testFetchWithInvalidEntityName() {
        // Given
        let request = NSFetchRequest<NSManagedObject>(entityName: "InvalidEntity")
        
        // When & Then
        XCTAssertThrowsError(try testContext.fetch(request)) { error in
            XCTAssertTrue(error is NSError)
        }
    }
    
    // MARK: - Concurrency Tests
    
    func testConcurrentAccess() {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent operations should complete")
        expectation.expectedFulfillmentCount = 2
        
        // When
        DispatchQueue.global(qos: .background).async {
            let backgroundContext = self.sut.persistentContainer.newBackgroundContext()
            backgroundContext.performAndWait {
                let entity = TransactionEntity(context: backgroundContext)
                entity.id = UUID()
                entity.amountBTC = 1.0
                entity.category = "Background"
                entity.type = TransactionType.income.rawValue
                entity.timestamp = Date()
                
                do {
                    try backgroundContext.save()
                    expectation.fulfill()
                } catch {
                    XCTFail("Background save failed: \(error)")
                }
            }
        }
        
        DispatchQueue.main.async {
            let entity = self.createTestTransactionEntity(category: "Main")
            do {
                try self.testContext.save()
                expectation.fulfill()
            } catch {
                XCTFail("Main context save failed: \(error)")
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Helper Methods
    
    @discardableResult
    private func createTestTransactionEntity(
        amount: Double = 1.0,
        type: TransactionType = .expense,
        category: String = "Test",
        timestamp: Date = Date()
    ) -> TransactionEntity {
        let entity = TransactionEntity(context: testContext)
        entity.id = UUID()
        entity.amountBTC = amount
        entity.category = category
        entity.type = type.rawValue
        entity.timestamp = timestamp
        return entity
    }
} 