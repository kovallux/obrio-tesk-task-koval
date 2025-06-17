//
//  StatisticsViewController.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 17.06.2025.
//

import UIKit
import Combine

class StatisticsViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerView = StatisticsHeaderView()
    private let periodSegmentedControl = UISegmentedControl(items: ["Week", "Month", "3M", "Year"])
    private let metricsContainerView = UIView()
    private let categoryContainerView = UIView()
    private let insightsContainerView = UIView()
    
    // MARK: - Properties
    private var viewModel = StatisticsViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupConstraints()
        viewModel.loadStatistics()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Statistics"
        view.backgroundColor = UIColor.systemBackground
        
        // Navigation bar setup
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(exportStatistics)
        )
        
        // Period control setup
        periodSegmentedControl.selectedSegmentIndex = 1 // Month
        periodSegmentedControl.addTarget(self, action: #selector(periodChanged), for: .valueChanged)
        
        // Scroll view setup
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        
        // Container views
        metricsContainerView.backgroundColor = UIColor.secondarySystemBackground
        metricsContainerView.layer.cornerRadius = 12
        
        categoryContainerView.backgroundColor = UIColor.secondarySystemBackground
        categoryContainerView.layer.cornerRadius = 12
        
        insightsContainerView.backgroundColor = UIColor.secondarySystemBackground
        insightsContainerView.layer.cornerRadius = 12
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerView)
        contentView.addSubview(periodSegmentedControl)
        contentView.addSubview(metricsContainerView)
        contentView.addSubview(categoryContainerView)
        contentView.addSubview(insightsContainerView)
        
        // Configure subviews
        [headerView, periodSegmentedControl, metricsContainerView, categoryContainerView, insightsContainerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        setupContainerContent()
    }
    
    private func setupContainerContent() {
        // Metrics container content
        let metricsLabel = createSectionLabel("Key Metrics")
        let metricsContentLabel = createContentLabel("Loading metrics...")
        
        metricsContainerView.addSubview(metricsLabel)
        metricsContainerView.addSubview(metricsContentLabel)
        
        metricsLabel.translatesAutoresizingMaskIntoConstraints = false
        metricsContentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            metricsLabel.topAnchor.constraint(equalTo: metricsContainerView.topAnchor, constant: 16),
            metricsLabel.leadingAnchor.constraint(equalTo: metricsContainerView.leadingAnchor, constant: 16),
            metricsLabel.trailingAnchor.constraint(equalTo: metricsContainerView.trailingAnchor, constant: -16),
            
            metricsContentLabel.topAnchor.constraint(equalTo: metricsLabel.bottomAnchor, constant: 12),
            metricsContentLabel.leadingAnchor.constraint(equalTo: metricsContainerView.leadingAnchor, constant: 16),
            metricsContentLabel.trailingAnchor.constraint(equalTo: metricsContainerView.trailingAnchor, constant: -16),
            metricsContentLabel.bottomAnchor.constraint(equalTo: metricsContainerView.bottomAnchor, constant: -16)
        ])
        
        // Category container content
        let categoryLabel = createSectionLabel("Category Breakdown")
        let categoryContentLabel = createContentLabel("Loading categories...")
        
        categoryContainerView.addSubview(categoryLabel)
        categoryContainerView.addSubview(categoryContentLabel)
        
        categoryLabel.translatesAutoresizingMaskIntoConstraints = false
        categoryContentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            categoryLabel.topAnchor.constraint(equalTo: categoryContainerView.topAnchor, constant: 16),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryContainerView.leadingAnchor, constant: 16),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryContainerView.trailingAnchor, constant: -16),
            
            categoryContentLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 12),
            categoryContentLabel.leadingAnchor.constraint(equalTo: categoryContainerView.leadingAnchor, constant: 16),
            categoryContentLabel.trailingAnchor.constraint(equalTo: categoryContainerView.trailingAnchor, constant: -16),
            categoryContentLabel.bottomAnchor.constraint(equalTo: categoryContainerView.bottomAnchor, constant: -16)
        ])
        
        // Insights container content
        let insightsLabel = createSectionLabel("Insights")
        let insightsContentLabel = createContentLabel("Loading insights...")
        
        insightsContainerView.addSubview(insightsLabel)
        insightsContainerView.addSubview(insightsContentLabel)
        
        insightsLabel.translatesAutoresizingMaskIntoConstraints = false
        insightsContentLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            insightsLabel.topAnchor.constraint(equalTo: insightsContainerView.topAnchor, constant: 16),
            insightsLabel.leadingAnchor.constraint(equalTo: insightsContainerView.leadingAnchor, constant: 16),
            insightsLabel.trailingAnchor.constraint(equalTo: insightsContainerView.trailingAnchor, constant: -16),
            
            insightsContentLabel.topAnchor.constraint(equalTo: insightsLabel.bottomAnchor, constant: 12),
            insightsContentLabel.leadingAnchor.constraint(equalTo: insightsContainerView.leadingAnchor, constant: 16),
            insightsContentLabel.trailingAnchor.constraint(equalTo: insightsContainerView.trailingAnchor, constant: -16),
            insightsContentLabel.bottomAnchor.constraint(equalTo: insightsContainerView.bottomAnchor, constant: -16)
        ])
    }
    
    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textColor = UIColor.label
        return label
    }
    
    private func createContentLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.secondaryLabel
        label.numberOfLines = 0
        return label
    }
    
    private func setupBindings() {
        // Statistics data binding
        viewModel.$statistics
            .receive(on: DispatchQueue.main)
            .sink { [weak self] statistics in
                self?.updateUI(with: statistics)
            }
            .store(in: &cancellables)
        
        // Loading state binding
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
        
        // Error handling
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.showError(error)
            }
            .store(in: &cancellables)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Scroll view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content view
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            headerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Period control
            periodSegmentedControl.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 20),
            periodSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            periodSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            periodSegmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            // Metrics container
            metricsContainerView.topAnchor.constraint(equalTo: periodSegmentedControl.bottomAnchor, constant: 20),
            metricsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            metricsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            metricsContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            // Category container
            categoryContainerView.topAnchor.constraint(equalTo: metricsContainerView.bottomAnchor, constant: 20),
            categoryContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            categoryContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            categoryContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            
            // Insights container
            insightsContainerView.topAnchor.constraint(equalTo: categoryContainerView.bottomAnchor, constant: 20),
            insightsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            insightsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            insightsContainerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            insightsContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    @objc private func periodChanged() {
        let periods: [StatisticsPeriod] = [.week, .month, .threeMonths, .year]
        let selectedPeriod = periods[periodSegmentedControl.selectedSegmentIndex]
        viewModel.changePeriod(selectedPeriod)
    }
    
    @objc private func exportStatistics() {
        viewModel.exportStatistics { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self?.presentShareSheet(for: url)
                case .failure(let error):
                    self?.showError(error.localizedDescription)
                }
            }
        }
    }
    
    @objc func dismissViewController() {
        dismiss(animated: true)
    }
    
    // MARK: - UI Updates
    private func updateUI(with statistics: TransactionStatistics?) {
        guard let statistics = statistics else { return }
        
        headerView.configure(with: statistics)
        updateMetricsContent(with: statistics)
        updateCategoryContent(with: statistics)
        updateInsightsContent(with: statistics)
    }
    
    private func updateMetricsContent(with statistics: TransactionStatistics) {
        if let metricsContentLabel = metricsContainerView.subviews.last as? UILabel {
            let metricsText = """
            Average Transaction: \(String(format: "%.6f BTC", statistics.averageTransactionAmount))
            Largest Transaction: \(String(format: "%.6f BTC", statistics.largestTransaction))
            Smallest Transaction: \(String(format: "%.6f BTC", statistics.smallestTransaction))
            
            Transaction Count:
            • Income: \(statistics.transactionCount.income)
            • Expenses: \(statistics.transactionCount.expense)
            """
            metricsContentLabel.text = metricsText
        }
    }
    
    private func updateCategoryContent(with statistics: TransactionStatistics) {
        if let categoryContentLabel = categoryContainerView.subviews.last as? UILabel {
            var categoryText = ""
            
            if statistics.categoryBreakdown.isEmpty {
                categoryText = "No categories available for the selected period."
            } else {
                categoryText = "Top categories for this period:\n\n"
                for (index, category) in statistics.categoryBreakdown.prefix(5).enumerated() {
                    categoryText += "\(index + 1). \(category.category)\n"
                    categoryText += "   Amount: \(category.formattedTotalAmount)\n"
                    categoryText += "   Transactions: \(category.transactionCount)\n"
                    categoryText += "   Average: \(category.formattedAverageAmount)\n\n"
                }
            }
            
            categoryContentLabel.text = categoryText
        }
    }
    
    private func updateInsightsContent(with statistics: TransactionStatistics) {
        if let insightsContentLabel = insightsContainerView.subviews.last as? UILabel {
            var insightsText = ""
            
            if statistics.insights.isEmpty {
                insightsText = "No insights available for the selected period."
            } else {
                for insight in statistics.insights {
                    insightsText += "• \(insight.title)\n"
                    insightsText += "  \(insight.description)\n\n"
                }
            }
            
            insightsContentLabel.text = insightsText
        }
    }
    
    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            // Show loading state
            if let metricsLabel = metricsContainerView.subviews.last as? UILabel {
                metricsLabel.text = "Loading metrics..."
            }
            if let categoryLabel = categoryContainerView.subviews.last as? UILabel {
                categoryLabel.text = "Loading categories..."
            }
            if let insightsLabel = insightsContainerView.subviews.last as? UILabel {
                insightsLabel.text = "Loading insights..."
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func presentShareSheet(for url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityVC, animated: true)
    }
}



// MARK: - SimpleMetricView
class SimpleMetricView: UIView {
    
    private let titleLabel = UILabel()
    private let valueLabel = UILabel()
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
        backgroundColor = UIColor.tertiarySystemBackground
        layer.cornerRadius = 8
        
        // Color indicator
        colorIndicator.layer.cornerRadius = 2
        
        // Title
        titleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = UIColor.secondaryLabel
        titleLabel.textAlignment = .center
        
        // Value
        valueLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        valueLabel.textColor = UIColor.label
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        
        addSubview(colorIndicator)
        addSubview(titleLabel)
        addSubview(valueLabel)
        
        [colorIndicator, titleLabel, valueLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            colorIndicator.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            colorIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 16),
            colorIndicator.heightAnchor.constraint(equalToConstant: 3),
            
            titleLabel.topAnchor.constraint(equalTo: colorIndicator.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            valueLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4)
        ])
    }
    
    func configure(title: String, value: String, color: UIColor) {
        titleLabel.text = title
        valueLabel.text = value
        colorIndicator.backgroundColor = color
    }
} 