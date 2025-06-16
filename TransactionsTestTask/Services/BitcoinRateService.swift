//
//  BitcoinRateService.swift
//  TransactionsTestTask
//
//

import Foundation
import Combine

/// Rate Service fetches Bitcoin price from CoinCap API 3.0
/// Fetching should be scheduled with dynamic update interval
/// Rate should be cached for the offline mode
/// Every successful fetch should be logged with analytics service
/// The service should be covered by unit tests
protocol BitcoinRateService: AnyObject {
    var ratePublisher: AnyPublisher<Double, Never> { get }
    var currentBitcoinRate: Double { get }
    func fetchRate() -> AnyPublisher<Double, Error>
    func fetchBitcoinRatePublisher() -> AnyPublisher<Double, Error>
    func startPeriodicFetch()
    func stopPeriodicFetch()
}

final class BitcoinRateServiceImpl: BitcoinRateService {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let session: URLSession
    private let baseURL = "https://rest.coincap.io/v3"
    
    @Published private var currentRate: Double = 0.0
    private var cancellables = Set<AnyCancellable>()
    private var fetchTimer: Timer?
    
    var ratePublisher: AnyPublisher<Double, Never> {
        $currentRate
            .filter { $0 > 0 }
            .eraseToAnyPublisher()
    }
    
    var currentBitcoinRate: Double {
        return currentRate
    }
    
    // MARK: - Init
    
    init(apiKey: String, session: URLSession = URLSession.shared) {
        self.apiKey = apiKey
        self.session = session
        
        // Load cached rate on initialization
        if let cachedRate = loadCachedRate() {
            self.currentRate = cachedRate
        }
        
        print("BitcoinRateService: Initialized with API key")
    }
    
    // MARK: - Fetch Rate
    
    func fetchRate() -> AnyPublisher<Double, Error> {
        guard let url = URL(string: "\(baseURL)/assets/bitcoin?apiKey=\(apiKey)") else {
            print("BitcoinRateService: Invalid URL")
            return Fail(error: BitcoinRateError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("BitcoinRateService: Fetching rate from CoinCap API...")
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: CoinCapResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard let priceString = response.data.priceUsd,
                      let price = Double(priceString) else {
                    throw BitcoinRateError.invalidResponse
                }
                return price
            }
            .handleEvents(
                receiveOutput: { [weak self] rate in
                    print("BitcoinRateService: Successfully fetched rate: $\(String(format: "%.2f", rate))")
                    self?.currentRate = rate
                    self?.cacheRate(rate)
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("BitcoinRateService: Failed to fetch rate - Error: \(error)")
                    }
                }
            )
            .catch { [weak self] error -> AnyPublisher<Double, Error> in
                print("BitcoinRateService: Network request failed, trying cached rate...")
                if let cachedRate = self?.loadCachedRate() {
                    self?.currentRate = cachedRate
                    return Just(cachedRate)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } else {
                    return Fail(error: error)
                        .eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }
    
    func fetchBitcoinRatePublisher() -> AnyPublisher<Double, Error> {
        return fetchRate()
    }
    
    // MARK: - Periodic Fetch
    
    func startPeriodicFetch() {
        print("BitcoinRateService: Starting periodic fetch every 3 minutes")
        
        // Initial fetch
        fetchRate()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Schedule periodic fetch every 3 minutes (180 seconds)
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 180, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.fetchRate()
                .sink(
                    receiveCompletion: { _ in },
                    receiveValue: { _ in }
                )
                .store(in: &self.cancellables)
        }
    }
    
    func stopPeriodicFetch() {
        print("BitcoinRateService: Stopping periodic fetch")
        fetchTimer?.invalidate()
        fetchTimer = nil
        cancellables.removeAll()
    }
    
    // MARK: - Caching
    
    private func cacheRate(_ rate: Double) {
        let cacheData = CachedRate(rate: rate, timestamp: Date())
        
        do {
            let data = try JSONEncoder().encode(cacheData)
            let url = getCacheURL()
            try data.write(to: url)
            print("BitcoinRateService: Cached rate to disk: $\(String(format: "%.2f", rate))")
        } catch {
            print("BitcoinRateService: Failed to cache rate - Error: \(error)")
        }
    }
    
    private func loadCachedRate() -> Double? {
        do {
            let url = getCacheURL()
            let data = try Data(contentsOf: url)
            let cachedRate = try JSONDecoder().decode(CachedRate.self, from: data)
            
            // Check if cache is not older than 1 hour
            let oneHourAgo = Date().addingTimeInterval(-3600)
            if cachedRate.timestamp > oneHourAgo {
                print("BitcoinRateService: Loaded cached rate: $\(String(format: "%.2f", cachedRate.rate))")
                return cachedRate.rate
            } else {
                print("BitcoinRateService: Cached rate is too old, ignoring")
                return nil
            }
        } catch {
            print("BitcoinRateService: Failed to load cached rate - Error: \(error)")
            return nil
        }
    }
    
    private func getCacheURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("bitcoin_rate_cache.json")
    }
}

// MARK: - Data Models

struct CoinCapResponse: Codable {
    let data: BitcoinData
}

struct BitcoinData: Codable {
    let id: String
    let rank: String
    let symbol: String
    let name: String
    let supply: String?
    let maxSupply: String?
    let marketCapUsd: String?
    let volumeUsd24Hr: String?
    let priceUsd: String?
    let changePercent24Hr: String?
    let vwap24Hr: String?
}

struct CachedRate: Codable {
    let rate: Double
    let timestamp: Date
}

// MARK: - Errors

enum BitcoinRateError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid API response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
