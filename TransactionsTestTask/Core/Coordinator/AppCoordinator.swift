//
//  AppCoordinator.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import UIKit

class AppCoordinator {
    
    // MARK: - Properties
    private let window: UIWindow
    private var navigationController: UINavigationController?
    
    // MARK: - Dependencies
    // ServicesAssembler is an enum, not a class, so we access it statically
    
    // MARK: - Initialization
    init(window: UIWindow) {
        self.window = window
    }
    
    // MARK: - Public Methods
    func start() {
        setupMainFlow()
    }
    
    // MARK: - Private Methods
    private func setupMainFlow() {
        let dashboardViewModel = createDashboardViewModel()
        let dashboardViewController = DashboardViewController(viewModel: dashboardViewModel)
        
        let navigationController = UINavigationController(rootViewController: dashboardViewController)
        navigationController.navigationBar.prefersLargeTitles = true
        
        self.navigationController = navigationController
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    private func createDashboardViewModel() -> DashboardViewModel {
        // Create use cases
        let fetchTransactionsUseCase = FetchTransactionsUseCase()
        let updateBitcoinRateUseCase = UpdateBitcoinRateUseCase()
        
        // Create and return view model
        return DashboardViewModel(
            fetchTransactionsUseCase: fetchTransactionsUseCase,
            updateBitcoinRateUseCase: updateBitcoinRateUseCase
        )
    }
} 
