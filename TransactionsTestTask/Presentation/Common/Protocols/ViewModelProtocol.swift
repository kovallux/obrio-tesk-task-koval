//
//  ViewModelProtocol.swift
//  TransactionsTestTask
//
//  Created by Sergii Koval on 16.06.2025.
//

import Foundation
import Combine

protocol ViewModelProtocol: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    
    func refresh()
}

// MARK: - Default Implementation
extension ViewModelProtocol {
    func handleError(_ error: Error, context: String = "") {
        let message = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        errorMessage = message
        print("ViewModel Error - \(message)")
        
        // Clear error message after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.errorMessage == message {
                self?.errorMessage = nil
            }
        }
    }
} 