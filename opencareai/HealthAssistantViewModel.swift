//
//  HealthAssistantViewModel.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// ViewModels/HealthAssistantViewModel.swift
import Foundation
import FirebaseAuth

@MainActor
class HealthAssistantViewModel: ObservableObject {
    @Published var messages: [String] = []
    @Published var errorMessage: String?
    
    private let apiService = APIService()
    private var userId: String? { Auth.auth().currentUser?.uid }

    func sendMessage(_ message: String) {
        guard let userId = userId, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        messages.append("You: \(message)")
        
        Task {
            do {
                let response = try await apiService.sendHealthAssistantQuery(query: message, userId: userId)
                messages.append("Assistant: \(response)")
            } catch {
                errorMessage = "Failed to get response from assistant: \(error.localizedDescription)"
                messages.append("Assistant: Sorry, I couldn't get a response. Please try again.")
            }
        }
    }
}