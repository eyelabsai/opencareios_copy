//
//  MedicationViewModel.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// ViewModels/MedicationViewModel.swift
import Foundation

@MainActor
class MedicationViewModel: ObservableObject {
    @Published var medications: [Medication] = []
    @Published var errorMessage: String?

    func fetchMedications() {
        FirebaseService.shared.fetchMedications { [weak self] result in
            switch result {
            case .success(let medications):
                self?.medications = medications
            case .failure(let error):
                self?.errorMessage = "Failed to fetch medications: \(error.localizedDescription)"
            }
        }
    }
}