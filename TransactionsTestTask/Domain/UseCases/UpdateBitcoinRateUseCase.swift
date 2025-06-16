//
//  UpdateBitcoinRateUseCase.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

protocol UpdateBitcoinRateUseCaseProtocol {
    func execute() -> AnyPublisher<Double, Error>
    func getCurrentRate() -> AnyPublisher<Double, Error>
    func startPeriodicUpdates() -> AnyPublisher<Double, Error>
    func stopPeriodicUpdates()
}

final class UpdateBitcoinRateUseCase: UpdateBitcoinRateUseCaseProtocol {
    
    private let bitcoinRateService: BitcoinRateService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    
    init(bitcoinRateService: BitcoinRateService = BitcoinRateServiceImpl(apiKey: "ed001fae24a74737266cda1710af78e0625cd55f1f3780887c05c528278d9fa6")) {
        self.bitcoinRateService = bitcoinRateService
        print("UpdateBitcoinRateUseCase: Initialized")
    }
    
    deinit {
        stopPeriodicUpdates()
        print("UpdateBitcoinRateUseCase: Deinitialized")
    }
    
    // MARK: - Execute Methods
    
    func execute() -> AnyPublisher<Double, Error> {
        print("UpdateBitcoinRateUseCase: Executing manual rate update")
        
        return bitcoinRateService.fetchBitcoinRatePublisher()
            .handleEvents(
                receiveOutput: { rate in
                    print("UpdateBitcoinRateUseCase: Successfully updated rate to $\(String(format: "%.2f", rate))")
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("UpdateBitcoinRateUseCase: Failed to update rate - Error: \(error)")
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    func getCurrentRate() -> AnyPublisher<Double, Error> {
        print("UpdateBitcoinRateUseCase: Getting current rate")
        
        let currentRate = bitcoinRateService.currentBitcoinRate
        
        if currentRate > 0 {
            print("UpdateBitcoinRateUseCase: Current rate available - $\(String(format: "%.2f", currentRate))")
            return Just(currentRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            print("UpdateBitcoinRateUseCase: No current rate available, fetching new rate")
            return execute()
        }
    }
    
    func startPeriodicUpdates() -> AnyPublisher<Double, Error> {
        print("UpdateBitcoinRateUseCase: Starting periodic updates")
        
        // Stop any existing updates first
        stopPeriodicUpdates()
        
        return bitcoinRateService.ratePublisher
            .setFailureType(to: Error.self)
            .handleEvents(
                receiveOutput: { rate in
                    print("UpdateBitcoinRateUseCase: Periodic update received - $\(String(format: "%.2f", rate))")
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("UpdateBitcoinRateUseCase: Periodic updates failed - Error: \(error)")
                    }
                },
                receiveCancel: {
                    print("UpdateBitcoinRateUseCase: Periodic updates cancelled")
                }
            )
            .eraseToAnyPublisher()
    }
    
    func stopPeriodicUpdates() {
        print("UpdateBitcoinRateUseCase: Stopping periodic updates")
        cancellables.removeAll()
    }
}

// MARK: - Rate Monitoring

extension UpdateBitcoinRateUseCase {
    
    func monitorRateChanges(threshold: Double = 1000.0) -> AnyPublisher<RateChangeEvent, Error> {
        print("UpdateBitcoinRateUseCase: Starting rate change monitoring with threshold $\(threshold)")
        
        return startPeriodicUpdates()
            .scan((previous: 0.0, current: 0.0)) { (accumulator, newRate) in
                return (previous: accumulator.current, current: newRate)
            }
            .compactMap { rates in
                guard rates.previous > 0 else { return nil }
                
                let change = rates.current - rates.previous
                let changePercent = (change / rates.previous) * 100
                
                if abs(change) >= threshold {
                    let event = RateChangeEvent(
                        previousRate: rates.previous,
                        currentRate: rates.current,
                        change: change,
                        changePercent: changePercent,
                        timestamp: Date(),
                        isSignificant: true
                    )
                    
                    print("UpdateBitcoinRateUseCase: Significant rate change detected - \(event.formattedChange)")
                    return event
                }
                
                return RateChangeEvent(
                    previousRate: rates.previous,
                    currentRate: rates.current,
                    change: change,
                    changePercent: changePercent,
                    timestamp: Date(),
                    isSignificant: false
                )
            }
            .eraseToAnyPublisher()
    }
    
    func getRateHistory(limit: Int = 100) -> AnyPublisher<[RateHistoryEntry], Error> {
        print("UpdateBitcoinRateUseCase: Getting rate history (limit: \(limit))")
        
        // This would typically come from a persistent storage
        // For now, we'll return the current rate as a single entry
        return getCurrentRate()
            .map { rate in
                let entry = RateHistoryEntry(
                    rate: rate,
                    timestamp: Date()
                )
                print("UpdateBitcoinRateUseCase: Rate history retrieved - 1 entry")
                return [entry]
            }
            .eraseToAnyPublisher()
    }
    
    func getAverageRate(for period: TimePeriod) -> AnyPublisher<Double, Error> {
        print("UpdateBitcoinRateUseCase: Calculating average rate for \(period)")
        
        // For now, return current rate as average
        // In a real implementation, this would calculate from historical data
        return getCurrentRate()
            .map { rate in
                print("UpdateBitcoinRateUseCase: Average rate calculated - $\(String(format: "%.2f", rate))")
                return rate
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Data Models

struct RateChangeEvent {
    let previousRate: Double
    let currentRate: Double
    let change: Double
    let changePercent: Double
    let timestamp: Date
    let isSignificant: Bool
    
    var formattedChange: String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", change)) (\(sign)\(String(format: "%.2f", changePercent))%)"
    }
    
    var formattedCurrentRate: String {
        return "$\(String(format: "%.2f", currentRate))"
    }
    
    var formattedPreviousRate: String {
        return "$\(String(format: "%.2f", previousRate))"
    }
}

struct RateHistoryEntry {
    let rate: Double
    let timestamp: Date
    
    var formattedRate: String {
        return "$\(String(format: "%.2f", rate))"
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

enum TimePeriod: String, CaseIterable {
    case hour = "1h"
    case day = "24h"
    case week = "7d"
    case month = "30d"
    
    var displayName: String {
        switch self {
        case .hour: return "Last Hour"
        case .day: return "Last 24 Hours"
        case .week: return "Last Week"
        case .month: return "Last Month"
        }
    }
    
    var timeInterval: TimeInterval {
        switch self {
        case .hour: return 3600
        case .day: return 86400
        case .week: return 604800
        case .month: return 2592000
        }
    }
}

// MARK: - Errors

enum UpdateBitcoinRateError: Error, LocalizedError {
    case useCaseDeinitialized
    case serviceError(Error)
    case noRateAvailable
    case invalidThreshold
    
    var errorDescription: String? {
        switch self {
        case .useCaseDeinitialized:
            return "Use case was deinitialized"
        case .serviceError(let error):
            return "Service error: \(error.localizedDescription)"
        case .noRateAvailable:
            return "No Bitcoin rate available"
        case .invalidThreshold:
            return "Invalid threshold value"
        }
    }
} 