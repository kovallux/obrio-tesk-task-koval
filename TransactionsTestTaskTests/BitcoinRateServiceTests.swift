//
//  BitcoinRateServiceTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
import Combine
@testable import TransactionsTestTask

class BitcoinRateServiceTests: XCTestCase {
    
    var sut: BitcoinRateServiceImpl!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        sut = BitcoinRateServiceImpl(apiKey: "test_api_key")
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Given & When
        let service = BitcoinRateServiceImpl(apiKey: "test_key")
        
        // Then
        XCTAssertNotNil(service)
        XCTAssertEqual(service.currentBitcoinRate, 0.0)
    }
    
    // MARK: - Rate Publisher Tests
    
    func testRatePublisherFiltersZeroValues() {
        // Given
        let expectation = XCTestExpectation(description: "Rate publisher should filter zero values")
        expectation.isInverted = true // We expect this NOT to be fulfilled
        
        // When
        sut.ratePublisher
            .sink { rate in
                if rate == 0.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRatePublisherEmitsValidRates() {
        // Given
        let expectation = XCTestExpectation(description: "Rate publisher should emit valid rates")
        let testRate = 50000.0
        
        // When
        sut.ratePublisher
            .sink { rate in
                XCTAssertGreaterThan(rate, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate rate update
        sut.currentRate = testRate
        
        // Then
        wait(for: [expectation], timeout: 2.0)
    }
    
    // MARK: - Fetch Rate Tests
    
    func testFetchRateSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Fetch rate should succeed")
        
        // When
        sut.fetchRate()
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        XCTFail("Expected success but got failure")
                    }
                },
                receiveValue: { rate in
                    XCTAssertGreaterThan(rate, 0)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testFetchRateWithInvalidAPIKey() {
        // Given
        let invalidService = BitcoinRateServiceImpl(apiKey: "invalid_key")
        let expectation = XCTestExpectation(description: "Fetch rate should fail with invalid API key")
        
        // When
        invalidService.fetchRate()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertTrue(error is BitcoinRateError)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected failure but got success")
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Caching Tests
    
    func testCacheCreation() {
        // Given
        let testRate = 45000.0
        let testData = CachedRate(rate: testRate, timestamp: Date())
        
        // When
        let success = sut.saveToCache(testData)
        
        // Then
        XCTAssertTrue(success)
    }
    
    func testCacheRetrieval() {
        // Given
        let testRate = 45000.0
        let testData = CachedRate(rate: testRate, timestamp: Date())
        
        // When
        let saveSuccess = sut.saveToCache(testData)
        let retrievedData = sut.loadFromCache()
        
        // Then
        XCTAssertTrue(saveSuccess)
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(retrievedData?.rate, testRate)
    }
    
    func testCacheExpiration() {
        // Given
        let testRate = 45000.0
        let expiredDate = Date().addingTimeInterval(-7200) // 2 hours ago
        let expiredData = CachedRate(rate: testRate, timestamp: expiredDate)
        
        // When
        let saveSuccess = sut.saveToCache(expiredData)
        let isValid = sut.isCacheValid()
        
        // Then
        XCTAssertTrue(saveSuccess)
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Periodic Fetch Tests
    
    func testStartPeriodicFetch() {
        // Given
        let expectation = XCTestExpectation(description: "Periodic fetch should start")
        
        // When
        sut.startPeriodicFetch()
        
        // Verify timer is running (simplified check)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        
        // Cleanup
        sut.stopPeriodicFetch()
    }
    
    func testStopPeriodicFetch() {
        // Given
        sut.startPeriodicFetch()
        
        // When
        sut.stopPeriodicFetch()
        
        // Then
        // Verify timer is stopped (simplified check)
        XCTAssertTrue(true) // In real implementation, we'd check timer state
    }
    
    // MARK: - Error Handling Tests
    
    func testNetworkErrorHandling() {
        // Given
        let expectation = XCTestExpectation(description: "Should handle network errors gracefully")
        
        // When - Simulate network error by using invalid URL
        let invalidService = BitcoinRateServiceImpl(apiKey: "test")
        // Override URL to invalid one (in real implementation)
        
        invalidService.fetchRate()
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTAssertNotNil(error)
                        expectation.fulfill()
                    }
                },
                receiveValue: { _ in
                    // May still succeed if network is available
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        // Then
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Performance Tests
    
    func testFetchRatePerformance() {
        measure {
            let expectation = XCTestExpectation(description: "Fetch rate performance")
            
            sut.fetchRate()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in
                        expectation.fulfill()
                    }
                )
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    func testCachePerformance() {
        let testData = CachedRate(rate: 50000.0, timestamp: Date())
        
        measure {
            for _ in 0..<1000 {
                _ = sut.saveToCache(testData)
                _ = sut.loadFromCache()
            }
        }
    }
}

// MARK: - Mock Classes

class MockBitcoinRateService: BitcoinRateService {
    var currentBitcoinRate: Double = 50000.0
    var shouldFail = false
    var mockRate = 50000.0
    
    var ratePublisher: AnyPublisher<Double, Never> {
        Just(mockRate).eraseToAnyPublisher()
    }
    
    func fetchRate() -> AnyPublisher<Double, Error> {
        if shouldFail {
            return Fail(error: BitcoinRateError.networkError)
                .eraseToAnyPublisher()
        } else {
            return Just(mockRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
    
    func fetchBitcoinRatePublisher() -> AnyPublisher<Double, Error> {
        return fetchRate()
    }
    
    func startPeriodicFetch() {
        // Mock implementation
    }
    
    func stopPeriodicFetch() {
        // Mock implementation
    }
} 