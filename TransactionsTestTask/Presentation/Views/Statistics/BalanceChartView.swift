//
//  BalanceChartView.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 17.06.2025.
//

import UIKit

class BalanceChartView: UIView {
    
    // MARK: - UI Components
    private let titleLabel = UILabel()
    private let chartContainerView = UIView()
    private let noDataLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    
    // MARK: - Properties
    private var dataPoints: [BalanceDataPoint] = []
    private var chartLayers: [CALayer] = []
    
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
        titleLabel.text = "Balance History"
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor.label
        
        // Chart container
        chartContainerView.backgroundColor = UIColor.clear
        chartContainerView.layer.cornerRadius = 8
        chartContainerView.layer.borderWidth = 1
        chartContainerView.layer.borderColor = UIColor.separator.cgColor
        
        // No data label
        noDataLabel.text = "No data available"
        noDataLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        noDataLabel.textColor = UIColor.secondaryLabel
        noDataLabel.textAlignment = .center
        noDataLabel.isHidden = true
        
        // Loading indicator
        loadingIndicator.hidesWhenStopped = true
        
        addSubview(titleLabel)
        addSubview(chartContainerView)
        addSubview(noDataLabel)
        addSubview(loadingIndicator)
        
        [titleLabel, chartContainerView, noDataLabel, loadingIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Title
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // Chart container
            chartContainerView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            chartContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            chartContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chartContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // No data label
            noDataLabel.centerXAnchor.constraint(equalTo: chartContainerView.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: chartContainerView.centerYAnchor),
            
            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: chartContainerView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: chartContainerView.centerYAnchor)
        ])
    }
    
    // MARK: - Configuration
    func configure(with dataPoints: [BalanceDataPoint]) {
        self.dataPoints = dataPoints
        
        if dataPoints.isEmpty {
            showNoData()
        } else {
            hideNoData()
            drawChart()
        }
    }
    
    func showLoadingState() {
        loadingIndicator.startAnimating()
        noDataLabel.isHidden = true
        clearChart()
    }
    
    func hideLoadingState() {
        loadingIndicator.stopAnimating()
    }
    
    // MARK: - Private Methods
    private func showNoData() {
        noDataLabel.isHidden = false
        clearChart()
    }
    
    private func hideNoData() {
        noDataLabel.isHidden = true
    }
    
    private func clearChart() {
        chartLayers.forEach { $0.removeFromSuperlayer() }
        chartLayers.removeAll()
    }
    
    private func drawChart() {
        clearChart()
        
        guard !dataPoints.isEmpty else { return }
        
        let chartBounds = chartContainerView.bounds.insetBy(dx: 20, dy: 20)
        guard chartBounds.width > 0 && chartBounds.height > 0 else { return }
        
        // Calculate min/max values
        let balances = dataPoints.map { $0.balance }
        let minBalance = balances.min() ?? 0
        let maxBalance = balances.max() ?? 0
        let range = maxBalance - minBalance
        
        // Avoid division by zero
        let adjustedRange = range == 0 ? 1 : range
        
        // Create path for line chart
        let linePath = UIBezierPath()
        let gradientPath = UIBezierPath()
        
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = chartBounds.minX + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * chartBounds.width
            let normalizedValue = (dataPoint.balance - minBalance) / adjustedRange
            let y = chartBounds.maxY - normalizedValue * chartBounds.height
            
            if index == 0 {
                linePath.move(to: CGPoint(x: x, y: y))
                gradientPath.move(to: CGPoint(x: x, y: chartBounds.maxY))
                gradientPath.addLine(to: CGPoint(x: x, y: y))
            } else {
                linePath.addLine(to: CGPoint(x: x, y: y))
                gradientPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Close gradient path
        if let lastPoint = dataPoints.last {
            let lastX = chartBounds.minX + CGFloat(dataPoints.count - 1) / CGFloat(dataPoints.count - 1) * chartBounds.width
            gradientPath.addLine(to: CGPoint(x: lastX, y: chartBounds.maxY))
        }
        gradientPath.close()
        
        // Create gradient layer
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = chartContainerView.bounds
        gradientLayer.colors = [
            UIColor.systemBlue.withAlphaComponent(0.3).cgColor,
            UIColor.systemBlue.withAlphaComponent(0.0).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        
        let gradientMask = CAShapeLayer()
        gradientMask.path = gradientPath.cgPath
        gradientLayer.mask = gradientMask
        
        // Create line layer
        let lineLayer = CAShapeLayer()
        lineLayer.path = linePath.cgPath
        lineLayer.strokeColor = UIColor.systemBlue.cgColor
        lineLayer.fillColor = UIColor.clear.cgColor
        lineLayer.lineWidth = 2.0
        lineLayer.lineCap = .round
        lineLayer.lineJoin = .round
        
        // Add layers
        chartContainerView.layer.addSublayer(gradientLayer)
        chartContainerView.layer.addSublayer(lineLayer)
        
        chartLayers.append(gradientLayer)
        chartLayers.append(lineLayer)
        
        // Add data point indicators
        addDataPointIndicators(in: chartBounds, minBalance: minBalance, range: adjustedRange)
        
        // Add axis labels
        addAxisLabels(in: chartBounds, minBalance: minBalance, maxBalance: maxBalance)
    }
    
    private func addDataPointIndicators(in chartBounds: CGRect, minBalance: Double, range: Double) {
        for (index, dataPoint) in dataPoints.enumerated() {
            let x = chartBounds.minX + (CGFloat(index) / CGFloat(dataPoints.count - 1)) * chartBounds.width
            let normalizedValue = (dataPoint.balance - minBalance) / range
            let y = chartBounds.maxY - normalizedValue * chartBounds.height
            
            let indicatorLayer = CAShapeLayer()
            let indicatorPath = UIBezierPath(ovalIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6))
            indicatorLayer.path = indicatorPath.cgPath
            indicatorLayer.fillColor = UIColor.systemBlue.cgColor
            indicatorLayer.strokeColor = UIColor.systemBackground.cgColor
            indicatorLayer.lineWidth = 1.0
            
            chartContainerView.layer.addSublayer(indicatorLayer)
            chartLayers.append(indicatorLayer)
        }
    }
    
    private func addAxisLabels(in chartBounds: CGRect, minBalance: Double, maxBalance: Double) {
        // Y-axis labels (balance values)
        let yLabels = [minBalance, (minBalance + maxBalance) / 2, maxBalance]
        
        for (index, value) in yLabels.enumerated() {
            let label = CATextLayer()
            label.string = String(format: "%.4f", value)
            label.font = UIFont.systemFont(ofSize: 10)
            label.fontSize = 10
            label.foregroundColor = UIColor.secondaryLabel.cgColor
            label.contentsScale = UIScreen.main.scale
            
            let y = chartBounds.maxY - CGFloat(index) * (chartBounds.height / 2)
            label.frame = CGRect(x: 0, y: y - 6, width: 50, height: 12)
            
            chartContainerView.layer.addSublayer(label)
            chartLayers.append(label)
        }
        
        // X-axis labels (dates)
        if dataPoints.count > 1 {
            let xLabels = [dataPoints.first!, dataPoints.last!]
            
            for (index, dataPoint) in xLabels.enumerated() {
                let label = CATextLayer()
                label.string = dataPoint.formattedDate
                label.font = UIFont.systemFont(ofSize: 10)
                label.fontSize = 10
                label.foregroundColor = UIColor.secondaryLabel.cgColor
                label.contentsScale = UIScreen.main.scale
                
                let x = index == 0 ? chartBounds.minX : chartBounds.maxX - 40
                label.frame = CGRect(x: x, y: chartBounds.maxY + 5, width: 40, height: 12)
                
                chartContainerView.layer.addSublayer(label)
                chartLayers.append(label)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Redraw chart when bounds change
        if !dataPoints.isEmpty {
            drawChart()
        }
    }
} 