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
}

class UpdateBitcoinRateUseCase: UpdateBitcoinRateUseCaseProtocol {
    private let bitcoinRateService = BitcoinRateService.shared
    
    func execute() -> AnyPublisher<Double, Error> {
        return Future { [weak self] promise in
            guard let self = self else {
                promise(.failure(UpdateBitcoinRateError.serviceUnavailable))
                return
            }
            
            // Trigger a manual fetch
            self.bitcoinRateService.fetchBitcoinRate()
            
            // Return the current rate (which will be updated by the service)
            let currentRate = self.bitcoinRateService.currentRate
            
            if currentRate > 0 {
                promise(.success(currentRate))
            } else {
                promise(.failure(UpdateBitcoinRateError.invalidRate))
            }
        }
        .eraseToAnyPublisher()
    }
}

enum UpdateBitcoinRateError: Error, LocalizedError {
    case serviceUnavailable
    case invalidRate
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable:
            return "Bitcoin rate service is unavailable"
        case .invalidRate:
            return "Invalid Bitcoin rate received"
        case .networkError:
            return "Network error while fetching Bitcoin rate"
        }
    }
} 