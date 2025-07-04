//
//  UserViewModel.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// ViewModels/UserViewModel.swift
import Foundation

@MainActor
class UserViewModel: ObservableObject {
    @Published var user = User(email: "", name: "", chronicConditions: [])
    @Published var newCondition = ""
    @Published var errorMessage: String?

    func fetchUserProfile() {
        FirebaseService.shared.fetchUserProfile { [weak self] result in
            switch result {
            case .success(let userProfile):
                self?.user = userProfile
            case .failure(let error):
                self?.errorMessage = "Failed to load profile: \(error.localizedDescription)"
            }
        }
    }
    
    func updateUserProfile() {
        FirebaseService.shared.updateUserProfile(userProfile: user) { [weak self] error in
            if let error = error {
                self?.errorMessage = "Failed to save profile: \(error.localizedDescription)"
            } else {
                 self?.errorMessage = "Profile saved successfully!"
            }
        }
    }
    
    func addCondition() {
        guard !newCondition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        user.chronicConditions.append(newCondition)
        newCondition = ""
    }
}