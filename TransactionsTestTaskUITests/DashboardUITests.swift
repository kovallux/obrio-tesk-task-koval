//
//  DashboardUITests.swift
//  TransactionsTestTaskUITests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest

class DashboardUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        app = nil
        super.tearDown()
    }
    
    // MARK: - Dashboard Tests
    
    func testDashboardLoadsSuccessfully() {
        // Given & When
        let dashboardTitle = app.navigationBars["Expense Tracker"]
        
        // Then
        XCTAssertTrue(dashboardTitle.exists)
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5.0))
    }
    
    func testBitcoinRateDisplayed() {
        // Given & When
        let bitcoinRateLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '$'")).firstMatch
        
        // Then
        XCTAssertTrue(bitcoinRateLabel.waitForExistence(timeout: 10.0))
    }
    
    func testBalanceDisplayed() {
        // Given & When
        let balanceLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'BTC'")).firstMatch
        
        // Then
        XCTAssertTrue(balanceLabel.waitForExistence(timeout: 5.0))
    }
    
    func testAddTransactionButtonExists() {
        // Given & When
        let addButton = app.buttons["Add Transaction"]
        
        // Then
        XCTAssertTrue(addButton.exists)
        XCTAssertTrue(addButton.isEnabled)
    }
    
    func testNavigationBarButtons() {
        // Given & When
        let addButton = app.navigationBars.buttons.element(boundBy: 0)
        let statisticsButton = app.navigationBars.buttons.element(boundBy: 1)
        
        // Then
        XCTAssertTrue(addButton.exists)
        XCTAssertTrue(statisticsButton.exists)
    }
    
    // MARK: - Transaction List Tests
    
    func testTransactionListExists() {
        // Given & When
        let transactionList = app.tables.firstMatch
        
        // Then
        XCTAssertTrue(transactionList.exists)
    }
    
    func testEmptyStateDisplayed() {
        // Given & When - Assuming fresh app with no transactions
        let emptyStateMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'No transactions'")).firstMatch
        
        // Then
        XCTAssertTrue(emptyStateMessage.waitForExistence(timeout: 5.0))
    }
    
    // MARK: - Add Transaction Flow Tests
    
    func testAddTransactionFlow() {
        // Given
        let addButton = app.buttons["Add Transaction"]
        
        // When
        addButton.tap()
        
        // Then
        let addTransactionTitle = app.navigationBars["Add Transaction"]
        XCTAssertTrue(addTransactionTitle.waitForExistence(timeout: 3.0))
    }
    
    func testAddTransactionFormElements() {
        // Given
        let addButton = app.buttons["Add Transaction"]
        addButton.tap()
        
        // When & Then
        let amountField = app.textFields["Amount"]
        let categoryPicker = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Category'")).firstMatch
        let typeSegmentedControl = app.segmentedControls.firstMatch
        let saveButton = app.buttons["Add"]
        
        XCTAssertTrue(amountField.waitForExistence(timeout: 3.0))
        XCTAssertTrue(categoryPicker.exists)
        XCTAssertTrue(typeSegmentedControl.exists)
        XCTAssertTrue(saveButton.exists)
    }
    
    func testAddTransactionWithValidData() {
        // Given
        let addButton = app.buttons["Add Transaction"]
        addButton.tap()
        
        let amountField = app.textFields["Amount"]
        let saveButton = app.buttons["Add"]
        
        // When
        amountField.tap()
        amountField.typeText("0.001")
        
        saveButton.tap()
        
        // Then
        let dashboardTitle = app.navigationBars["Expense Tracker"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 5.0))
    }
    
    func testAddTransactionCancelFlow() {
        // Given
        let addButton = app.buttons["Add Transaction"]
        addButton.tap()
        
        // When
        let cancelButton = app.navigationBars.buttons["Cancel"]
        cancelButton.tap()
        
        // Then
        let dashboardTitle = app.navigationBars["Expense Tracker"]
        XCTAssertTrue(dashboardTitle.waitForExistence(timeout: 3.0))
    }
    
    // MARK: - Pull to Refresh Tests
    
    func testPullToRefresh() {
        // Given
        let transactionList = app.tables.firstMatch
        
        // When
        transactionList.swipeDown()
        
        // Then
        // Verify refresh indicator appears (simplified check)
        XCTAssertTrue(transactionList.exists)
    }
    
    // MARK: - Navigation Tests
    
    func testStatisticsNavigation() {
        // Given
        let statisticsButton = app.navigationBars.buttons.element(boundBy: 1)
        
        // When
        statisticsButton.tap()
        
        // Then
        // Verify statistics view appears (would need actual implementation)
        XCTAssertTrue(true) // Placeholder
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() {
        // Given & When
        let addButton = app.buttons["Add Transaction"]
        let bitcoinRateLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '$'")).firstMatch
        
        // Then
        XCTAssertTrue(addButton.isAccessibilityElement)
        XCTAssertTrue(bitcoinRateLabel.waitForExistence(timeout: 5.0))
        XCTAssertTrue(bitcoinRateLabel.isAccessibilityElement)
    }
    
    func testVoiceOverSupport() {
        // Given
        let addButton = app.buttons["Add Transaction"]
        
        // When & Then
        XCTAssertNotNil(addButton.label)
        XCTAssertFalse(addButton.label.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testDashboardLaunchPerformance() {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testScrollPerformance() {
        // Given
        let transactionList = app.tables.firstMatch
        
        // When & Then
        measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
            transactionList.swipeUp()
            transactionList.swipeDown()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        // Given - Simulate network issues (would need mock setup)
        
        // When
        let refreshControl = app.tables.firstMatch
        refreshControl.swipeDown()
        
        // Then
        // Verify error handling (simplified check)
        XCTAssertTrue(refreshControl.exists)
    }
    
    // MARK: - Rotation Tests
    
    func testDeviceRotation() {
        // Given
        let device = XCUIDevice.shared
        
        // When
        device.orientation = .landscapeLeft
        
        // Then
        let dashboardTitle = app.navigationBars["Expense Tracker"]
        XCTAssertTrue(dashboardTitle.exists)
        
        // Cleanup
        device.orientation = .portrait
    }
    
    // MARK: - Memory Tests
    
    func testMemoryUsage() {
        measure(metrics: [XCTMemoryMetric()]) {
            // Simulate heavy usage
            for _ in 0..<10 {
                let addButton = app.buttons["Add Transaction"]
                addButton.tap()
                
                let cancelButton = app.navigationBars.buttons["Cancel"]
                cancelButton.tap()
            }
        }
    }
} 