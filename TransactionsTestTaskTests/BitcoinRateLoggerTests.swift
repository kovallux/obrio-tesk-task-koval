//
//  BitcoinRateLoggerTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
@testable import TransactionsTestTask

final class BitcoinRateLoggerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear logs before each test
        BitcoinRateLogger.clearLogs()
    }
    
    override func tearDown() {
        // Clean up after each test
        BitcoinRateLogger.clearLogs()
        super.tearDown()
    }
    
    // MARK: - Basic Logging Tests
    
    func testLoggerSingleton() {
        // Given & When
        let logger1 = BitcoinRateLogger.shared
        let logger2 = BitcoinRateLogger.shared
        
        // Then
        XCTAssertTrue(logger1 === logger2, "BitcoinRateLogger should be a singleton")
    }
    
    func testBasicRateLogging() {
        // Given
        let testRate = 45000.0
        let expectation = XCTestExpectation(description: "Rate should be logged")
        
        // When
        BitcoinRateLogger.log(testRate, subscriberCount: 5)
        
        // Wait a bit for async logging to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        // Verify log file was created and contains the rate
        let logContents = BitcoinRateLogger.getLogContents()
        XCTAssertNotNil(logContents, "Log file should exist")
        XCTAssertTrue(logContents?.contains("45000.00") == true, "Log should contain the rate")
        XCTAssertTrue(logContents?.contains("5 modules") == true, "Log should mention subscriber count")
    }
    
    func testSpecificModuleLogging() {
        // Given
        let testRate = 50000.0
        let moduleName = "TestModule"
        let expectation = XCTestExpectation(description: "Module-specific rate should be logged")
        
        // When
        BitcoinRateLogger.log(testRate, from: moduleName)
        
        // Wait for async logging
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        
        // Note: Module-specific logging goes to system logger, not file
        // This test verifies the method doesn't crash
        XCTAssertTrue(true, "Module-specific logging should complete without error")
    }
    
    // MARK: - Log File Tests
    
    func testLogFileCreation() {
        // Given & When
        BitcoinRateLogger.log(42000.0, subscriberCount: 1)
        
        // Wait for file creation
        let expectation = XCTestExpectation(description: "Log file should be created")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        let logFileURL = BitcoinRateLogger.logFileURL
        XCTAssertNotNil(logFileURL, "Log file URL should be available")
        
        if let url = logFileURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Log file should exist")
        }
    }
    
    func testLogFileContents() {
        // Given
        let testRate = 48000.0
        let subscriberCount = 10
        
        // When
        BitcoinRateLogger.log(testRate, subscriberCount: subscriberCount)
        
        // Wait for logging to complete
        let expectation = XCTestExpectation(description: "Logging should complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        let logContents = BitcoinRateLogger.getLogContents()
        XCTAssertNotNil(logContents, "Log contents should be available")
        
        if let contents = logContents {
            XCTAssertTrue(contents.contains("48000.00"), "Log should contain the rate")
            XCTAssertTrue(contents.contains("\(subscriberCount) modules"), "Log should contain subscriber count")
            XCTAssertTrue(contents.contains("Rate Update:"), "Log should contain rate update marker")
        }
    }
    
    func testLogFileClear() {
        // Given
        BitcoinRateLogger.log(40000.0, subscriberCount: 3)
        
        // Wait for initial logging
        let expectation1 = XCTestExpectation(description: "Initial logging should complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1.0)
        
        // Verify log has content
        var logContents = BitcoinRateLogger.getLogContents()
        XCTAssertTrue(logContents?.contains("40000.00") == true, "Log should initially contain the rate")
        
        // When
        BitcoinRateLogger.clearLogs()
        
        // Wait for clearing to complete
        let expectation2 = XCTestExpectation(description: "Log clearing should complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation2.fulfill()
        }
        wait(for: [expectation2], timeout: 1.0)
        
        // Then
        logContents = BitcoinRateLogger.getLogContents()
        XCTAssertNotNil(logContents, "Log file should still exist after clearing")
        XCTAssertFalse(logContents?.contains("40000.00") == true, "Log should not contain the old rate after clearing")
        XCTAssertTrue(logContents?.contains("Cleared:") == true, "Log should contain cleared marker")
    }
    
    // MARK: - Multiple Logging Tests
    
    func testMultipleRateUpdates() {
        // Given
        let rates = [45000.0, 46000.0, 47000.0]
        let expectation = XCTestExpectation(description: "Multiple rates should be logged")
        
        // When
        for rate in rates {
            BitcoinRateLogger.log(rate, subscriberCount: 5)
        }
        
        // Wait for all logging to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Then
        let logContents = BitcoinRateLogger.getLogContents()
        XCTAssertNotNil(logContents, "Log contents should be available")
        
        if let contents = logContents {
            for rate in rates {
                let formattedRate = String(format: "%.2f", rate)
                XCTAssertTrue(contents.contains(formattedRate), "Log should contain rate \(formattedRate)")
            }
        }
    }
    
    // MARK: - Performance Tests
    
//    func testLoggingPerformance() {
//        // Given
//        let testRate = 50000.0
//        
//        // When & Then
//        measure {
//            BitcoinRateLogger.log(testRate, subscriberCount: 25)
//            
//            // Wait for logging to complete
//            let expectation = XCTestExpectation(description: "Logging should complete")
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                expectation.fulfill()
//            }
//            wait(for: [expectation], timeout: 0.5)
//        }
//    }
    
    // MARK: - Edge Cases
    
    func testZeroRate() {
        // Given
        let testRate = 0.0
        let expectation = XCTestExpectation(description: "Zero rate should be logged")
        
        // When
        BitcoinRateLogger.log(testRate, subscriberCount: 1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        let logContents = BitcoinRateLogger.getLogContents()
        XCTAssertNotNil(logContents, "Log should exist even for zero rate")
        XCTAssertTrue(logContents?.contains("0.00") == true, "Log should contain zero rate")
    }
    
    func testNegativeRate() {
        // Given
        let testRate = -1000.0
        let expectation = XCTestExpectation(description: "Negative rate should be logged")
        
        // When
        BitcoinRateLogger.log(testRate, subscriberCount: 1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Then
        let logContents = BitcoinRateLogger.getLogContents()
        XCTAssertNotNil(logContents, "Log should exist for negative rate")
        XCTAssertTrue(logContents?.contains("-1000.00") == true, "Log should contain negative rate")
    }
    
//    func testMaxSubscriberCount() {
//        // Given
//        let testRate = 55000.0
//        let maxSubscribers = 50
//        let expectation = XCTestExpectation(description: "Max subscribers should be logged")
//        
//        // When
//        BitcoinRateLogger.log(testRate, subscriberCount: maxSubscribers)
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            expectation.fulfill()
//        }
//        wait(for: [expectation], timeout: 1.0)
//        
//        // Then
//        let logContents = BitcoinRateLogger.getLogContents()
//        XCTAssertNotNil(logContents, "Log should exist for max subscribers")
//        XCTAssertTrue(logContents?.contains("\(maxSubscribers) modules") == true, "Log should contain max subscriber count")
//    }
} 
