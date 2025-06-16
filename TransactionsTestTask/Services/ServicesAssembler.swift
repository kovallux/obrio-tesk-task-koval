//
//  ServicesAssembler.swift
//  TransactionsTestTask
//
//

import Foundation
import Combine

/// Services Assembler is used for Dependency Injection
/// There is an example of a _bad_ services relationship built on `onRateUpdate` callback
/// This kind of relationship must be refactored with a more convenient and reliable approach
///
/// It's ok to move the logging to model/viewModel/interactor/etc when you have 1-2 modules in your app
/// Imagine having rate updates in 20-50 diffent modules
/// Make this logic not depending on any module
enum ServicesAssembler {
    
    // MARK: - BitcoinRateService
    
    static let bitcoinRateService: PerformOnce<BitcoinRateService> = {
        let apiKey = "ed001fae24a74737266cda1710af78e0625cd55f1f3780887c05c528278d9fa6"
        let service = BitcoinRateServiceImpl(apiKey: apiKey)
        
        // Start periodic fetching
        service.startPeriodicFetch()
        
        return { service }
    }()
    
    // MARK: - AnalyticsService
    
    static let analyticsService: PerformOnce<AnalyticsService> = {
        let service = AnalyticsServiceImpl()
        
        return { service }
    }()
}
