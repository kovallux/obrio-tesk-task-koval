//
//  TransactionFilterView.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit
import Combine

protocol TransactionFilterViewDelegate: AnyObject {
    func filterView(_ filterView: TransactionFilterView, didApplyFilters filters: TransactionFilters)
    func filterViewDidClearFilters(_ filterView: TransactionFilterView)
}

class TransactionFilterView: UIView {
    
    weak var delegate: TransactionFilterViewDelegate?
    
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
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Filter Transactions"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        return scrollView
    }()
    
    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.distribution = .fill
        return stackView
    }()
    
    // MARK: - Filter Components
    
    private lazy var typeFilterView: FilterSectionView = {
        let view = FilterSectionView(title: "Transaction Type")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var typeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["All", "Income", "Expense"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 0
        control.backgroundColor = .systemGray6
        control.selectedSegmentTintColor = .systemBlue
        return control
    }()
    
    private lazy var categoryFilterView: FilterSectionView = {
        let view = FilterSectionView(title: "Category")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var categoryPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private lazy var dateRangeFilterView: FilterSectionView = {
        let view = FilterSectionView(title: "Date Range")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var dateRangeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var fromDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.maximumDate = Date()
        return picker
    }()
    
    private lazy var toDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.maximumDate = Date()
        return picker
    }()
    
    private lazy var amountRangeFilterView: FilterSectionView = {
        let view = FilterSectionView(title: "Amount Range (BTC)")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var amountRangeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var minAmountTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Min amount"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        return textField
    }()
    
    private lazy var maxAmountTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Max amount"
        textField.borderStyle = .roundedRect
        textField.keyboardType = .decimalPad
        return textField
    }()
    
    // MARK: - Action Buttons
    
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Clear", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(clearButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var applyButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Apply Filters", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.addTarget(self, action: #selector(applyButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Data
    
    private let categories = [
        "All Categories",
        "Food & Dining",
        "Transportation",
        "Shopping",
        "Entertainment",
        "Bills & Utilities",
        "Healthcare",
        "Education",
        "Travel",
        "Investment",
        "Salary",
        "Freelance",
        "Business",
        "Gift",
        "Other"
    ]
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupDelegates()
        setupInitialValues()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupDelegates()
        setupInitialValues()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStackView)
        
        // Add filter sections
        typeFilterView.addContentView(typeSegmentedControl)
        categoryFilterView.addContentView(categoryPickerView)
        
        dateRangeStackView.addArrangedSubview(fromDatePicker)
        dateRangeStackView.addArrangedSubview(toDatePicker)
        dateRangeFilterView.addContentView(dateRangeStackView)
        
        amountRangeStackView.addArrangedSubview(minAmountTextField)
        amountRangeStackView.addArrangedSubview(maxAmountTextField)
        amountRangeFilterView.addContentView(amountRangeStackView)
        
        buttonStackView.addArrangedSubview(clearButton)
        buttonStackView.addArrangedSubview(applyButton)
        
        contentStackView.addArrangedSubview(typeFilterView)
        contentStackView.addArrangedSubview(categoryFilterView)
        contentStackView.addArrangedSubview(dateRangeFilterView)
        contentStackView.addArrangedSubview(amountRangeFilterView)
        contentStackView.addArrangedSubview(buttonStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            containerView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20),
            containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            containerView.heightAnchor.constraint(lessThanOrEqualToConstant: 600),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            
            // Content Stack View
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Category Picker Height
            categoryPickerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Button Heights
            clearButton.heightAnchor.constraint(equalToConstant: 44),
            applyButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setupDelegates() {
        categoryPickerView.dataSource = self
        categoryPickerView.delegate = self
    }
    
    private func setupInitialValues() {
        // Set default date range (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        fromDatePicker.date = thirtyDaysAgo
        toDatePicker.date = Date()
    }
    
    // MARK: - Actions
    
    @objc private func clearButtonTapped() {
        typeSegmentedControl.selectedSegmentIndex = 0
        categoryPickerView.selectRow(0, inComponent: 0, animated: true)
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        fromDatePicker.date = thirtyDaysAgo
        toDatePicker.date = Date()
        
        minAmountTextField.text = ""
        maxAmountTextField.text = ""
        
        delegate?.filterViewDidClearFilters(self)
    }
    
    @objc private func applyButtonTapped() {
        let filters = TransactionFilters(
            type: getSelectedTransactionType(),
            category: getSelectedCategory(),
            dateRange: DateRange(from: fromDatePicker.date, to: toDatePicker.date),
            amountRange: getAmountRange()
        )
        
        delegate?.filterView(self, didApplyFilters: filters)
    }
    
    // MARK: - Helper Methods
    
    private func getSelectedTransactionType() -> TransactionType? {
        switch typeSegmentedControl.selectedSegmentIndex {
        case 1: return .income
        case 2: return .expense
        default: return nil
        }
    }
    
    private func getSelectedCategory() -> String? {
        let selectedRow = categoryPickerView.selectedRow(inComponent: 0)
        return selectedRow == 0 ? nil : categories[selectedRow]
    }
    
    private func getAmountRange() -> AmountRange? {
        let minText = minAmountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let maxText = maxAmountTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        let minAmount = minText.isEmpty ? nil : Double(minText)
        let maxAmount = maxText.isEmpty ? nil : Double(maxText)
        
        if minAmount != nil || maxAmount != nil {
            return AmountRange(min: minAmount, max: maxAmount)
        }
        
        return nil
    }
    
    func show(in parentView: UIView) {
        parentView.addSubview(self)
        self.frame = parentView.bounds
        self.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate

extension TransactionFilterView: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return categories[row]
    }
}

// MARK: - Filter Section View

class FilterSectionView: UIView {
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private lazy var contentContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(titleLabel)
        addSubview(contentContainer)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            contentContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func addContentView(_ view: UIView) {
        contentContainer.addSubview(view)
        
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor)
        ])
    }
}

 