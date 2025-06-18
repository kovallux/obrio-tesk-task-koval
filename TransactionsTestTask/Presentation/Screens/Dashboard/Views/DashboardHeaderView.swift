//
//  DashboardHeaderView.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit

class DashboardHeaderView: UIView {
    
    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 8
        return view
    }()
    
    private lazy var bitcoinRateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Bitcoin Rate"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var bitcoinRateValueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "$0.00"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var bitcoinRateStatusView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        return view
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private lazy var balanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Total Balance"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var balanceBTCLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0.00000000 BTC"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var balanceUSDLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "$0.00 USD"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var lastUpdatedLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Last updated: --"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.addSubview(bitcoinRateLabel)
        containerView.addSubview(bitcoinRateValueLabel)
        containerView.addSubview(bitcoinRateStatusView)
        containerView.addSubview(separatorView)
        containerView.addSubview(balanceLabel)
        containerView.addSubview(balanceBTCLabel)
        containerView.addSubview(balanceUSDLabel)
        containerView.addSubview(lastUpdatedLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Bitcoin Rate Section
            bitcoinRateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            bitcoinRateLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            
            bitcoinRateStatusView.centerYAnchor.constraint(equalTo: bitcoinRateLabel.centerYAnchor),
            bitcoinRateStatusView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            bitcoinRateStatusView.widthAnchor.constraint(equalToConstant: 8),
            bitcoinRateStatusView.heightAnchor.constraint(equalToConstant: 8),
            
            bitcoinRateValueLabel.topAnchor.constraint(equalTo: bitcoinRateLabel.bottomAnchor, constant: 8),
            bitcoinRateValueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            bitcoinRateValueLabel.trailingAnchor.constraint(lessThanOrEqualTo: bitcoinRateStatusView.leadingAnchor, constant: -16),
            
            // Separator
            separatorView.topAnchor.constraint(equalTo: bitcoinRateValueLabel.bottomAnchor, constant: 20),
            separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            // Balance Section
            balanceLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 20),
            balanceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            balanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            balanceBTCLabel.topAnchor.constraint(equalTo: balanceLabel.bottomAnchor, constant: 8),
            balanceBTCLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            balanceBTCLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            balanceUSDLabel.topAnchor.constraint(equalTo: balanceBTCLabel.bottomAnchor, constant: 4),
            balanceUSDLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            balanceUSDLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Last Updated
            lastUpdatedLabel.topAnchor.constraint(equalTo: balanceUSDLabel.bottomAnchor, constant: 16),
            lastUpdatedLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            lastUpdatedLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            lastUpdatedLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Public Methods
    func updateBitcoinRate(_ rate: Double) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        if rate > 0 {
            bitcoinRateValueLabel.text = formatter.string(from: NSNumber(value: rate)) ?? "$0.00"
            bitcoinRateStatusView.backgroundColor = .systemGreen
        } else {
            bitcoinRateValueLabel.text = "Loading..."
            bitcoinRateStatusView.backgroundColor = .systemOrange
        }
        
        updateLastUpdatedTime()
    }
    
    func updateBalance(_ balance: Double) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        formatter.minimumFractionDigits = 8
        
        balanceBTCLabel.text = "\(formatter.string(from: NSNumber(value: balance)) ?? "0.00000000") BTC"
        
        // Update text color based on balance
        if balance > 0 {
            balanceBTCLabel.textColor = .systemGreen
        } else if balance < 0 {
            balanceBTCLabel.textColor = .systemRed
        } else {
            balanceBTCLabel.textColor = .label
        }
    }
    
    func updateBalanceUSD(_ balanceUSD: Double) {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 2
        
        balanceUSDLabel.text = "\(formatter.string(from: NSNumber(value: balanceUSD)) ?? "$0.00") USD"
        
        // Update text color based on balance
        if balanceUSD > 0 {
            balanceUSDLabel.textColor = .systemGreen
        } else if balanceUSD < 0 {
            balanceUSDLabel.textColor = .systemRed
        } else {
            balanceUSDLabel.textColor = .secondaryLabel
        }
    }
    
    private func updateLastUpdatedTime() {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        lastUpdatedLabel.text = "Last updated: \(formatter.string(from: Date()))"
    }
} 
