//
//  StatisticsViewController.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit
import CoreData
import Combine

class StatisticsViewController: UIViewController {
    
    // MARK: - Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let context = CoreDataStack.shared.context
    private let bitcoinRateService = BitcoinRateService.shared
    
    private var transactions: [Transaction] = []
    private var currentBitcoinRate: Double = 0.0
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var totalTransactionsCard: StatisticsCardView = {
        return StatisticsCardView(
            title: "Total Transactions",
            value: "0",
            subtitle: "All time",
            iconName: "list.bullet",
            color: .systemBlue
        )
    }()
    
    private lazy var totalIncomeCard: StatisticsCardView = {
        return StatisticsCardView(
            title: "Total Income",
            value: "0.00 BTC",
            subtitle: "$0.00",
            iconName: "arrow.up.circle.fill",
            color: .systemGreen
        )
    }()
    
    private lazy var totalExpensesCard: StatisticsCardView = {
        return StatisticsCardView(
            title: "Total Expenses",
            value: "0.00 BTC",
            subtitle: "$0.00",
            iconName: "arrow.down.circle.fill",
            color: .systemRed
        )
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        loadStatistics()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Statistics"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        view.addSubview(loadingIndicator)
        
        contentStackView.addArrangedSubview(totalTransactionsCard)
        contentStackView.addArrangedSubview(totalIncomeCard)
        contentStackView.addArrangedSubview(totalExpensesCard)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        bitcoinRateService.$currentRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.currentBitcoinRate = rate
                self?.updateStatistics()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func refreshTapped() {
        loadStatistics()
        bitcoinRateService.fetchBitcoinRate()
    }
    
    @objc func dismissViewController() {
        dismiss(animated: true)
    }
    
    // MARK: - Data Loading
    
    private func loadStatistics() {
        loadingIndicator.startAnimating()
        
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let entities = try context.fetch(request)
            transactions = entities.map { Transaction(from: $0) }
            updateStatistics()
        } catch {
            print("Failed to load transactions: \(error.localizedDescription)")
        }
        
        loadingIndicator.stopAnimating()
    }
    
    private func updateStatistics() {
        let totalCount = transactions.count
        let totalIncome = transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amountBTC }
        let totalExpenses = transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amountBTC }
        
        totalTransactionsCard.updateValue("\(totalCount)")
        
        let incomeUSD = totalIncome * currentBitcoinRate
        totalIncomeCard.updateValue(String(format: "%.4f BTC", totalIncome))
        totalIncomeCard.updateSubtitle(String(format: "$%.2f", incomeUSD))
        
        let expensesUSD = totalExpenses * currentBitcoinRate
        totalExpensesCard.updateValue(String(format: "%.4f BTC", totalExpenses))
        totalExpensesCard.updateSubtitle(String(format: "$%.2f", expensesUSD))
    }
}

// MARK: - Statistics Card View

class StatisticsCardView: UIView {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.1
        view.layer.shadowRadius = 4
        return view
    }()
    
    init(title: String, value: String, subtitle: String, iconName: String, color: UIColor) {
        super.init(frame: .zero)
        
        titleLabel.text = title
        valueLabel.text = value
        subtitleLabel.text = subtitle
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = color
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        containerView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 100),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 32),
            iconImageView.heightAnchor.constraint(equalToConstant: 32),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            valueLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func updateValue(_ newValue: String) {
        valueLabel.text = newValue
    }
    
    func updateSubtitle(_ newSubtitle: String) {
        subtitleLabel.text = newSubtitle
    }
} 