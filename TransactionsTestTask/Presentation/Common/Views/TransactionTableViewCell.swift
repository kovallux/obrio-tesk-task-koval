//
//  TransactionTableViewCell.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    
    static let identifier = "TransactionTableViewCell"
    
    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.05
        view.layer.shadowRadius = 3
        return view
    }()
    
    private lazy var typeIconView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 20
        return view
    }()
    
    private lazy var typeIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        return label
    }()
    
    private lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private lazy var amountLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .right
        return label
    }()
    
    private lazy var amountSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(typeIconView)
        typeIconView.addSubview(typeIconImageView)
        containerView.addSubview(categoryLabel)
        containerView.addSubview(timestampLabel)
        containerView.addSubview(amountLabel)
        containerView.addSubview(amountSubtitleLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container View
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Type Icon View
            typeIconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            typeIconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            typeIconView.widthAnchor.constraint(equalToConstant: 40),
            typeIconView.heightAnchor.constraint(equalToConstant: 40),
            
            // Type Icon Image View
            typeIconImageView.centerXAnchor.constraint(equalTo: typeIconView.centerXAnchor),
            typeIconImageView.centerYAnchor.constraint(equalTo: typeIconView.centerYAnchor),
            typeIconImageView.widthAnchor.constraint(equalToConstant: 20),
            typeIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // Category Label
            categoryLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            categoryLabel.leadingAnchor.constraint(equalTo: typeIconView.trailingAnchor, constant: 12),
            categoryLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -12),
            
            // Timestamp Label
            timestampLabel.topAnchor.constraint(equalTo: categoryLabel.bottomAnchor, constant: 4),
            timestampLabel.leadingAnchor.constraint(equalTo: typeIconView.trailingAnchor, constant: 12),
            timestampLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountSubtitleLabel.leadingAnchor, constant: -12),
            timestampLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            
            // Amount Label
            amountLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            amountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            amountLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            
            // Amount Subtitle Label
            amountSubtitleLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            amountSubtitleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            amountSubtitleLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),
            amountSubtitleLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100)
        ])
    }
    
    // MARK: - Configuration
    func configure(with transaction: Transaction) {
        categoryLabel.text = transaction.category
        timestampLabel.text = transaction.formattedTimestamp
        
        // Configure type icon and colors
        switch transaction.type {
        case .income:
            typeIconView.backgroundColor = .systemGreen
            typeIconImageView.image = UIImage(systemName: "arrow.down.left")
            amountLabel.textColor = .systemGreen
            amountLabel.text = "+\(transaction.formattedAmount)"
            
        case .expense:
            typeIconView.backgroundColor = .systemRed
            typeIconImageView.image = UIImage(systemName: "arrow.up.right")
            amountLabel.textColor = .systemRed
            amountLabel.text = "-\(transaction.formattedAmount)"
        }
        
        // Amount subtitle (BTC)
        amountSubtitleLabel.text = "BTC"
        
        // Add subtle animation on configuration
        containerView.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.containerView.transform = .identity
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        categoryLabel.text = nil
        timestampLabel.text = nil
        amountLabel.text = nil
        amountSubtitleLabel.text = nil
        typeIconImageView.image = nil
        containerView.transform = .identity
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.1) {
            self.containerView.transform = highlighted ? 
                CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            self.containerView.alpha = highlighted ? 0.8 : 1.0
        }
    }
} 
