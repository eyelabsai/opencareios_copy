// ViewModels/VisitViewModel.swift
import Foundation
import Firebase
import FirebaseAuth
import Combine

class VisitViewModel: ObservableObject {
    @Published var currentStep: RecordingStep = .ready
    @Published var progressValue: Double = 0.0
    @Published var visitSummary: VisitSummary?
    @Published var showingSuccess = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var transcript: String = "" // Add transcript property to match web app
    @Published var visits: [Visit] = [] // Add visits property back
    @Published var medicationViewModel = MedicationViewModel() // Add this property

    
    private let apiService = APIService.shared
    private let firebaseService = OpenCareFirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum RecordingStep {
        case ready
        case recording
        case processing
        case reviewing
        case completed
    }
    
    // Computed properties matching web app functionality
    var totalVisits: Int {
        visits.count
    }
    
    var recentVisits: [Visit] {
        Array(visits.prefix(5))
    }
    
    var visitsThisMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return visits.filter { visit in
            guard let visitDate = visit.date else { return false }
            return visitDate >= startOfMonth
        }.count
    }
    
    var visitsBySpecialty: [String: [Visit]] {
        Dictionary(grouping: visits) { $0.specialty ?? "Unknown" }
    }
    
    var specialties: [String] {
        Array(Set(visits.compactMap { $0.specialty })).sorted()
    }
    
    init() {
        // Load visits when initialized
        Task {
            await loadVisitsAsync()
        }
    }
    
    // MARK: - Load Visits
    @MainActor
    func loadVisitsAsync() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedVisits = try await firebaseService.getUserVisits(userId: userId)
            self.visits = fetchedVisits
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Create Visit
    @MainActor
    func createVisit(_ visit: Visit) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.createVisit(visit, userId: userId)
            // Add all medications from the visit to the user's global medications collection
            if let meds = visit.medications {
                for med in meds {
                    await medicationViewModel.createMedication(med)
                }
            }
            await loadVisitsAsync() // Reload visits after creation
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Process Visit with Audio
    @MainActor
    func processVisitWithAudio(audioData: Data, filename: String) async -> Visit? {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Process audio through API
            let visitSummary = try await apiService.processVisit(audioData: audioData, filename: filename)
            
            // Convert VisitSummary to Visit
            var newVisit = Visit()
            newVisit.userId = userId
            newVisit.summary = visitSummary.summary
            newVisit.tldr = visitSummary.tldr
            newVisit.specialty = visitSummary.specialty
            newVisit.medications = visitSummary.medications
            // Convert medication action strings to MedicationAction objects
            let medicationActions = visitSummary.medicationActions.compactMap { actionString -> MedicationAction? in
                guard let actionType = MedicationActionType(rawValue: actionString) else { return nil }
                return MedicationAction(
                    id: UUID().uuidString,
                    visitId: "", // Will be set by Firebase
                    medicationId: nil,
                    action: actionType,
                    medicationName: "Unknown", // Default value
                    genericReference: nil,
                    reason: nil,
                    newInstructions: nil,
                    createdAt: Date()
                )
            }
            newVisit.medicationActions = medicationActions
            newVisit.chronicConditions = visitSummary.chronicConditions
            
            // Parse date
            if visitSummary.date == "TODAY" {
                newVisit.date = Date()
            } else {
                // Try to parse the date string
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                newVisit.date = formatter.date(from: visitSummary.date) ?? Date()
            }
            
            // Save to Firebase
            try await firebaseService.createVisit(newVisit, userId: userId)
            
            // Add all medications from the visit to the user's global medications collection
            if let meds = newVisit.medications {
                for med in meds {
                    await medicationViewModel.createMedication(med)
                }
            }
            
            // Reload visits
            await loadVisitsAsync()
            
            return newVisit
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
        
        isLoading = false
    }
    
    // MARK: - Update Visit
    @MainActor
    func updateVisit(_ visit: Visit) async {
        guard let visitId = visit.id else {
            errorMessage = "Visit ID not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Convert Visit to dictionary for update
            var updates: [String: Any] = [:]
            
            if let specialty = visit.specialty {
                updates["specialty"] = specialty
            }
            if let summary = visit.summary {
                updates["summary"] = summary
            }
            if let tldr = visit.tldr {
                updates["tldr"] = tldr
            }
            if let date = visit.date {
                updates["date"] = Timestamp(date: date)
            }
            if let medications = visit.medications {
                updates["medications"] = medications
            }
            if let medicationActions = visit.medicationActions {
                updates["medicationActions"] = medicationActions
            }
            if let chronicConditions = visit.chronicConditions {
                updates["chronicConditions"] = chronicConditions
            }
            
            try await firebaseService.updateVisit(visitId: visitId, updates: updates)
            await loadVisitsAsync() // Reload visits after update
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Delete Visit
    @MainActor
    func deleteVisit(_ visit: Visit) async {
        guard let visitId = visit.id else {
            errorMessage = "Visit ID not found"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await firebaseService.deleteVisit(visitId)
            
            // Remove from local array
            visits.removeAll { $0.id == visitId }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Get Visit by ID
    func getVisitById(_ visitId: String) async -> Visit? {
        do {
            return try await firebaseService.getVisitById(visitId: visitId)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
    // MARK: - Filter Visits
    func filterVisits(specialty: String? = nil, timeframe: String? = nil) -> [Visit] {
        var filtered = visits
        
        if let specialty = specialty, specialty != "All" {
            filtered = filtered.filter { $0.specialty == specialty }
        }
        
        if let timeframe = timeframe, timeframe != "All" {
            let calendar = Calendar.current
            let now = Date()
            
            switch timeframe {
            case "This Week":
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                filtered = filtered.filter { visit in
                    guard let visitDate = visit.date else { return false }
                    return visitDate >= startOfWeek
                }
            case "This Month":
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                filtered = filtered.filter { visit in
                    guard let visitDate = visit.date else { return false }
                    return visitDate >= startOfMonth
                }
            case "This Year":
                let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
                filtered = filtered.filter { visit in
                    guard let visitDate = visit.date else { return false }
                    return visitDate >= startOfYear
                }
            default:
                break
            }
        }
        
        return filtered
    }
    
    // MARK: - Clear Error
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Summary Generation
    @MainActor
    func generateSummaryFromTranscript() async {
        guard !transcript.isEmpty else { return }
        
        do {
            // Use enhanced summarization with verification (matching web app functionality)
            let (summaryResponse, medications, actions) = try await apiService.summarizeTranscriptWithVerification(transcript)
            
            // Convert MedicationAction array to [String] of action raw values
            let medicationActionStrings: [String] = actions.map { $0.action.rawValue }
            
            let visitSummary = VisitSummary(
                summary: summaryResponse.summary ?? "",
                tldr: summaryResponse.tldr ?? "",
                specialty: summaryResponse.specialty ?? "",
                date: summaryResponse.date ?? "",
                medications: medications,
                medicationActions: medicationActionStrings,
                chronicConditions: summaryResponse.chronicConditions ?? []
            )
            
            self.visitSummary = visitSummary
            
        } catch {
            errorMessage = "Failed to generate summary: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Save Visit
    @MainActor
    func saveCurrentVisit() async {
        guard let summary = visitSummary else { return }
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        do {
            let visit = Visit(
                userId: userId,
                date: Date(),
                specialty: summary.specialty,
                summary: summary.summary,
                tldr: summary.tldr,
                medications: summary.medications,
                medicationActions: nil, // Not available from summary
                chronicConditions: summary.chronicConditions,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await firebaseService.createVisit(visit, userId: userId)
            
        } catch {
            errorMessage = "Failed to save visit: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Legacy Methods (for backward compatibility)
    func loadVisits() {
        Task {
            await loadVisitsAsync()
        }
    }
    
    func saveVisit(_ visit: Visit) {
        Task {
            await createVisit(visit)
        }
    }
    
    func deleteVisit(_ visit: Visit) {
        Task {
            await deleteVisit(visit)
        }
    }
    
    // MARK: - Process Audio Recording (without auto-saving)
    @MainActor
    func processAudioRecording(_ audioData: Data) async {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        print("🔊 Starting audio processing...")
        print("🔊 Audio data size: \(audioData.count) bytes")
        
        isLoading = true
        errorMessage = nil
        progressValue = 0.0
        
        do {
            // Step 1: Transcribe audio
            print("🔊 Step 1: Transcribing audio...")
            progressValue = 0.3
            let transcriptionResponse = try await apiService.transcribeAudio(audioData: audioData, filename: "recording.m4a")
            
            print("🔊 Transcription response: \(transcriptionResponse)")
            
            guard let transcriptText = transcriptionResponse.transcript else {
                errorMessage = "No transcript received"
                isLoading = false
                return
            }
            
            print("🔊 Transcript received: \(transcriptText)")
            transcript = transcriptText
            progressValue = 0.6
            
            // Step 2: Summarize transcript
            print("🔊 Step 2: Summarizing transcript...")
            let (summarizationResponse, medications, actions) = try await apiService.summarizeTranscriptWithVerification(transcriptText)
            progressValue = 0.9
            
            print("🔊 Summarization response received: \(summarizationResponse)")
            
            // Step 3: Create VisitSummary (DO NOT SAVE YET)
            let medicationActionStrings = actions.map { $0.action.rawValue }
            
            self.visitSummary = VisitSummary(
                summary: summarizationResponse.summary ?? "",
                tldr: summarizationResponse.tldr ?? "",
                specialty: summarizationResponse.specialty ?? "General",
                date: summarizationResponse.date ?? "TODAY",
                medications: summarizationResponse.medications ?? [],
                medicationActions: medicationActionStrings,
                chronicConditions: summarizationResponse.chronicConditions ?? []
            )
            
            print("🔊 Visit summary created: \(self.visitSummary?.summary ?? "No summary")")
            
            progressValue = 1.0
            currentStep = .reviewing
            
        } catch {
            print("❌ Error during audio processing: \(error)")
            errorMessage = error.localizedDescription
            currentStep = .ready
        }
        
        isLoading = false
    }
    
    // MARK: - Save Visit (explicit save action)
    @MainActor
    func saveVisitFromSummary() async {
        guard let summary = visitSummary else {
            errorMessage = "No visit summary to save"
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        
        do {
            print("🔊 Saving visit to Firebase...")
            
            // Convert medication action strings back to MedicationAction objects
            let medicationActions = summary.medicationActions.compactMap { actionString -> MedicationAction? in
                guard let actionType = MedicationActionType(rawValue: actionString) else { return nil }
                // We need to extract the medication name from the action string
                // Since we only have action types as strings, we'll need to reconstruct from medications
                return nil // We'll handle this differently
            }
            
            let visit = Visit(
                userId: userId,
                date: Date(),
                specialty: summary.specialty,
                summary: summary.summary,
                tldr: summary.tldr,
                medications: summary.medications,
                medicationActions: medicationActions,
                chronicConditions: summary.chronicConditions,
                createdAt: Date(),
                updatedAt: Date()
            )
            

            
            // Save visit first
            try await firebaseService.createVisit(visit, userId: userId)
            print("🔊 Visit saved successfully")
            
            // Process medication actions from the visit summary/transcript
            await processMedicationActionsFromSummary(summary)
            
            // Add new medications to global collection (only the ones that aren't stopped)
            print("🔊 Adding new medications to global collection...")
            for med in summary.medications {
                // Only add if it's marked as active (not stopped during the visit)
                if med.isActive ?? true {
                    await medicationViewModel.createMedication(med)
                } else {
                    print("🛑 Skipping discontinued medication: \(med.name)")
                }
            }
            
            // Reload visits and medications
            await loadVisitsAsync()
            await medicationViewModel.loadMedicationsAsync()
            
            currentStep = .completed
            showingSuccess = true
            
        } catch {
            print("❌ Error saving visit: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    

    
    // MARK: - Process Medication Actions from Summary
    @MainActor
    private func processMedicationActionsFromSummary(_ summary: VisitSummary) async {
        print("🔊 Processing medication actions from visit summary...")
        
        // Check if the summary or transcript contains stop/discontinue instructions
        let transcript = self.transcript.lowercased()
        let summaryText = summary.summary.lowercased()
        
        // Look for stop/discontinue patterns in the text
        let stopPatterns = [
            "stop\\s+(?:the\\s+use\\s+of\\s+)?([a-zA-Z0-9\\-\\s]+)",
            "discontinue\\s+(?:the\\s+use\\s+of\\s+)?([a-zA-Z0-9\\-\\s]+)",
            "no\\s+longer\\s+(?:use\\s+|need\\s+)?([a-zA-Z0-9\\-\\s]+)",
            "cease\\s+(?:the\\s+use\\s+of\\s+)?([a-zA-Z0-9\\-\\s]+)"
        ]
        
        for pattern in stopPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                
                // Check both transcript and summary
                let textsToCheck = [transcript, summaryText]
                
                for text in textsToCheck {
                    let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                    
                    for match in matches {
                        if let nameRange = Range(match.range(at: 1), in: text) {
                            let medicationName = String(text[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // Clean up the medication name (remove common suffixes)
                            let cleanedName = medicationName
                                .replacingOccurrences(of: " drops?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " tablets?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " capsules?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " ointment", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " eye drops?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " solution", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " cream", with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            print("🔍 Found stop instruction for medication: '\(cleanedName)'")
                            
                            // Try to find and discontinue the medication
                            await discontinueMedicationByName(cleanedName, reason: "Discontinued per doctor's instructions during visit")
                        }
                    }
                }
            } catch {
                print("❌ Error processing stop pattern: \(pattern) - \(error)")
            }
        }
    }
    
    // MARK: - Discontinue Medication by Name
    @MainActor
    private func discontinueMedicationByName(_ medicationName: String, reason: String) async {
        print("🔍 Attempting to discontinue medication: '\(medicationName)'")
        
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ User not authenticated")
            return
        }
        
        do {
            // Get all user medications (including active ones)
            let medications = try await firebaseService.getUserMedications(userId: userId)
            print("🔍 Searching among \(medications.count) medications: \(medications.map { $0.name })")
            
            // Try exact match first
            if let exactMatch = medications.first(where: { $0.name.lowercased() == medicationName.lowercased() }) {
                print("✅ Found exact match: \(exactMatch.name)")
                try await firebaseService.discontinueMedication(medicationId: exactMatch.id!, reason: reason)
                print("🛑 Successfully discontinued: \(exactMatch.name)")
                return
            }
            
            // Try partial match
            if let partialMatch = medications.first(where: { 
                $0.name.lowercased().contains(medicationName.lowercased()) || 
                medicationName.lowercased().contains($0.name.lowercased()) 
            }) {
                print("✅ Found partial match: \(partialMatch.name) for '\(medicationName)'")
                try await firebaseService.discontinueMedication(medicationId: partialMatch.id!, reason: reason)
                print("🛑 Successfully discontinued: \(partialMatch.name)")
                return
            }
            
            // Try category matching for common medication types
            let searchName = medicationName.lowercased()
            if searchName.contains("latanoprost") {
                if let latanoprostMed = medications.first(where: { $0.name.lowercased().contains("latanoprost") }) {
                    print("✅ Found latanoprost medication: \(latanoprostMed.name)")
                    try await firebaseService.discontinueMedication(medicationId: latanoprostMed.id!, reason: reason)
                    print("🛑 Successfully discontinued: \(latanoprostMed.name)")
                    return
                }
            }
            
            print("❌ No matching medication found for: '\(medicationName)'")
            
        } catch {
            print("❌ Error discontinuing medication '\(medicationName)': \(error)")
                 }
     }
     
     
     
     func resetRecording() {
        progressValue = 0.0
        currentStep = .ready
        visitSummary = nil
        transcript = "" // Reset transcript
        showingSuccess = false
        errorMessage = nil
        isLoading = false
    }
}
