//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 17.06.2025.
//

import Foundation
import Combine

class BitcoinRateService: ObservableObject {
    static let shared = BitcoinRateService()
    
    @Published var currentRate: Double = 0.0
    @Published var isLoading: Bool = false
    @Published var lastError: String?
    
    private var timer: Timer?
    private let cacheKey = "cached_bitcoin_rate"
    private let cacheTimestampKey = "cached_bitcoin_rate_timestamp"
    private let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
    
    private init() {
        print("BitcoinRateService: Initializing...")
        loadCachedRate()
        startPeriodicFetch()
        fetchBitcoinRate() // Initial fetch
    }
    
    deinit {
        stopPeriodicFetch()
    }
    
    func startPeriodicFetch() {
        print("BitcoinRateService: Starting periodic fetch every 3 minutes")
        stopPeriodicFetch() // Stop any existing timer
        
        timer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            self?.fetchBitcoinRate()
        }
    }
    
    func stopPeriodicFetch() {
        print("BitcoinRateService: Stopping periodic fetch")
        timer?.invalidate()
        timer = nil
    }
    
    func fetchBitcoinRate() {
        print("BitcoinRateService: Fetching Bitcoin rate...")
        isLoading = true
        lastError = nil
        
        // Use CoinGecko API - free and reliable
        guard let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd") else {
            print("BitcoinRateService: ❌ Invalid URL")
            handleError("Invalid API URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        
        print("BitcoinRateService: 📡 Making API request to CoinGecko...")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }
            
            if let error = error {
                print("BitcoinRateService: ❌ Network error: \(error.localizedDescription)")
                self?.handleError("Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("BitcoinRateService: ❌ Invalid response type")
                self?.handleError("Invalid response")
                return
            }
            
            print("BitcoinRateService: 📊 HTTP Status Code: \(httpResponse.statusCode)")
            
            guard httpResponse.statusCode == 200 else {
                print("BitcoinRateService: ❌ HTTP Error: \(httpResponse.statusCode)")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("BitcoinRateService: Response body: \(responseString)")
                }
                self?.handleError("HTTP Error: \(httpResponse.statusCode)")
                return
            }
            
            guard let data = data else {
                print("BitcoinRateService: ❌ No data received")
                self?.handleError("No data received")
                return
            }
            
            print("BitcoinRateService: 📦 Received \(data.count) bytes of data")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("BitcoinRateService: ✅ JSON parsed successfully")
                
                if let bitcoin = json?["bitcoin"] as? [String: Any],
                   let price = bitcoin["usd"] as? Double {
                    
                    print("BitcoinRateService: ✅ Bitcoin price successfully extracted: $\(price)")
                    
                    DispatchQueue.main.async {
                        self?.currentRate = price
                        self?.lastError = nil
                    }
                    
                    // Cache the rate
                    self?.cacheRate(price)
                    
                    print("BitcoinRateService: 🎉 Bitcoin rate updated successfully!")
                } else {
                    print("BitcoinRateService: ❌ Failed to parse Bitcoin rate from JSON")
                    print("BitcoinRateService: JSON structure: \(String(describing: json))")
                    self?.handleError("Failed to parse Bitcoin rate")
                }
            } catch {
                print("BitcoinRateService: ❌ JSON parsing error: \(error.localizedDescription)")
                self?.handleError("JSON parsing error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    private func handleError(_ message: String) {
        print("BitcoinRateService: 🔄 Handling error: \(message)")
        DispatchQueue.main.async {
            self.lastError = message
            self.isLoading = false
        }
        
        // Try to load cached rate if available
        if currentRate == 0.0 {
            loadCachedRate()
        }
    }
    
    private func cacheRate(_ rate: Double) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cacheFilePath = documentsPath.appendingPathComponent("bitcoin_rate_cache.json")
        
        let cacheData = [
            "rate": rate,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: cacheData, options: [])
            try jsonData.write(to: cacheFilePath)
            print("BitcoinRateService: 💾 Rate cached successfully: $\(rate)")
        } catch {
            print("BitcoinRateService: ❌ Failed to cache rate: \(error.localizedDescription)")
        }
    }
    
    private func loadCachedRate() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cacheFilePath = documentsPath.appendingPathComponent("bitcoin_rate_cache.json")
        
        guard FileManager.default.fileExists(atPath: cacheFilePath.path) else {
            print("BitcoinRateService: 📝 No cached rate found")
            return
        }
        
        do {
            let jsonData = try Data(contentsOf: cacheFilePath)
            let cacheData = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
            
            guard let rate = cacheData?["rate"] as? Double,
                  let timestamp = cacheData?["timestamp"] as? TimeInterval else {
                print("BitcoinRateService: ❌ Invalid cached data format")
                return
            }
            
            let cacheAge = Date().timeIntervalSince1970 - timestamp
            
            if cacheAge < cacheExpirationInterval {
                DispatchQueue.main.async {
                    self.currentRate = rate
                }
                print("BitcoinRateService: 📱 Loaded cached rate: $\(rate) (age: \(Int(cacheAge))s)")
            } else {
                print("BitcoinRateService: ⏰ Cached rate expired (age: \(Int(cacheAge))s)")
            }
        } catch {
            print("BitcoinRateService: ❌ Failed to load cached rate: \(error.localizedDescription)")
        }
    }
}
