//
//  ServicesAssembler.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation

class ServicesAssembler {
    
    static func bitcoinRateService() -> BitcoinRateService {
        return BitcoinRateService.shared
    }
} 