// ViewModels/AuthViewModel.swift
import Foundation
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var errorMessage: String?

    init() {
        userSession = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
        }
    }

    func signIn(withEmail email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
            } else {
                self?.errorMessage = nil
            }
        }
    }

    func createUser(withEmail email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            
            guard let user = result?.user else {
                self?.errorMessage = "Failed to get user data after creation."
                return
            }
            
            // Create a profile for the new user in Firestore
            var newUser = User(email: email, name: "", chronicConditions: [])
            newUser.id = user.uid // Assign the id after initialization
            
            FirebaseService.shared.updateUserProfile(userProfile: newUser) { error in
                if let error = error {
                    // If creating the profile fails, show the error
                    self?.errorMessage = "Failed to create user profile: \(error.localizedDescription)"
                    // Optional: You might want to delete the created auth user here
                    // user.delete { _ in }
                } else {
                    // This part is successful, so no error message.
                    // The state change will automatically dismiss the auth view.
                    self?.errorMessage = nil
                }
            }
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
