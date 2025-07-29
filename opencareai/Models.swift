import Foundation
import FirebaseFirestore

// MARK: - User Model (matching web app structure)
struct User: Codable, Identifiable {
    var id: String?
    var email: String
    var firstName: String
    var lastName: String
    var dob: String
    var gender: String
    var phoneNumber: String
    var street: String
    var city: String
    var state: String
    var zip: String
    var insuranceProvider: String
    var insuranceMemberId: String
    var allergies: [String]
    var chronicConditions: [String]
    var heightFeet: String
    var heightInches: String
    var weight: String
    var emergencyContactName: String
    var emergencyContactPhone: String
    var primaryPhysician: String
    var bloodType: String
    var createdAt: Date?
    var updatedAt: Date?
    
    // Custom initializer
    init(
        id: String? = nil,
        email: String = "",
        firstName: String = "",
        lastName: String = "",
        dob: String = "",
        gender: String = "",
        phoneNumber: String = "",
        street: String = "",
        city: String = "",
        state: String = "",
        zip: String = "",
        insuranceProvider: String = "",
        insuranceMemberId: String = "",
        allergies: [String] = [],
        chronicConditions: [String] = [],
        heightFeet: String = "",
        heightInches: String = "",
        weight: String = "",
        emergencyContactName: String = "",
        emergencyContactPhone: String = "",
        primaryPhysician: String = "",
        bloodType: String = "",
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.dob = dob
        self.gender = gender
        self.phoneNumber = phoneNumber
        self.street = street
        self.city = city
        self.state = state
        self.zip = zip
        self.insuranceProvider = insuranceProvider
        self.insuranceMemberId = insuranceMemberId
        self.allergies = allergies
        self.chronicConditions = chronicConditions
        self.heightFeet = heightFeet
        self.heightInches = heightInches
        self.weight = weight
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.primaryPhysician = primaryPhysician
        self.bloodType = bloodType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Visit Model (matching web app structure)
struct Visit: Codable, Identifiable {
    var id: String?
    var userId: String?
    var date: Date?
    var specialty: String?
    var summary: String?
    var tldr: String?
    var medications: [Medication]?
    var medicationActions: [MedicationAction]?
    var chronicConditions: [String]?
    var createdAt: Date?
    var updatedAt: Date?
}

// MARK: - Medication Model (matching web app structure)
struct Medication: Codable, Identifiable {
    var id: String?
    var userId: String?
    var name: String
    var dosage: String
    var frequency: String
    var timing: String?
    var route: String?
    var laterality: String?
    var duration: String?
    var instructions: String?
    var fullInstructions: String?
    var isActive: Bool?
    var startDate: Date?
    var discontinuationReason: String?
    var createdAt: Date?
    var updatedAt: Date?
    var discontinuedDate: Date?
}

// MARK: - Enhanced User Model
extension User {
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var fullAddress: String {
        "\(street), \(city), \(state) \(zip)"
    }
    
    var heightInCm: Double? {
        guard let feet = Double(heightFeet), let inches = Double(heightInches) else { return nil }
        return (feet * 12 + inches) * 2.54
    }
    
    var weightInKg: Double? {
        guard let weightStr = Double(weight) else { return nil }
        return weightStr * 0.453592 // Convert pounds to kg
    }
}

// MARK: - Enhanced Visit Model
extension Visit {
    var formattedDate: String {
        guard let date = date else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var medicationsCount: Int {
        medications?.count ?? 0
    }
    
    var medicationActionsCount: Int {
        medicationActions?.count ?? 0
    }
}

// MARK: - Enhanced Medication Model
extension Medication {
    var isCurrentlyActive: Bool {
        isActive ?? true
    }
    
    var formattedInstructions: String {
        var instructions = "\(dosage) \(name) \(frequency)"
        if let timing = timing, !timing.isEmpty {
            instructions += " \(timing)"
        }
        if let route = route, !route.isEmpty {
            instructions += " \(route)"
        }
        if let laterality = laterality, !laterality.isEmpty {
            instructions += " \(laterality)"
        }
        if let duration = duration, !duration.isEmpty {
            instructions += " for \(duration)"
        }
        return instructions
    }
    
    var displayName: String {
        name.capitalized
    }
    
    // MARK: - Date and Progress Tracking
    
    var effectiveStartDate: Date {
        return startDate ?? createdAt ?? Date()
    }
    
    var formattedStartDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: effectiveStartDate)
    }
    
    var formattedStopDate: String? {
        guard let discontinuedDate = discontinuedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: discontinuedDate)
    }
    
    var durationUsed: String {
        guard let endDate = discontinuedDate else {
            // Still active - calculate duration from start to now
            let days = Calendar.current.dateComponents([.day], from: effectiveStartDate, to: Date()).day ?? 0
            return "\(days) days (ongoing)"
        }
        
        // Discontinued - calculate actual duration used
        let days = Calendar.current.dateComponents([.day], from: effectiveStartDate, to: endDate).day ?? 0
        return "\(days) days"
    }
    
    var medicationStatus: String {
        if isCurrentlyActive {
            return "Active"
        } else {
            return discontinuationReason ?? "Discontinued"
        }
    }
    
    var statusColor: String {
        if isCurrentlyActive {
            return "green"
        } else {
            return "red"
        }
    }
    
    // MARK: - Smart Schedule Integration
    
    var hasSmartSchedule: Bool {
        guard let instructions = fullInstructions, !instructions.isEmpty else { return false }
        
        // Check for tapering patterns (matching web app logic)
        let taperingPatterns = [
            "then", "taper", "reduce", "decrease", "step", "wean", "gradually"
        ]
        
        return taperingPatterns.contains { instructions.localizedCaseInsensitiveContains($0) }
    }
    
    var medicationType: String {
        if hasSmartSchedule {
            return "tapering"
        }
        
        // Check for specific duration
        if let dur = duration, !dur.isEmpty, dur != "ongoing" {
            return "short-term"
        }
        
        return "chronic"
    }
    
    var progressPercentage: Int {
        guard medicationType != "chronic" else { return 0 }
        
        // For short-term medications, calculate progress based on duration
        guard let durationStr = duration, !durationStr.isEmpty else { return 0 }
        
        let totalDays = extractDurationInDays(from: durationStr)
        guard totalDays > 0 else { return 0 }
        
        let daysElapsed = Calendar.current.dateComponents([.day], from: effectiveStartDate, to: Date()).day ?? 0
        
        let progress = min(100, max(0, Int((Double(daysElapsed) / Double(totalDays)) * 100)))
        return progress
    }
    
    private func extractDurationInDays(from durationString: String) -> Int {
        let lowercased = durationString.lowercased()
        
        if lowercased.contains("week") {
            // Extract number of weeks
            let numbers = durationString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            if let weekStr = numbers.first(where: { !$0.isEmpty }), let weeks = Int(weekStr) {
                return weeks * 7
            }
        } else if lowercased.contains("day") {
            // Extract number of days
            let numbers = durationString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            if let dayStr = numbers.first(where: { !$0.isEmpty }), let days = Int(dayStr) {
                return days
            }
        }
        
        return 7 // Default to 7 days if can't parse
    }
}

// MARK: - Medication Action Model (matching web app structure)
struct MedicationAction: Codable, Identifiable {
    var id: String?
    var visitId: String? // Made optional to handle API responses that don't include visitId
    var medicationId: String?
    var action: MedicationActionType
    var medicationName: String
    var genericReference: String?
    var reason: String?
    var newInstructions: String?
    var createdAt: Date?
}

enum MedicationActionType: String, Codable, CaseIterable {
    case start = "start"
    case stop = "stop"
    case continued = "continue"
    case modify = "modify"
    
    var displayName: String {
        switch self {
        case .start: return "Started"
        case .stop: return "Stopped"
        case .continued: return "Continued"
        case .modify: return "Modified"
        }
    }
    
    var color: String {
        switch self {
        case .start: return "green"
        case .stop: return "red"
        case .continued: return "blue"
        case .modify: return "orange"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .start: return "plus.circle.fill"
        case .stop: return "minus.circle.fill"
        case .continued: return "arrow.clockwise.circle.fill"
        case .modify: return "pencil.circle.fill"
        }
    }
}

// MARK: - Health Assistant Message
struct HealthAssistantMessage: Codable, Identifiable {
    var id: String?
    var userId: String
    var message: String
    var response: String
    var timestamp: Date?
}

// MARK: - API Response Models
struct TranscriptionResponse: Codable {
    let success: Bool
    let transcript: String?
    let error: String?
}

// Using SummarizationResponseAPI to avoid conflict with SummarizationResponse in SummarizationResponse.swift
struct SummarizationResponseAPI: Codable {
    let success: Bool
    let summary: String?
    let specialty: String?
    let date: String?
    let tldr: String?
    let medications: [Medication]?
    let medicationActions: [MedicationAction]?
    let chronicConditions: [String]?
    let error: String?
}

struct VisitSummary: Codable {
    var summary: String
    var tldr: String
    var specialty: String
    var date: String
    var medications: [Medication]
    var medicationActions: [String] // Changed from [MedicationAction] to [String] to match API response
    var chronicConditions: [String]
}

struct HealthAssistantResponse: Codable {
    let success: Bool
    let answer: String?
    let medicationActions: [MedicationAction]?
    let error: String?
}

// MARK: - App State (matching web app functionality)
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var visits: [Visit] = []
    @Published var medications: [Medication] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedSpecialty: String = "All"
    @Published var selectedTimeframe: String = "All"
    // Add dark mode preference
    @Published var colorScheme: ColorSchemeOption = .system
    
    var activeMedications: [Medication] {
        medications.filter { $0.isCurrentlyActive }
    }
    
    var inactiveMedications: [Medication] {
        medications.filter { !$0.isCurrentlyActive }
    }
    
    var visitsBySpecialty: [String: [Visit]] {
        Dictionary(grouping: visits) { $0.specialty ?? "Unknown" }
    }
    
    var filteredVisits: [Visit] {
        var filtered = visits
        
        if selectedSpecialty != "All" {
            filtered = filtered.filter { $0.specialty == selectedSpecialty }
        }
        
        if selectedTimeframe != "All" {
            let calendar = Calendar.current
            let now = Date()
            
            switch selectedTimeframe {
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
    
    var totalVisits: Int {
        visits.count
    }
    
    var totalActiveMedications: Int {
        activeMedications.count
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
    
    var specialties: [String] {
        Array(Set(visits.compactMap { $0.specialty })).sorted()
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func setError(_ message: String) {
        errorMessage = message
    }
}

// Enum for color scheme preference
enum ColorSchemeOption: String, CaseIterable, Codable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - Emergency Contact
struct EmergencyContact: Codable {
    var name: String
    var relationship: String
    var phoneNumber: String
}

// MARK: - API Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case transcriptionFailed(String)
    case summarizationFailed(String)
    case assistantFailed(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        case .summarizationFailed(let message):
            return "Summarization failed: \(message)"
        case .assistantFailed(let message):
            return "Health assistant failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}