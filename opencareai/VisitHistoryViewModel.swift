//
//  VisitHistoryViewModel.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// ViewModels/VisitHistoryViewModel.swift
import Foundation

@MainActor
class VisitHistoryViewModel: ObservableObject {
    @Published var visits: [Visit] = []
    @Published var errorMessage: String?

    func fetchVisits() {
        FirebaseService.shared.fetchVisits { [weak self] result in
            switch result {
            case .success(let visits):
                self?.visits = visits
            case .failure(let error):
                self?.errorMessage = "Failed to fetch visits: \(error.localizedDescription)"
            }
        }
    }
}