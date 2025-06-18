//
//  ServicesAssembler.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

class ServicesAssembler {
    
    // MARK: - Singleton
    static let shared = ServicesAssembler()
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var isLoggingSetup = false
    
    // MARK: - Initialization
    private init() {
        setupBitcoinRateLogging()
    }
    
    // MARK: - Services
    
    static func bitcoinRateService() -> BitcoinRateService {
        return BitcoinRateService.shared
    }
    
    // MARK: - Private Methods
    
    private func setupBitcoinRateLogging() {
        guard !isLoggingSetup else { return }
        
        let bitcoinRateService = BitcoinRateService.shared
        
        // Create fan-out logging subscriptions to simulate 20-50 modules
        // Each subscription represents a different module that would need Bitcoin rate updates
        createFanOutSubscriptions(for: bitcoinRateService)
        
        isLoggingSetup = true
        print("ServicesAssembler: Bitcoin rate fan-out logging setup completed")
    }
    
    private func createFanOutSubscriptions(for service: BitcoinRateService) {
        // Generate random number of subscribers between 20-50
        let subscriberCount = Int.random(in: 20...50)
        
        print("ServicesAssembler: Creating \(subscriberCount) fan-out logging subscriptions")
        
        // Create multiple subscriptions to simulate different modules
        for i in 1...subscriberCount {
            service.$currentRate
                .filter { $0 > 0 } // Only log when we have a valid rate
                .sink { [weak self] rate in
                    // Log the rate update through BitcoinRateLogger
                    // This simulates each module receiving and logging the update
                    BitcoinRateLogger.log(rate, subscriberCount: 1)
                }
                .store(in: &cancellables)
        }
        
        // Also create a master subscription that logs the full fan-out
        service.$currentRate
            .filter { $0 > 0 }
            .sink { rate in
                // This logs the main rate update with full subscriber simulation
                BitcoinRateLogger.log(rate, subscriberCount: subscriberCount)
            }
            .store(in: &cancellables)
        
        print("ServicesAssembler: ✅ Fan-out logging subscriptions created successfully")
    }
} 