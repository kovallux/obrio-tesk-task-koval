//
//  CategoryBreakdownView.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 17.06.2025.
//

import UIKit

class CategoryBreakdownView: UIView {
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let pieChartView = PieChartView()
    private let categoryListView = CategoryListView()
    private let noDataLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    private var categoryData: [CategoryData] = []
    
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
        
        // Title
        titleLabel.text = "Category Breakdown"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor.label
        
        // No data label
        noDataLabel.text = "No categories to display"
        noDataLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        noDataLabel.textColor = UIColor.secondaryLabel
        noDataLabel.textAlignment = .center
        noDataLabel.isHidden = true
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        
        addSubview(titleLabel)
        addSubview(pieChartView)
        addSubview(categoryListView)
        addSubview(noDataLabel)
        addSubview(loadingIndicator)
        
        [titleLabel, pieChartView, categoryListView, noDataLabel, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Pie chart
            pieChartView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            pieChartView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            pieChartView.widthAnchor.constraint(equalToConstant: 120),
            pieChartView.heightAnchor.constraint(equalToConstant: 120),
            
            // Category list
            categoryListView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            categoryListView.leadingAnchor.constraint(equalTo: pieChartView.trailingAnchor, constant: 16),
            categoryListView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            categoryListView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // No data label
            noDataLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with categoryData: [CategoryData]) {
        // Calculate percentages
        let totalAmount = categoryData.reduce(0) { $0 + $1.totalAmount }
        let dataWithPercentages = categoryData.map { category in
            CategoryData(
                category: category.category,
                totalAmount: category.totalAmount,
                transactionCount: category.transactionCount,
                averageAmount: category.averageAmount,
                percentage: totalAmount > 0 ? (category.totalAmount / totalAmount) * 100 : 0
            )
        }
        
        self.categoryData = dataWithPercentages
        
        if categoryData.isEmpty {
            showNoData()
        } else {
            hideNoData()
            pieChartView.configure(with: dataWithPercentages)
            categoryListView.configure(with: dataWithPercentages)
        }
    }
    
    func showLoadingState() {
        loadingIndicator.startAnimating()
        noDataLabel.isHidden = true
        pieChartView.isHidden = true
        categoryListView.isHidden = true
    }
    
    func hideLoadingState() {
        loadingIndicator.stopAnimating()
        pieChartView.isHidden = false
        categoryListView.isHidden = false
    }
    
    // MARK: - Private Methods
    private func showNoData() {
        noDataLabel.isHidden = false
        pieChartView.isHidden = true
        categoryListView.isHidden = true
    }
    
    private func hideNoData() {
        noDataLabel.isHidden = true
        pieChartView.isHidden = false
        categoryListView.isHidden = false
    }
}

// MARK: - PieChartView
class PieChartView: UIView {
    
    private var categoryData: [CategoryData] = []
    private var chartLayers: [CALayer] = []
    
    private let colors: [UIColor] = [
        .systemBlue, .systemGreen, .systemOrange, .systemRed, .systemPurple,
        .systemYellow, .systemPink, .systemTeal, .systemIndigo, .systemBrown
    ]
    
    func configure(with categoryData: [CategoryData]) {
        self.categoryData = categoryData
        drawPieChart()
    }
    
    private func drawPieChart() {
        // Clear existing layers
        chartLayers.forEach { $0.removeFromSuperlayer() }
        chartLayers.removeAll()
        
        guard !categoryData.isEmpty else { return }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10
        
        var startAngle: CGFloat = -CGFloat.pi / 2 // Start from top
        
        for (index, category) in categoryData.enumerated() {
            let percentage = category.percentage / 100
            let endAngle = startAngle + CGFloat(percentage * 2 * Double.pi)
            
            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            path.close()
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath
            shapeLayer.fillColor = colors[index % colors.count].cgColor
            shapeLayer.strokeColor = UIColor.systemBackground.cgColor
            shapeLayer.lineWidth = 2
            
            layer.addSublayer(shapeLayer)
            chartLayers.append(shapeLayer)
            
            startAngle = endAngle
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !categoryData.isEmpty {
            drawPieChart()
        }
    }
}

// MARK: - CategoryListView
class CategoryListView: UIView {
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    private let colors: [UIColor] = [
        .systemBlue, .systemGreen, .systemOrange, .systemRed, .systemPurple,
        .systemYellow, .systemPink, .systemTeal, .systemIndigo, .systemBrown
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Scroll view
        scrollView.showsVerticalScrollIndicator = false
        addSubview(scrollView)
        
        // Stack view
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fill
        scrollView.addSubview(stackView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }
    
    func configure(with categoryData: [CategoryData]) {
        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, category) in categoryData.enumerated() {
            let categoryRowView = CategoryRowView()
            categoryRowView.configure(
                category: category,
                color: colors[index % colors.count]
            )
            stackView.addArrangedSubview(categoryRowView)
        }
    }
}

// MARK: - CategoryRowView
class CategoryRowView: UIView {
    
    private let colorIndicator = UIView()
    private let categoryLabel = UILabel()
    private let percentageLabel = UILabel()
    private let amountLabel = UILabel()
    private let countLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        // Color indicator
        colorIndicator.layer.cornerRadius = 6
        colorIndicator.layer.masksToBounds = true
        
        // Category label
        categoryLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        categoryLabel.textColor = UIColor.label
        
        // Percentage label
        percentageLabel.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        percentageLabel.textColor = UIColor.secondaryLabel
        percentageLabel.textAlignment = .right
        
        // Amount label
        amountLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        amountLabel.textColor = UIColor.secondaryLabel
        
        // Count label
        countLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        countLabel.textColor = UIColor.tertiaryLabel
        
        addSubview(colorIndicator)
        addSubview(categoryLabel)
        addSubview(percentageLabel)
        addSubview(amountLabel)
        addSubview(countLabel)
        
        [colorIndicator, categoryLabel, percentageLabel, amountLabel, countLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            colorIndicator.leadingAnchor.constraint(equalTo: leadingAnchor),
            colorIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),
            colorIndicator.widthAnchor.constraint(equalToConstant: 12),
            colorIndicator.heightAnchor.constraint(equalToConstant: 12),
            
            categoryLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 8),
            categoryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            
            percentageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            percentageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            percentageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: categoryLabel.trailingAnchor, constant: 8),
            
            amountLabel.leadingAnchor.constraint(equalTo: colorIndicator.trailingAnchor, constant: 8),
            amountLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 2),
            amountLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            countLabel.topAnchor.constraint(equalTo: percentageLabel.bottomAnchor, constant: 2),
            countLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            
            heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])
    }
    
    func configure(category: CategoryData, color: UIColor) {
        colorIndicator.backgroundColor = color
        categoryLabel.text = category.category
        percentageLabel.text = category.formattedPercentage
        amountLabel.text = category.formattedTotalAmount
        countLabel.text = "\(category.transactionCount) transactions"
    }
} 