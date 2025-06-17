//
//  ViewController.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 10.06.2025.
//

import UIKit
import Combine
import CoreData

class ViewController: UIViewController {
    
    private let bitcoinService = BitcoinRateService.shared
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        setupTestUI()
        runAllTests()
        createSampleData()
    }
    
    private func setupTestUI() {
        title = "Bitcoin Service Tests"
        
        let testButton = UIButton(type: .system)
        testButton.setTitle("Run Tests Again", for: .normal)
        testButton.addTarget(self, action: #selector(runTestsButtonTapped), for: .touchUpInside)
        testButton.translatesAutoresizingMaskIntoConstraints = false
        
        let sampleDataButton = UIButton(type: .system)
        sampleDataButton.setTitle("Create Sample Data", for: .normal)
        sampleDataButton.addTarget(self, action: #selector(createSampleDataButtonTapped), for: .touchUpInside)
        sampleDataButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(testButton)
        view.addSubview(sampleDataButton)
        
        NSLayoutConstraint.activate([
            testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            
            sampleDataButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            sampleDataButton.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 20)
        ])
    }
    
    @objc private func runTestsButtonTapped() {
        runAllTests()
    }
    
    @objc private func createSampleDataButtonTapped() {
        createSampleData()
    }
    
    private func runAllTests() {
        print("🧪 Starting comprehensive Bitcoin service tests...")
        
        // Test 1: Direct API connection
        testDirectAPIConnection()
        
        // Test 2: Service integration
        testServiceIntegration()
        
        // Test 3: Caching functionality
        testCachingFunctionality()
        
        // Test 4: Error handling
        testErrorHandling()
    }
    
    private func testDirectAPIConnection() {
        print("\n📡 Test 1: Direct API Connection")
        print("================================")
        
        bitcoinService.fetchBitcoinRate()
        
        // Subscribe to rate updates
        bitcoinService.$currentRate
            .sink { rate in
                if rate > 0 {
                    print("✅ API Connection successful!")
                    print("💰 Current Bitcoin rate: $\(String(format: "%.2f", rate))")
                } else {
                    print("⏳ Waiting for rate update...")
                }
            }
            .store(in: &cancellables)
    }
    
    private func testServiceIntegration() {
        print("\n🔧 Test 2: Service Integration")
        print("==============================")
        
        print("🚀 Service initialized: \(bitcoinService)")
        print("📊 Current rate from service: $\(bitcoinService.currentRate)")
        print("🔄 Loading state: \(bitcoinService.isLoading)")
        
        if let error = bitcoinService.lastError {
            print("❌ Last error: \(error)")
        } else {
            print("✅ No errors reported")
        }
    }
    
    private func testCachingFunctionality() {
        print("\n💾 Test 3: Caching Functionality")
        print("=================================")
        
        // Test cache by triggering multiple fetches
        for i in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                print("🔄 Fetch attempt \(i)")
                self.bitcoinService.fetchBitcoinRate()
            }
        }
    }
    
    private func testErrorHandling() {
        print("\n🛡️ Test 4: Error Handling")
        print("==========================")
        
        // Monitor error states
        bitcoinService.$lastError
            .sink { error in
                if let error = error {
                    print("⚠️ Error detected: \(error)")
                } else {
                    print("✅ No errors in error handling test")
                }
            }
            .store(in: &cancellables)
        
        print("✅ Error handling test setup complete")
    }
    
    private func createSampleData() {
        print("\n📊 Creating Sample Transaction Data")
        print("===================================")
        
        let context = CoreDataStack.shared.context
        
        // Sample transactions for the last 30 days
        let categories = ["Food", "Transport", "Entertainment", "Shopping", "Bills", "Salary", "Investment", "Gift"]
        let calendar = Calendar.current
        let now = Date()
        
        // Clear existing data first
        clearExistingData()
        
        // Create 50 sample transactions
        for _ in 0..<50 {
            let daysAgo = Int.random(in: 0...30)
            let transactionDate = calendar.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            
            let entity = TransactionEntity(context: context)
            entity.id = UUID()
            entity.timestamp = transactionDate
            entity.category = categories.randomElement() ?? "Other"
            
            // Random transaction type (70% expenses, 30% income)
            if Int.random(in: 1...10) <= 7 {
                // Expense
                entity.type = "expense"
                entity.amountBTC = Double.random(in: 0.001...0.05) // 0.001 to 0.05 BTC
            } else {
                // Income
                entity.type = "income"
                entity.amountBTC = Double.random(in: 0.01...0.2) // 0.01 to 0.2 BTC
            }
            
            print("📝 Created \(entity.type!) transaction: \(String(format: "%.6f", entity.amountBTC)) BTC in \(entity.category!) on \(DateFormatter.localizedString(from: transactionDate, dateStyle: .short, timeStyle: .none))")
        }
        
        // Save context
        do {
            try context.save()
            print("✅ Sample data created successfully!")
            print("📊 Created 50 sample transactions across different categories and dates")
        } catch {
            print("❌ Failed to save sample data: \(error)")
        }
    }
    
    private func clearExistingData() {
        let context = CoreDataStack.shared.context
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        
        do {
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            try context.save()
            print("🗑️ Cleared existing transaction data")
        } catch {
            print("⚠️ Failed to clear existing data: \(error)")
        }
    }
}
