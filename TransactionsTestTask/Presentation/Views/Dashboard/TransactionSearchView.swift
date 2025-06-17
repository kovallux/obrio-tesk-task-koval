//
//  TransactionSearchView.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit
import Combine

protocol TransactionSearchViewDelegate: AnyObject {
    func searchView(_ searchView: TransactionSearchView, didSearchWithQuery query: String)
    func searchViewDidClearSearch(_ searchView: TransactionSearchView)
}

class TransactionSearchView: UIView {
    
    weak var delegate: TransactionSearchViewDelegate?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
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
    
    private lazy var searchTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Search transactions..."
        textField.font = .systemFont(ofSize: 16)
        textField.borderStyle = .none
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .search
        return textField
    }()
    
    private lazy var searchIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "magnifyingglass")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var filterButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "line.3.horizontal.decrease.circle"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(filterButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var resultsCountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .secondaryLabel
        label.isHidden = true
        return label
    }()
    
    // MARK: - Properties
    
    @Published private var searchQuery: String = ""
    private var isSearchActive: Bool = false
    
    var onFilterButtonTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(searchIconImageView)
        containerView.addSubview(searchTextField)
        containerView.addSubview(filterButton)
        addSubview(resultsCountLabel)
        
        searchTextField.delegate = self
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 44),
            
            // Search Icon
            searchIconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            searchIconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            searchIconImageView.widthAnchor.constraint(equalToConstant: 20),
            searchIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Search Text Field
            searchTextField.leadingAnchor.constraint(equalTo: searchIconImageView.trailingAnchor, constant: 8),
            searchTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            searchTextField.trailingAnchor.constraint(equalTo: filterButton.leadingAnchor, constant: -8),
            
            // Filter Button
            filterButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            filterButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            filterButton.widthAnchor.constraint(equalToConstant: 30),
            filterButton.heightAnchor.constraint(equalToConstant: 30),
            
            // Results Count Label
            resultsCountLabel.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: 8),
            resultsCountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            resultsCountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            resultsCountLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupBindings() {
        // Debounce search input
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                
                if query.isEmpty {
                    self.delegate?.searchViewDidClearSearch(self)
                    self.hideResultsCount()
                } else {
                    self.delegate?.searchView(self, didSearchWithQuery: query)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func filterButtonTapped() {
        onFilterButtonTapped?()
    }
    
    // MARK: - Public Methods
    
    func updateResultsCount(_ count: Int) {
        if isSearchActive && !searchQuery.isEmpty {
            resultsCountLabel.text = "\(count) result\(count == 1 ? "" : "s") found"
            resultsCountLabel.isHidden = false
        } else {
            hideResultsCount()
        }
    }
    
    func clearSearch() {
        searchTextField.text = ""
        searchQuery = ""
        isSearchActive = false
        hideResultsCount()
    }
    
    func setFilterActive(_ isActive: Bool) {
        filterButton.tintColor = isActive ? .systemOrange : .systemBlue
        filterButton.setImage(
            UIImage(systemName: isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle"),
            for: .normal
        )
    }
    
    private func hideResultsCount() {
        resultsCountLabel.isHidden = true
    }
}

// MARK: - UITextFieldDelegate

extension TransactionSearchView: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        let newText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        searchQuery = newText
        isSearchActive = !newText.isEmpty
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        isSearchActive = true
        
        UIView.animate(withDuration: 0.2) {
            self.containerView.layer.shadowOpacity = 0.2
            self.containerView.transform = CGAffineTransform(scaleX: 1.02, y: 1.02)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.2) {
            self.containerView.layer.shadowOpacity = 0.1
            self.containerView.transform = .identity
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        searchQuery = ""
        isSearchActive = false
        hideResultsCount()
        delegate?.searchViewDidClearSearch(self)
        return true
    }
} 