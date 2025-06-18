//
//  ServicesAssemblerTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
@testable import TransactionsTestTask

final class ServicesAssemblerTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    // MARK: - BitcoinRateService Tests
    
    func testBitcoinRateServiceReturnsSharedInstance() {
        // When
        let service = ServicesAssembler.bitcoinRateService()
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service === BitcoinRateService.shared)
    }
    
    func testBitcoinRateServiceConsistency() {
        // When
        let service1 = ServicesAssembler.bitcoinRateService()
        let service2 = ServicesAssembler.bitcoinRateService()
        
        // Then
        XCTAssertTrue(service1 === service2)
    }
    
    func testBitcoinRateServiceType() {
        // When
        let service = ServicesAssembler.bitcoinRateService()
        
        // Then
        XCTAssertTrue(service is BitcoinRateService)
    }
    
    func testBitcoinRateServiceInitialState() {
        // When
        let service = ServicesAssembler.bitcoinRateService()
        
        // Then
        XCTAssertEqual(service.currentRate, 0.0) // Initial rate should be 0
        XCTAssertFalse(service.isLoading) // Should not be loading initially
        XCTAssertNil(service.lastError) // Should have no error initially
    }
    
    func testServicesAssemblerStaticMethods() {
        // Given
        let assemblerType = type(of: ServicesAssembler.self)
        
        // When
        let hasStaticBitcoinRateServiceMethod = assemblerType.responds(to: #selector(ServicesAssembler.bitcoinRateService))
        
        // Then
        XCTAssertTrue(hasStaticBitcoinRateServiceMethod)
    }
    
    // MARK: - Fan-out Logging Tests
    
    func testServicesAssemblerSingleton() {
        // When
        let assembler1 = ServicesAssembler.shared
        let assembler2 = ServicesAssembler.shared
        
        // Then
        XCTAssertTrue(assembler1 === assembler2, "ServicesAssembler should be a singleton")
    }
    
    func testFanOutLoggingSetup() {
        // Given
        BitcoinRateLogger.clearLogs()
        
        // When
        let assembler = ServicesAssembler.shared
        let bitcoinRateService = ServicesAssembler.bitcoinRateService()
        
        // Simulate a rate update
        bitcoinRateService.currentRate = 50000.0
        
        // Wait for logging to complete
        let expectation = XCTestExpectation(description: "Fan-out logging should complete")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
        
        // Then
        let logContents = BitcoinRateLogger.getLogContents()
        XCTAssertNotNil(logContents, "Log file should exist after rate update")
        
        if let contents = logContents {
            XCTAssertTrue(contents.contains("50000.00"), "Log should contain the rate update")
            XCTAssertTrue(contents.contains("modules"), "Log should mention modules")
        }
    }
} 