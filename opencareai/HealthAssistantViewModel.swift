//
//  HealthAssistantViewModel.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// ViewModels/HealthAssistantViewModel.swift
import Foundation
import Firebase
import Combine
import FirebaseAuth

class HealthAssistantViewModel: ObservableObject {
    @Published var messages: [HealthAssistantMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentMessage = ""
    @Published var isTyping = false
    
    private let apiService = APIService.shared
    private let firebaseService = OpenCareFirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load previous messages when initialized
        Task {
            await loadMessagesAsync()
        }
    }
    
    // MARK: - Load Messages
    @MainActor
    func loadMessagesAsync() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await firebaseService.getHealthAssistantMessages(userId: userId)
            self.messages = fetchedMessages
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Send Message
    @MainActor
    func sendMessage(_ message: String) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        isTyping = true
        
        // Create user message
        var userMessage = HealthAssistantMessage(
            id: UUID().uuidString,
            userId: userId,
            message: message,
            response: "",
            timestamp: Date()
        )
        
        // Add user message to the list
        messages.append(userMessage)
        
        do {
            // Get context from recent visits and medications
            let context = await buildContext()
            
            // Send to API
            let response = try await apiService.askHealthAssistant(question: message, context: context)
            
            guard let answer = response.answer else {
                throw APIError.assistantFailed("No response received")
            }
            
            // Update the message with the response
            userMessage.response = answer
            
            // Process medication actions if any
            if let medicationActions = response.medicationActions, !medicationActions.isEmpty {
                let actionResults = await processMedicationActions(medicationActions)
                if !actionResults.isEmpty {
                    successMessage = actionResults.joined(separator: "\n")
                }
            }
            
            // Save to Firebase
            try await firebaseService.saveHealthAssistantMessage(userMessage)
            
            // Update the message in the list
            if let index = messages.firstIndex(where: { $0.id == userMessage.id }) {
                messages[index] = userMessage
            }
            
        } catch {
            errorMessage = error.localizedDescription
            
            // Remove the message if it failed
            messages.removeAll { $0.id == userMessage.id }
        }
        
        isLoading = false
        isTyping = false
        currentMessage = ""
    }
    
    // MARK: - Build Context
    private func buildContext() async -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            return ""
        }
        
        var context = ""
        
        do {
            // Get recent visits
            let visits = try await firebaseService.getUserVisits(userId: userId)
            let recentVisits = Array(visits.prefix(3))
            
            if !recentVisits.isEmpty {
                context += "Recent Medical Visits:\n"
                for visit in recentVisits {
                    context += "- \(visit.specialty ?? "General"): \(visit.tldr ?? visit.summary ?? "No summary")\n"
                }
                context += "\n"
            }
            
            // Get active medications
            let medications = try await firebaseService.getUserMedications(userId: userId)
            
            if !medications.isEmpty {
                context += "Current Medications:\n"
                for medication in medications {
                    context += "- \(medication.name): \(medication.formattedInstructions)\n"
                }
                context += "\n"
            }
            
            // Get user profile for allergies and conditions
            let user = try await firebaseService.getUserData(userId: userId)
            
            if !user.allergies.isEmpty {
                context += "Allergies: \(user.allergies.joined(separator: ", "))\n"
            }
            
            if !user.chronicConditions.isEmpty {
                context += "Chronic Conditions: \(user.chronicConditions.joined(separator: ", "))\n"
            }
            
        } catch {
            // If context building fails, continue without it
            print("Failed to build context: \(error)")
        }
        
        return context
    }
    
    // MARK: - Clear Messages
    @MainActor
    func clearMessages() {
        messages.removeAll()
    }
    
    // MARK: - Delete Message
    @MainActor
    func deleteMessage(_ message: HealthAssistantMessage) async {
        guard let messageId = message.id else {
            errorMessage = "Message ID not found"
            return
        }
        
        do {
            try await firebaseService.deleteHealthAssistantMessage(messageId: messageId)
            messages.removeAll { $0.id == messageId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Get Message by ID
    func getMessageById(_ messageId: String) -> HealthAssistantMessage? {
        return messages.first { $0.id == messageId }
    }
    
    // MARK: - Search Messages
    func searchMessages(query: String) -> [HealthAssistantMessage] {
        guard !query.isEmpty else { return messages }
        
        return messages.filter { message in
            message.message.localizedCaseInsensitiveContains(query) ||
            message.response.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Process Medication Actions
    @MainActor
    private func processMedicationActions(_ actions: [MedicationAction]) async -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return []
        }
        
        var actionResults: [String] = []
        
        do {
            for action in actions {
                // Record the medication action
                try await firebaseService.recordMedicationAction(action)
                
                // Handle different action types
                switch action.action {
                case .stop:
                    // Discontinue medication
                    if let existingMed = await getMedicationByName(action.medicationName) {
                        try await firebaseService.discontinueMedication(medicationId: existingMed.id!, reason: action.reason)
                        actionResults.append("✅ Discontinued \(action.medicationName)")
                        print("🛑 [HEALTH ASSISTANT] Discontinued medication: \(action.medicationName) - Reason: \(action.reason ?? "User requested")")
                    } else {
                        actionResults.append("⚠️ Could not find medication to discontinue: \(action.medicationName)")
                        print("⚠️ [HEALTH ASSISTANT] Could not find medication to discontinue: \(action.medicationName)")
                    }
                    
                case .start:
                    // Create new medication if it doesn't exist
                    if let existingMed = await getMedicationByName(action.medicationName) {
                        // Medication already exists, update if needed
                        if let newInstructions = action.newInstructions {
                            var updatedMed = existingMed
                            updatedMed.fullInstructions = newInstructions
                            try await firebaseService.updateMedication(medicationId: existingMed.id!, updates: ["fullInstructions": newInstructions])
                            actionResults.append("✏️ Updated \(action.medicationName)")
                        }
                    } else {
                        // Create new medication
                        var newMedication = Medication(
                            id: nil,
                            userId: userId,
                            name: action.medicationName,
                            dosage: "As prescribed",
                            frequency: "As prescribed",
                            timing: nil,
                            route: nil,
                            laterality: nil,
                            duration: nil,
                            instructions: nil,
                            fullInstructions: action.newInstructions ?? "Take as prescribed",
                            isActive: true,
                            discontinuationReason: nil,
                            createdAt: nil,
                            updatedAt: nil,
                            discontinuedDate: nil
                        )
                        
                        try await firebaseService.createMedication(newMedication, userId: userId)
                        actionResults.append("🆕 Added new medication: \(action.medicationName)")
                        print("🆕 [HEALTH ASSISTANT] Created new medication: \(action.medicationName)")
                    }
                    
                case .modify:
                    // Update medication instructions
                    if let existingMed = await getMedicationByName(action.medicationName) {
                        var updatedMed = existingMed
                        updatedMed.fullInstructions = action.newInstructions ?? existingMed.fullInstructions
                        try await firebaseService.updateMedication(medicationId: existingMed.id!, updates: ["fullInstructions": action.newInstructions ?? existingMed.fullInstructions])
                        actionResults.append("✏️ Modified \(action.medicationName)")
                        print("✏️ [HEALTH ASSISTANT] Modified medication: \(action.medicationName)")
                    }
                    
                case .continued:
                    // No action needed for continued medications
                    break
                }
            }
        } catch {
            errorMessage = "Failed to process medication actions: \(error.localizedDescription)"
            print("❌ [HEALTH ASSISTANT] Error processing medication actions: \(error)")
        }
        
        return actionResults
    }
    
    // MARK: - Helper Methods
    private func getMedicationByName(_ name: String) async -> Medication? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        
        do {
            let medications = try await firebaseService.getUserMedications(userId: userId)
            print("🔍 [HEALTH ASSISTANT] Searching for medication: '\(name)' among \(medications.count) medications")
            print("🔍 [HEALTH ASSISTANT] Available medications: \(medications.map { $0.name })")
            
            // Try exact match first
            if let exactMatch = medications.first(where: { $0.name.lowercased() == name.lowercased() }) {
                print("✅ [HEALTH ASSISTANT] Found exact match: \(exactMatch.name)")
                return exactMatch
            }
            
            // Try partial match
            if let partialMatch = medications.first(where: { $0.name.lowercased().contains(name.lowercased()) || name.lowercased().contains($0.name.lowercased()) }) {
                print("✅ [HEALTH ASSISTANT] Found partial match: \(partialMatch.name) for '\(name)'")
                return partialMatch
            }
            
            // Try category matching for common medication types
            let searchName = name.lowercased()
            if searchName.contains("blood pressure") || searchName.contains("bp") || searchName.contains("hypertension") {
                if let bpMed = medications.first(where: { $0.name.lowercased().contains("lisinopril") || $0.name.lowercased().contains("amlodipine") || $0.name.lowercased().contains("metoprolol") }) {
                    print("✅ [HEALTH ASSISTANT] Found blood pressure medication: \(bpMed.name)")
                    return bpMed
                }
            }
            
            if searchName.contains("allergy") || searchName.contains("antihistamine") {
                if let allergyMed = medications.first(where: { $0.name.lowercased().contains("loratadine") || $0.name.lowercased().contains("cetirizine") || $0.name.lowercased().contains("fexofenadine") }) {
                    print("✅ [HEALTH ASSISTANT] Found allergy medication: \(allergyMed.name)")
                    return allergyMed
                }
            }
            
            print("❌ [HEALTH ASSISTANT] No match found for medication: '\(name)'")
            return nil
        } catch {
            print("❌ [HEALTH ASSISTANT] Error fetching medications: \(error)")
            return nil
        }
    }
    
    // MARK: - Clear Messages
    func clearError() {
        errorMessage = nil
    }
    
    func clearSuccessMessage() {
        successMessage = nil
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    func loadMessages() {
        Task {
            await loadMessagesAsync()
        }
    }
    
    func sendMessage(_ message: String) {
        Task {
            await sendMessage(message)
        }
    }
}

// MARK: - Firebase Service Extension for Health Assistant
extension OpenCareFirebaseService {
    func saveHealthAssistantMessage(_ message: HealthAssistantMessage) async throws {
        // Convert HealthAssistantMessage to dictionary manually
        var dict: [String: Any] = [
            "id": message.id ?? "",
            "userId": message.userId,
            "message": message.message,
            "response": message.response
        ]
        
        // Convert Date objects to Firestore Timestamps
        if let timestamp = message.timestamp {
            dict["timestamp"] = Timestamp(date: timestamp)
        }
        
        let db = OpenCareFirebaseService.shared.getFirestore()
        try await db.collection("health_assistant_messages").addDocument(data: dict)
    }
    
    func getHealthAssistantMessages(userId: String) async throws -> [HealthAssistantMessage] {
        let db = OpenCareFirebaseService.shared.getFirestore()
        let snapshot = try await db.collection("health_assistant_messages")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document in
            var data = document.data()
            
            // Convert Firestore Timestamps to ISO8601 strings
            if let timestamp = data["timestamp"] as? Timestamp {
                data["timestamp"] = ISO8601DateFormatter().string(from: timestamp.dateValue())
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            var message = try OpenCareFirebaseService.shared.getJSONDecoder().decode(HealthAssistantMessage.self, from: jsonData)
            message.id = document.documentID
            return message
        }
    }
    
        func deleteHealthAssistantMessage(messageId: String) async throws {
        let db = OpenCareFirebaseService.shared.getFirestore()
        try await db.collection("health_assistant_messages").document(messageId).delete()
    }
}
