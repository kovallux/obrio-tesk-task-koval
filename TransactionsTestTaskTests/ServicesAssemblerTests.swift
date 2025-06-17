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
} 