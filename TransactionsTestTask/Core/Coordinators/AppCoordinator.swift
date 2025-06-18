//
//  AppCoordinator.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }
    
    func start()
}

class AppCoordinator: Coordinator {
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        showDashboard()
    }
    
    private func showDashboard() {
        let dashboardViewModel = DashboardViewModel()
        let dashboardVC = DashboardViewController(viewModel: dashboardViewModel)
        dashboardVC.coordinator = self
        navigationController.setViewControllers([dashboardVC], animated: false)
    }
    
    func showAddTransaction(from viewController: UIViewController) {
        let addTransactionVC = AddTransactionViewController()
        addTransactionVC.delegate = viewController as? AddTransactionViewControllerDelegate
        let navController = UINavigationController(rootViewController: addTransactionVC)
        viewController.present(navController, animated: true)
    }
    
    func showStatistics(from viewController: UIViewController) {
        let statisticsVC = StatisticsViewController()
        let navController = UINavigationController(rootViewController: statisticsVC)
        
        statisticsVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: statisticsVC,
            action: #selector(StatisticsViewController.dismissViewController)
        )
        
        viewController.present(navController, animated: true)
    }
    
    func showSettings(from viewController: UIViewController) {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        viewController.present(navController, animated: true)
    }
} 