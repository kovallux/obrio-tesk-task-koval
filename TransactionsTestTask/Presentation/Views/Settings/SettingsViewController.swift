//
//  SettingsViewController.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit
import Combine

class SettingsViewController: UIViewController {
    
    // MARK: - Properties
    private let exportService = ExportService()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingsCell")
        tableView.register(SettingsSwitchCell.self, forCellReuseIdentifier: "SwitchCell")
        return tableView
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Data
    
    private let settingsSections: [SettingsSection] = [
        SettingsSection(
            title: "Export & Backup",
            items: [
                SettingsItem(title: "Export to CSV", subtitle: "Export all transactions", type: .action(.exportCSV)),
                SettingsItem(title: "Export to JSON", subtitle: "Export with metadata", type: .action(.exportJSON)),
                SettingsItem(title: "Export to PDF", subtitle: "Generate report", type: .action(.exportPDF)),
                SettingsItem(title: "Create Backup", subtitle: "Backup app data", type: .action(.createBackup))
            ]
        ),
        SettingsSection(
            title: "Preferences",
            items: [
                SettingsItem(title: "Auto-refresh Rate", subtitle: "Update Bitcoin rate automatically", type: .toggle(.autoRefresh)),
                SettingsItem(title: "Show USD Values", subtitle: "Display amounts in USD", type: .toggle(.showUSD)),
                SettingsItem(title: "Enable Notifications", subtitle: "Rate change alerts", type: .toggle(.notifications))
            ]
        ),
        SettingsSection(
            title: "About",
            items: [
                SettingsItem(title: "Version", subtitle: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", type: .info),
                SettingsItem(title: "Build", subtitle: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1", type: .info),
                SettingsItem(title: "Bitcoin Rate API", subtitle: "CoinCap API 3.0", type: .info)
            ]
        )
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = .systemBackground
        
        // Navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        // Add subviews
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Table View
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Export Methods
    
    private func exportToCSV() {
        print("Settings: Exporting to CSV")
        loadingIndicator.startAnimating()
        
        // Get all transactions first (simplified for demo)
        let sampleTransactions: [Transaction] = [] // In real app, fetch from repository
        
        exportService.exportToCSV(sampleTransactions)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.loadingIndicator.stopAnimating()
                    if case .failure(let error) = completion {
                        self?.showErrorAlert(message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] fileURL in
                    self?.showShareSheet(for: fileURL)
                }
            )
            .store(in: &cancellables)
    }
    
    private func exportToJSON() {
        print("Settings: Exporting to JSON")
        loadingIndicator.startAnimating()
        
        let sampleTransactions: [Transaction] = []
        
        exportService.exportToJSON(sampleTransactions)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.loadingIndicator.stopAnimating()
                    if case .failure(let error) = completion {
                        self?.showErrorAlert(message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] fileURL in
                    self?.showShareSheet(for: fileURL)
                }
            )
            .store(in: &cancellables)
    }
    
    private func exportToPDF() {
        print("Settings: Exporting to PDF")
        loadingIndicator.startAnimating()
        
        let sampleTransactions: [Transaction] = []
        let sampleStats: TransactionStatistics? = nil
        
        exportService.exportToPDF(sampleTransactions, statistics: sampleStats)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.loadingIndicator.stopAnimating()
                    if case .failure(let error) = completion {
                        self?.showErrorAlert(message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] fileURL in
                    self?.showShareSheet(for: fileURL)
                }
            )
            .store(in: &cancellables)
    }
    
    private func createBackup() {
        print("Settings: Creating backup")
        loadingIndicator.startAnimating()
        
        exportService.createBackup()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.loadingIndicator.stopAnimating()
                    if case .failure(let error) = completion {
                        self?.showErrorAlert(message: error.localizedDescription)
                    }
                },
                receiveValue: { [weak self] fileURL in
                    self?.showSuccessAlert(message: "Backup created successfully!")
                    self?.showShareSheet(for: fileURL)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    private func showShareSheet(for fileURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsSections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsSections[section].title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = settingsSections[indexPath.section].items[indexPath.row]
        
        switch item.type {
        case .toggle(let setting):
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell", for: indexPath) as! SettingsSwitchCell
            cell.configure(with: item, setting: setting)
            return cell
            
        case .action, .info:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
            cell.textLabel?.text = item.title
            cell.detailTextLabel?.text = item.subtitle
            cell.accessoryType = item.type.accessoryType
            return cell
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = settingsSections[indexPath.section].items[indexPath.row]
        
        switch item.type {
        case .action(let action):
            handleAction(action)
        case .toggle, .info:
            break
        }
    }
    
    private func handleAction(_ action: SettingsAction) {
        switch action {
        case .exportCSV:
            exportToCSV()
        case .exportJSON:
            exportToJSON()
        case .exportPDF:
            exportToPDF()
        case .createBackup:
            createBackup()
        }
    }
}

// MARK: - Settings Switch Cell

class SettingsSwitchCell: UITableViewCell {
    
    private lazy var switchControl: UISwitch = {
        let switchControl = UISwitch()
        switchControl.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
        return switchControl
    }()
    
    private var currentSetting: SettingsToggle?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        accessoryView = switchControl
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        accessoryView = switchControl
        selectionStyle = .none
    }
    
    func configure(with item: SettingsItem, setting: SettingsToggle) {
        textLabel?.text = item.title
        detailTextLabel?.text = item.subtitle
        currentSetting = setting
        switchControl.isOn = UserDefaults.standard.bool(forKey: setting.userDefaultsKey)
    }
    
    @objc private func switchValueChanged() {
        guard let setting = currentSetting else { return }
        UserDefaults.standard.set(switchControl.isOn, forKey: setting.userDefaultsKey)
        print("Settings: \(setting.userDefaultsKey) changed to \(switchControl.isOn)")
    }
}

// MARK: - Data Models

struct SettingsSection {
    let title: String
    let items: [SettingsItem]
}

struct SettingsItem {
    let title: String
    let subtitle: String
    let type: SettingsItemType
}

enum SettingsItemType {
    case action(SettingsAction)
    case toggle(SettingsToggle)
    case info
    
    var accessoryType: UITableViewCell.AccessoryType {
        switch self {
        case .action:
            return .disclosureIndicator
        case .toggle:
            return .none
        case .info:
            return .none
        }
    }
}

enum SettingsAction {
    case exportCSV
    case exportJSON
    case exportPDF
    case createBackup
}

enum SettingsToggle {
    case autoRefresh
    case showUSD
    case notifications
    
    var userDefaultsKey: String {
        switch self {
        case .autoRefresh:
            return "settings_auto_refresh"
        case .showUSD:
            return "settings_show_usd"
        case .notifications:
            return "settings_notifications"
        }
    }
} 