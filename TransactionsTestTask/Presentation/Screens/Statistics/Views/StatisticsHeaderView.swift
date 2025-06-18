//
//  StatisticsHeaderView.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 17.06.2025.
//

import UIKit

class StatisticsHeaderView: UIView {
    
    // MARK: - UI Components
    private let containerView = UIView()
    private let netBalanceLabel = UILabel()
    private let netBalanceValueLabel = UILabel()
    private let netBalanceUSDLabel = UILabel()
    
    private let metricsStackView = UIStackView()
    private let incomeMetricView = MetricView()
    private let expenseMetricView = MetricView()
    private let transactionCountMetricView = MetricView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor.secondarySystemBackground
        layer.cornerRadius = 12
        layer.masksToBounds = true
        
        // Container
        containerView.backgroundColor = UIColor.clear
        addSubview(containerView)
        
        // Net Balance
        netBalanceLabel.text = "Net Balance"
        netBalanceLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        netBalanceLabel.textColor = UIColor.secondaryLabel
        netBalanceLabel.textAlignment = .center
        
        netBalanceValueLabel.text = "0.00000000 BTC"
        netBalanceValueLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        netBalanceValueLabel.textColor = UIColor.label
        netBalanceValueLabel.textAlignment = .center
        
        netBalanceUSDLabel.text = "$0.00"
        netBalanceUSDLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        netBalanceUSDLabel.textColor = UIColor.secondaryLabel
        netBalanceUSDLabel.textAlignment = .center
        
        // Metrics Stack View
        metricsStackView.axis = .horizontal
        metricsStackView.distribution = .fillEqually
        metricsStackView.spacing = 1
        metricsStackView.backgroundColor = UIColor.separator
        
        // Configure metric views
        incomeMetricView.configure(title: "Income", value: "0.00000000 BTC", subtitle: "$0.00", color: .systemGreen)
        expenseMetricView.configure(title: "Expenses", value: "0.00000000 BTC", subtitle: "$0.00", color: .systemRed)
        transactionCountMetricView.configure(title: "Transactions", value: "0", subtitle: "Total", color: .systemBlue)
        
        metricsStackView.addArrangedSubview(incomeMetricView)
        metricsStackView.addArrangedSubview(expenseMetricView)
        metricsStackView.addArrangedSubview(transactionCountMetricView)
        
        // Add to container
        containerView.addSubview(netBalanceLabel)
        containerView.addSubview(netBalanceValueLabel)
        containerView.addSubview(netBalanceUSDLabel)
        containerView.addSubview(metricsStackView)
        
        // Configure constraints
        [containerView, netBalanceLabel, netBalanceValueLabel, netBalanceUSDLabel, metricsStackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // Net Balance Label
            netBalanceLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            netBalanceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            netBalanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Net Balance Value
            netBalanceValueLabel.topAnchor.constraint(equalTo: netBalanceLabel.bottomAnchor, constant: 4),
            netBalanceValueLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            netBalanceValueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Net Balance USD
            netBalanceUSDLabel.topAnchor.constraint(equalTo: netBalanceValueLabel.bottomAnchor, constant: 2),
            netBalanceUSDLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            netBalanceUSDLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            // Metrics Stack
            metricsStackView.topAnchor.constraint(equalTo: netBalanceUSDLabel.bottomAnchor, constant: 16),
            metricsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            metricsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            metricsStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            metricsStackView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    // MARK: - Configuration
    func configure(with statistics: TransactionStatistics) {
        netBalanceValueLabel.text = statistics.formattedNetBalance
        netBalanceUSDLabel.text = statistics.formattedNetBalanceUSD
        
        // Update net balance color based on positive/negative
        if statistics.netBalance >= 0 {
            netBalanceValueLabel.textColor = UIColor.systemGreen
        } else {
            netBalanceValueLabel.textColor = UIColor.systemRed
        }
        
        // Update metrics
        incomeMetricView.configure(
            title: "Income",
            value: statistics.formattedTotalIncome,
            subtitle: statistics.formattedTotalIncomeUSD,
            color: .systemGreen
        )
        
        expenseMetricView.configure(
            title: "Expenses",
            value: statistics.formattedTotalExpenses,
            subtitle: statistics.formattedTotalExpensesUSD,
            color: .systemRed
        )
        
        transactionCountMetricView.configure(
            title: "Transactions",
            value: "\(statistics.totalTransactions)",
            subtitle: "Total",
            color: .systemBlue
        )
    }
}

// MARK: - MetricView
class MetricView: UIView {
    
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let colorIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        backgroundColor = UIColor.secondarySystemBackground
        
        // Color indicator
        colorIndicator.layer.cornerRadius = 2
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = UIColor.secondaryLabel
        titleLabel.textAlignment = .center
        
        // Value
        valueLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = UIColor.label
        valueLabel.textAlignment = .center
        valueLabel.numberOfLines = 0
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.8
        
        // Subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = UIColor.secondaryLabel
        subtitleLabel.textAlignment = .center
        
        addSubview(colorIndicator)
        addSubview(titleLabel)
        addSubview(valueLabel)
        addSubview(subtitleLabel)
        
        [colorIndicator, titleLabel, valueLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            colorIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            colorIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 20),
            colorIndicator.heightAnchor.constraint(equalToConstant: 4),
            
            titleLabel.topAnchor.constraint(equalTo: colorIndicator.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            
            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4)
        ])
    }
    
    func configure(title: String, value: String, subtitle: String, color: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        colorIndicator.backgroundColor = color
    }
} 