//
//  BitcoinRateServiceTests.swift
//  TransactionsTestTaskTests
//
//  Created by Sergii Koval on 16.06.2025.
//

import XCTest
import Combine
@testable import TransactionsTestTask

final class BitcoinRateServiceTests: XCTestCase {
    
    private var cancellables: Set<AnyCancellable>!
    private var service: BitcoinRateServiceImpl!
    
    override func setUpWithError() throws {
        cancellables = Set<AnyCancellable>()
        // Use the same API key from ServicesAssembler
        service = BitcoinRateServiceImpl(apiKey: "ed001fae24a74737266cda1710af78e0625cd55f1f3780887c05c528278d9fa6")
    }
    
    override func tearDownWithError() throws {
        service.stopPeriodicFetch()
        cancellables = nil
        service = nil
    }
    
    // MARK: - API Fetch Tests
    
    func testFetchRateSuccess() throws {
        let expectation = XCTestExpectation(description: "Fetch rate successfully")
        
        service.fetchRate()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Test: Fetch completed successfully")
                    case .failure(let error):
                        XCTFail("Expected success, got error: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { rate in
                    print("✅ Test: Received rate: $\(String(format: "%.2f", rate))")
                    XCTAssertGreaterThan(rate, 0, "Rate should be greater than 0")
                    XCTAssertLessThan(rate, 1000000, "Rate should be reasonable (less than $1M)")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testRatePublisher() throws {
        let expectation = XCTestExpectation(description: "Rate publisher emits values")
        
        service.ratePublisher
            .sink { rate in
                print("✅ Test: Publisher emitted rate: $\(String(format: "%.2f", rate))")
                XCTAssertGreaterThan(rate, 0, "Published rate should be greater than 0")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Trigger a fetch to make the publisher emit
        service.fetchRate()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Caching Tests
    
    func testCachingFunctionality() throws {
        let expectation = XCTestExpectation(description: "Rate is cached after fetch")
        
        // First fetch should cache the rate
        service.fetchRate()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("✅ Test: First fetch completed, rate should be cached")
                        
                        // Create new service instance to test cache loading
                        let newService = BitcoinRateServiceImpl(apiKey: "ed001fae24a74737266cda1710af78e0625cd55f1f3780887c05c528278d9fa6")
                        
                        // Check if cached rate is loaded on initialization
                        newService.ratePublisher
                            .sink { cachedRate in
                                print("✅ Test: Cached rate loaded: $\(String(format: "%.2f", cachedRate))")
                                XCTAssertGreaterThan(cachedRate, 0, "Cached rate should be greater than 0")
                                expectation.fulfill()
                            }
                            .store(in: &self.cancellables)
                        
                    case .failure(let error):
                        XCTFail("Expected success, got error: \(error)")
                        expectation.fulfill()
                    }
                },
                receiveValue: { rate in
                    print("✅ Test: Rate fetched for caching: $\(String(format: "%.2f", rate))")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 15.0)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidAPIKey() throws {
        let expectation = XCTestExpectation(description: "Invalid API key should fail")
        
        let invalidService = BitcoinRateServiceImpl(apiKey: "invalid_key")
        
        invalidService.fetchRate()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure with invalid API key")
                    case .failure(let error):
                        print("✅ Test: Invalid API key failed as expected: \(error)")
                    }
                    expectation.fulfill()
                },
                receiveValue: { rate in
                    XCTFail("Should not receive value with invalid API key")
                }
            )
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    // MARK: - Performance Tests
    
    func testFetchPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Performance test")
            
            service.fetchRate()
                .sink(
                    receiveCompletion: { _ in expectation.fulfill() },
                    receiveValue: { _ in }
                )
                .store(in: &cancellables)
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
} 