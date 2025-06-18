//
//  DashboardViewController.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit
import Combine

class DashboardViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel: DashboardViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        scrollView.contentInsetAdjustmentBehavior = .automatic
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerView: DashboardHeaderView = {
        let view = DashboardHeaderView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var transactionListView: TransactionListView = {
        let view = TransactionListView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    private lazy var addTransactionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add Transaction", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 4
        button.addTarget(self, action: #selector(addTransactionTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        control.tintColor = .systemBlue
        control.attributedTitle = NSAttributedString(
            string: "Pull to refresh",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        return control
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    // MARK: - Initialization
    init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshBitcoinRate()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Expense Tracker"
        view.backgroundColor = .systemBackground
        
        // Add navigation bar buttons
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTransactionTapped)
        )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chart.bar.fill"),
            style: .plain,
            target: self,
            action: #selector(showStatistics)
        )
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        scrollView.refreshControl = refreshControl
        
        contentView.addSubview(headerView)
        contentView.addSubview(transactionListView)
        contentView.addSubview(errorLabel)
        
        view.addSubview(addTransactionButton)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor, constant: 1),
            
            // HeaderView
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // TransactionListView
            transactionListView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 24),
            transactionListView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            transactionListView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            transactionListView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            
            // Error Label
            errorLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: transactionListView.centerYAnchor),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 32),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -32),
            
            // Add Transaction Button
            addTransactionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addTransactionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addTransactionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addTransactionButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Bitcoin Rate
        viewModel.$currentBitcoinRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.headerView.updateBitcoinRate(rate)
            }
            .store(in: &cancellables)
        
        // Balance
        viewModel.$totalBalance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balance in
                self?.headerView.updateBalance(balance)
            }
            .store(in: &cancellables)
        
        // Balance in USD
        viewModel.$balanceInUSD
            .receive(on: DispatchQueue.main)
            .sink { [weak self] balanceUSD in
                self?.headerView.updateBalanceUSD(balanceUSD)
            }
            .store(in: &cancellables)
        
        // Transactions
        viewModel.$transactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                self?.transactionListView.updateTransactions(transactions)
                self?.errorLabel.isHidden = !transactions.isEmpty
            }
            .store(in: &cancellables)
        
        // Loading State
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        // Error Message
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage, !error.isEmpty {
                    self?.errorLabel.text = error
                    self?.errorLabel.isHidden = false
                    self?.showErrorAlert(message: error)
                } else {
                    self?.errorLabel.isHidden = true
                }
            }
            .store(in: &cancellables)
        
        // Has More Transactions
        viewModel.$hasMoreTransactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasMore in
                self?.transactionListView.updateLoadMoreState(hasMore)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func addTransactionTapped() {
        let addTransactionVC = AddTransactionViewController()
        addTransactionVC.delegate = self
        let navController = UINavigationController(rootViewController: addTransactionVC)
        present(navController, animated: true)
    }
    
    @objc private func refreshData() {
        viewModel.refresh()
    }
    
    @objc private func showStatistics() {
        let statisticsVC = StatisticsViewController()
        let navController = UINavigationController(rootViewController: statisticsVC)
        
        statisticsVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: statisticsVC,
            action: #selector(StatisticsViewController.dismissViewController)
        )
        
        present(navController, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TransactionListViewDelegate
extension DashboardViewController: TransactionListViewDelegate {
    func didRequestLoadMore() {
        viewModel.loadMoreTransactions()
    }
    
    func didSelectTransaction(_ transaction: Transaction) {
        // TODO: Implement transaction detail view
        print("Selected transaction: \(transaction.id)")
    }
}

// MARK: - AddTransactionViewControllerDelegate
extension DashboardViewController: AddTransactionViewControllerDelegate {
    func didAddTransaction() {
        viewModel.refresh()
    }
}

// MARK: - AddTransactionViewControllerDelegate Protocol
protocol AddTransactionViewControllerDelegate: AnyObject {
    func didAddTransaction()
} 
