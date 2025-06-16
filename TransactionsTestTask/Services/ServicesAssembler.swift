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
        
        // Setup fan-out logging subscriptions (simulating 20-50 modules)
        setupFanOutLogging(for: service)
        
        // Start periodic fetching
        service.startPeriodicFetch()
        
        return { service }
    }()
    
    // MARK: - Fan-out Logging Setup
    
    private static var cancellables = Set<AnyCancellable>()
    
    private static func setupFanOutLogging(for service: BitcoinRateServiceImpl) {
        print("🔄 ServicesAssembler: Setting up fan-out logging for multiple subscribers...")
        
        // Simulate different types of modules that would subscribe to rate updates
        let subscribers = [
            // UI Components
            "DashboardViewModel", "CurrencyRateView", "TransactionListView", "BalanceWidget",
            "PriceChartView", "NotificationBanner", "StatusBarWidget", "WatchAppExtension",
            
            // Business Logic
            "PortfolioCalculator", "RiskAnalyzer", "TradingEngine", "AlertManager",
            "ReportGenerator", "TaxCalculator", "BudgetTracker", "InvestmentAdvisor",
            
            // Analytics & Monitoring
            "AnalyticsTracker", "PerformanceMonitor", "CrashReporter", "UserBehaviorTracker",
            "MarketAnalyzer", "TrendDetector", "VolatilityCalculator", "PricePredictor",
            
            // External Integrations
            "CloudSyncService", "BackupService", "ExportService", "EmailNotifier",
            "PushNotificationService", "WebhookService", "APIGateway", "ThirdPartyIntegration",
            
            // Data Processing
            "DataValidator", "CacheManager", "DatabaseSync", "HistoryTracker",
            "StatisticsEngine", "MetricsCollector", "AuditLogger", "ComplianceChecker",
            
            // Additional Modules (to reach 50+)
            "SecurityMonitor", "FraudDetector", "RateValidator", "NetworkMonitor",
            "MemoryManager", "PerformanceOptimizer", "ErrorHandler", "DebugLogger",
            "TestingFramework", "QualityAssurance", "LoadBalancer", "CircuitBreaker"
        ]
        
        print("🔄 ServicesAssembler: Creating \(subscribers.count) subscriber connections...")
        
        // Create subscription for each simulated module
        for (index, subscriber) in subscribers.enumerated() {
            service.ratePublisher
                .sink { rate in
                    // Each subscriber logs the rate update
                    print("📊 \(subscriber): Rate update: $\(String(format: "%.2f", rate))")
                    
                    // Simulate different processing delays for realism
                    let delay = Double.random(in: 0.001...0.01) // 1-10ms delay
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + delay) {
                        // Simulate additional processing that some modules might do
                        if index % 5 == 0 { // Every 5th subscriber does extra logging
                            print("📊 \(subscriber)_Analytics: Additional processing: $\(String(format: "%.2f", rate))")
                        }
                    }
                }
                .store(in: &cancellables)
        }
        
        // Add special logging for analytics service integration
        service.ratePublisher
            .sink { rate in
                // Track the rate update in analytics service
                let analyticsService = Self.analyticsService()
                analyticsService.trackEvent(
                    name: "bitcoin_rate_update",
                    parameters: [
                        "rate": String(format: "%.2f", rate),
                        "timestamp": String(Int(Date().timeIntervalSince1970)),
                        "subscribers_count": String(subscribers.count)
                    ]
                )
                
                // Also log this to console for now
                print("📊 AnalyticsService: Rate logged: $\(String(format: "%.2f", rate))")
            }
            .store(in: &cancellables)
        
        print("🔄 ServicesAssembler: Fan-out logging setup complete with \(subscribers.count + 1) total subscribers")
    }
    
    // MARK: - AnalyticsService
    
    static let analyticsService: PerformOnce<AnalyticsService> = {
        let service = AnalyticsServiceImpl()
        
        return { service }
    }()
}
