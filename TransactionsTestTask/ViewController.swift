//
//  ViewController.swift
//  TransactionsTestTask
//
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    private let bitcoinService = ServicesAssembler.bitcoinRateService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        testLoggingSystem()
    }
    
    private func testLoggingSystem() {
        print("🧪 ViewController: Testing logging system...")
        
        // Subscribe to rate updates and log them
        bitcoinService.ratePublisher
            .sink { rate in
                print("🧪 ViewController: Logged rate update: $\(String(format: "%.2f", rate))")
            }
            .store(in: &cancellables)
        
        print("🧪 ViewController: Logging system test complete")
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Bitcoin Rate Service Test\nCheck console for logs"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
