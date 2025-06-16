//
//  AddTransactionViewController.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit
import Combine

class AddTransactionViewController: UIViewController {
    
    // MARK: - Properties
    private let viewModel = AddTransactionViewModel()
    private var cancellables = Set<AnyCancellable>()
    weak var delegate: AddTransactionViewControllerDelegate?
    
    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.keyboardDismissMode = .onDrag
        return scrollView
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Add Transaction"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private lazy var typeSegmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Income", "Expense"])
        control.translatesAutoresizingMaskIntoConstraints = false
        control.selectedSegmentIndex = 1 // Default to Expense
        control.addTarget(self, action: #selector(typeChanged), for: .valueChanged)
        return control
    }()
    
    private lazy var amountContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        return view
    }()
    
    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Amount (BTC)"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var amountTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "0.00000000"
        textField.keyboardType = .decimalPad
        textField.font = .systemFont(ofSize: 18, weight: .regular)
        textField.textColor = .label
        textField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        return textField
    }()
    
    private lazy var amountErrorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private lazy var categoryContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        return view
    }()
    
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Category"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private lazy var categoryPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    private lazy var customCategoryTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter custom category"
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.textColor = .label
        textField.isHidden = true
        textField.addTarget(self, action: #selector(customCategoryChanged), for: .editingChanged)
        return textField
    }()
    
    private lazy var categoryErrorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()
    
    private lazy var quickAmountStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()
    
    private lazy var addButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Add Transaction", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(addTransactionTapped), for: .touchUpInside)
        return button
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
        setupQuickAmountButtons()
        setupKeyboardHandling()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        amountTextField.becomeFirstResponder()
    }
    
    // MARK: - Setup
    private func setupUI() {
        title = "Add Transaction"
        view.backgroundColor = .systemGroupedBackground
        
        // Navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(typeSegmentedControl)
        contentView.addSubview(amountContainerView)
        contentView.addSubview(amountErrorLabel)
        contentView.addSubview(categoryContainerView)
        contentView.addSubview(categoryErrorLabel)
        contentView.addSubview(quickAmountStackView)
        contentView.addSubview(addButton)
        
        amountContainerView.addSubview(amountLabel)
        amountContainerView.addSubview(amountTextField)
        
        categoryContainerView.addSubview(categoryLabel)
        categoryContainerView.addSubview(categoryPickerView)
        categoryContainerView.addSubview(customCategoryTextField)
        
        view.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Title Label
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Type Segmented Control
            typeSegmentedControl.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            typeSegmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            typeSegmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            typeSegmentedControl.heightAnchor.constraint(equalToConstant: 44),
            
            // Amount Container
            amountContainerView.topAnchor.constraint(equalTo: typeSegmentedControl.bottomAnchor, constant: 24),
            amountContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            amountContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Amount Label
            amountLabel.topAnchor.constraint(equalTo: amountContainerView.topAnchor, constant: 16),
            amountLabel.leadingAnchor.constraint(equalTo: amountContainerView.leadingAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: amountContainerView.trailingAnchor, constant: -16),
            
            // Amount TextField
            amountTextField.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 8),
            amountTextField.leadingAnchor.constraint(equalTo: amountContainerView.leadingAnchor, constant: 16),
            amountTextField.trailingAnchor.constraint(equalTo: amountContainerView.trailingAnchor, constant: -16),
            amountTextField.bottomAnchor.constraint(equalTo: amountContainerView.bottomAnchor, constant: -16),
            amountTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Amount Error Label
            amountErrorLabel.topAnchor.constraint(equalTo: amountContainerView.bottomAnchor, constant: 8),
            amountErrorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            amountErrorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Quick Amount Stack View
            quickAmountStackView.topAnchor.constraint(equalTo: amountErrorLabel.bottomAnchor, constant: 16),
            quickAmountStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            quickAmountStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            quickAmountStackView.heightAnchor.constraint(equalToConstant: 40),
            
            // Category Container
            categoryContainerView.topAnchor.constraint(equalTo: quickAmountStackView.bottomAnchor, constant: 24),
            categoryContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categoryContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Category Label
            categoryLabel.topAnchor.constraint(equalTo: categoryContainerView.topAnchor, constant: 16),
            categoryLabel.leadingAnchor.constraint(equalTo: categoryContainerView.leadingAnchor, constant: 16),
            categoryLabel.trailingAnchor.constraint(equalTo: categoryContainerView.trailingAnchor, constant: -16),
            
            // Category Picker View
            categoryPickerView.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8),
            categoryPickerView.leadingAnchor.constraint(equalTo: categoryContainerView.leadingAnchor),
            categoryPickerView.trailingAnchor.constraint(equalTo: categoryContainerView.trailingAnchor),
            categoryPickerView.bottomAnchor.constraint(equalTo: categoryContainerView.bottomAnchor, constant: -16),
            categoryPickerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Custom Category TextField
            customCategoryTextField.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 8),
            customCategoryTextField.leadingAnchor.constraint(equalTo: categoryContainerView.leadingAnchor, constant: 16),
            customCategoryTextField.trailingAnchor.constraint(equalTo: categoryContainerView.trailingAnchor, constant: -16),
            customCategoryTextField.heightAnchor.constraint(equalToConstant: 44),
            
            // Category Error Label
            categoryErrorLabel.topAnchor.constraint(equalTo: categoryContainerView.bottomAnchor, constant: 8),
            categoryErrorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            categoryErrorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            // Add Button
            addButton.topAnchor.constraint(equalTo: categoryErrorLabel.bottomAnchor, constant: 32),
            addButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        // Amount validation
        viewModel.$amountError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.amountErrorLabel.text = error
                self?.amountErrorLabel.isHidden = error?.isEmpty ?? true
                self?.updateAmountContainerBorder(hasError: !(error?.isEmpty ?? true))
            }
            .store(in: &cancellables)
        
        // Category validation
        viewModel.$categoryError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.categoryErrorLabel.text = error
                self?.categoryErrorLabel.isHidden = error?.isEmpty ?? true
                self?.updateCategoryContainerBorder(hasError: !(error?.isEmpty ?? true))
            }
            .store(in: &cancellables)
        
        // Loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                    self?.addButton.isEnabled = false
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.addButton.isEnabled = true
                }
            }
            .store(in: &cancellables)
        
        // Success state
        viewModel.$isTransactionAdded
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAdded in
                if isAdded {
                    self?.delegate?.didAddTransaction()
                    self?.dismiss(animated: true)
                }
            }
            .store(in: &cancellables)
        
        // Selected category
        viewModel.$selectedCategory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] category in
                self?.updateCategorySelection(category)
            }
            .store(in: &cancellables)
    }
    
    private func setupQuickAmountButtons() {
        let amounts = ["0.001", "0.01", "0.1"]
        
        for amount in amounts {
            let button = UIButton(type: .system)
            button.setTitle("\(amount) BTC", for: .normal)
            button.backgroundColor = .systemGray6
            button.setTitleColor(.label, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
            button.layer.cornerRadius = 8
            button.addTarget(self, action: #selector(quickAmountTapped(_:)), for: .touchUpInside)
            quickAmountStackView.addArrangedSubview(button)
        }
    }
    
    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func typeChanged() {
        let isIncome = typeSegmentedControl.selectedSegmentIndex == 0
        viewModel.toggleTransactionType()
        
        // Update UI colors based on type
        let color: UIColor = isIncome ? .systemGreen : .systemRed
        typeSegmentedControl.selectedSegmentTintColor = color
        addButton.backgroundColor = color
    }
    
    @objc private func amountChanged() {
        viewModel.amountText = amountTextField.text ?? ""
    }
    
    @objc private func customCategoryChanged() {
        viewModel.customCategory = customCategoryTextField.text ?? ""
    }
    
    @objc private func quickAmountTapped(_ sender: UIButton) {
        guard let title = sender.title(for: .normal),
              let amount = title.components(separatedBy: " ").first else { return }
        
        amountTextField.text = amount
        viewModel.amountText = amount
    }
    
    @objc private func addTransactionTapped() {
        view.endEditing(true)
        viewModel.addTransaction()
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.scrollIndicatorInsets.bottom = keyboardHeight
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets.bottom = 0
    }
    
    // MARK: - Helper Methods
    private func updateAmountContainerBorder(hasError: Bool) {
        amountContainerView.layer.borderColor = hasError ? UIColor.systemRed.cgColor : UIColor.separator.cgColor
    }
    
    private func updateCategoryContainerBorder(hasError: Bool) {
        categoryContainerView.layer.borderColor = hasError ? UIColor.systemRed.cgColor : UIColor.separator.cgColor
    }
    
    private func updateCategorySelection(_ category: String) {
        if category == "Custom" {
            categoryPickerView.isHidden = true
            customCategoryTextField.isHidden = false
            
            // Update container height constraint
            categoryContainerView.constraints.forEach { constraint in
                if constraint.firstAttribute == .bottom && constraint.secondItem === categoryPickerView {
                    constraint.isActive = false
                }
            }
            
            customCategoryTextField.bottomAnchor.constraint(equalTo: categoryContainerView.bottomAnchor, constant: -16).isActive = true
        } else {
            categoryPickerView.isHidden = false
            customCategoryTextField.isHidden = true
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UIPickerViewDataSource & UIPickerViewDelegate
extension AddTransactionViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return viewModel.categories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return viewModel.categories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let category = viewModel.categories[row]
        viewModel.selectCategory(category)
    }
} 
