//
//  HomeView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//  Revised 7/21/25 – Rebuilt to match modern web app dashboard layout.
//

import SwiftUI
import AVFoundation

// MARK: - Main Home View (Dashboard)
struct HomeView: View {
    @EnvironmentObject var visitViewModel: VisitViewModel
    @EnvironmentObject var statsViewModel: StatsViewModel
    @EnvironmentObject var audioRecorder: AudioRecorder
    @EnvironmentObject var medicationViewModel: MedicationViewModel
    @StateObject private var userViewModel = UserViewModel()
    @Binding var selectedTab: Int
    
    @State private var showingVisitPrep = false
    @State private var showingNewVisit = false
    @State private var showingVisitDetail = false
    @State private var showingHealthAssistant = false
    @State private var showingMedicationDetail = false
    @State private var selectedVisit: Visit?
    @State private var selectedMedication: Medication?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header with welcome message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hello, \(getUserFirstName())! 👋")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Let's capture your medical visit today")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)

                    // Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2), spacing: 20) {
                        DashboardStatCard(
                            title: "Total Visits",
                            value: "\(visitViewModel.totalVisits)",
                            icon: "calendar",
                            color: .blue,
                            gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        DashboardStatCard(
                            title: "Visits This Month",
                            value: "\(visitViewModel.visitsThisMonth)",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green,
                            gradient: LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        DashboardStatCard(
                            title: "Active Meds",
                            value: "\(statsViewModel.currentMedications.count)",
                            icon: "pills",
                            color: .orange,
                            gradient: LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        DashboardStatCard(
                            title: "Specialties",
                            value: "\(visitViewModel.specialties.count)",
                            icon: "stethoscope",
                            color: .purple,
                            gradient: LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }
                    .padding(.horizontal, 24)

                    // Quick Actions Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Quick Actions")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.leading, 4)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                            QuickActionCard(title: "Record Visit", icon: "mic.fill", color: .blue) { showingNewVisit = true }
                            QuickActionCard(title: "View History", icon: "clock.fill", color: .green) { selectedTab = 1 }
                            QuickActionCard(title: "Prepare for Visit", icon: "list.clipboard.fill", color: .purple) { showingVisitPrep = true }
                            QuickActionCard(title: "Medications", icon: "pills.fill", color: .orange) { selectedTab = 2 }
                            QuickActionCard(title: "Health Assistant", icon: "message.fill", color: .purple) { showingHealthAssistant = true }
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 8)

                    // Recent Visits Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Recent Visits")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Button("View All") { selectedTab = 1 }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        if visitViewModel.isLoading {
                            ProgressView()
                                .frame(height: 200)
                        } else if visitViewModel.recentVisits.isEmpty {
                            Text("No recent visits found.")
                                .foregroundColor(.secondary)
                                .frame(height: 100)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(visitViewModel.recentVisits) { visit in
                                    VisitItem(
                                        visit: visit,
                                        onTap: {
                                            selectedVisit = visit
                                            showingVisitDetail = true
                                        },
                                        onDelete: {
                                            Task { await visitViewModel.deleteVisit(visit) }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 8)
                }
                .padding(.vertical, 32)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewVisit = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingNewVisit) {
                // You will need to create this view next
                // NewVisitView()
                //     .environmentObject(visitViewModel)
                //     .environmentObject(audioRecorder)
            }
            .sheet(isPresented: $showingVisitPrep) {
                VisitPrepView(
                    visits: visitViewModel.visits,
                    medications: medicationViewModel.medications
                )
            }
            .sheet(isPresented: $showingVisitDetail) {
                if let visit = selectedVisit {
                    VisitDetailView(visit: visit)
                        .environmentObject(visitViewModel)
                }
            }
            .sheet(isPresented: $showingHealthAssistant) {
                HealthAssistantView()
            }
            .onAppear {
                Task {
                    await visitViewModel.loadVisitsAsync()
                    await statsViewModel.fetchStats()
                    await userViewModel.fetchUserProfile()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getUserFirstName() -> String {
        let firstName = userViewModel.user.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        return firstName.isEmpty ? "User" : firstName
    }
}

// MARK: - Dashboard Stat Card
struct DashboardStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let gradient: LinearGradient

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Medication Item (using the one from Components.swift)

// MARK: - Medication Confirmation View
struct MedicationConfirmationView: View {
    @Binding var medications: [Medication]
    @EnvironmentObject var visitViewModel: VisitViewModel
    var onConfirm: () -> Void
    
    private var detectedMedicationActions: [String] {
        guard let summary = visitViewModel.visitSummary else { return [] }
        
        var actions: [String] = []
        let transcript = visitViewModel.transcript.lowercased()
        let summaryText = summary.summary.lowercased()
        
        // Look for stop/discontinue patterns
        let stopPatterns = [
            "stop\\s+(?:the\\s+use\\s+of\\s+)?([a-zA-Z0-9\\-\\s]+)",
            "discontinue\\s+(?:the\\s+use\\s+of\\s+)?([a-zA-Z0-9\\-\\s]+)",
            "no\\s+longer\\s+(?:use\\s+|need\\s+)?([a-zA-Z0-9\\-\\s]+)",
            "cease\\s+(?:the\\s+use\\s+of\\s+)?([a-zA-Z0-9\\-\\s]+)"
        ]
        
        for pattern in stopPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let textsToCheck = [transcript, summaryText]
                
                for text in textsToCheck {
                    let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                    
                    for match in matches {
                        if let nameRange = Range(match.range(at: 1), in: text) {
                            let medicationName = String(text[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // Clean up the medication name
                            let cleanedName = medicationName
                                .replacingOccurrences(of: " drops?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " tablets?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " capsules?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " ointment", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " eye drops?", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " solution", with: "", options: .regularExpression)
                                .replacingOccurrences(of: " cream", with: "", options: .regularExpression)
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if !cleanedName.isEmpty && !actions.contains("Stop \(cleanedName)") {
                                actions.append("Stop \(cleanedName)")
                            }
                        }
                    }
                }
            } catch {
                print("❌ Error processing stop pattern: \(pattern) - \(error)")
            }
        }
        
        return actions
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review & Confirm Medications")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Medication Actions Section
            if !detectedMedicationActions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Medication Actions Detected")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(detectedMedicationActions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(detectedMedicationActions, id: \.self) { action in
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(action)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Text("These actions will be processed when you save the visit.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .background(Color.orange.opacity(0.05))
                .cornerRadius(12)
            }
            
            // New Medications Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("New Medications")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(medications.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                if medications.isEmpty {
                    Text("No new medications identified for this visit.")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(medications.indices, id: \.self) { idx in
                        MedicationEditItem(medication: $medications[idx])
                    }
                    Button(action: {
                        medications.append(Medication(name: "", dosage: "", frequency: ""))
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Add Medication")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 8)
                }
            }
            
            Button("Confirm & Continue") {
                onConfirm()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(8)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct MedicationEditItem: View {
    @Binding var medication: Medication
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Medication Name (full width)
            VStack(alignment: .leading, spacing: 4) {
                Text("Medication Name")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                TextField("Enter medication name", text: $medication.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
            
            // Dosage and Frequency (side by side)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Dosage")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    TextField("e.g., 10mg", text: $medication.dosage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Frequency")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    TextField("e.g., twice daily", text: $medication.frequency)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
            }
            
            // Timing and Route (side by side)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Timing")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    TextField("e.g., morning", text: Binding($medication.timing, replacingNilWith: ""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Route")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    TextField("e.g., oral", text: Binding($medication.route, replacingNilWith: ""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
            }
            
            // Laterality and Duration (side by side)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Eye/Side")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    TextField("e.g., left eye", text: Binding($medication.laterality, replacingNilWith: ""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    TextField("e.g., 1 week", text: Binding($medication.duration, replacingNilWith: ""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
            }
            
            // Start Date Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Start Date")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                DatePicker("Select start date", selection: Binding(
                    get: { medication.startDate ?? Date() },
                    set: { medication.startDate = $0 }
                ), displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
            }
            
            // Full Instructions (full width)
            VStack(alignment: .leading, spacing: 4) {
                Text("Full Instructions")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                TextField("Complete instructions for patient", text: Binding($medication.fullInstructions, replacingNilWith: ""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// Helper to convert an optional String binding into a non-optional String binding
extension Binding where Value == String {
    init(_ source: Binding<String?>, replacingNilWith defaultValue: String) {
        self.init(
            get: { source.wrappedValue ?? defaultValue },
            set: { source.wrappedValue = $0 }
        )
    }
}

// MARK: - New Visit View (Matching Web App)
struct NewVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var visitViewModel: VisitViewModel
    @EnvironmentObject var audioRecorder: AudioRecorder
    
    @State private var showingPermissionAlert = false
    @State private var showingSuccessAlert = false
    @State private var confirmingMedications = false
    @State private var editableMedications: [Medication] = []
    @State private var visitSaved = false
    @State private var savedVisit: Visit?
    @State private var showingVisitDetails = false
    
    var body: some View {
        NavigationView {
            if visitSaved {
                visitCompletionView
            } else {
                newVisitView
            }
        }
        .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to record your medical visits.")
        }
        .alert("Visit Saved!", isPresented: $showingSuccessAlert) {
            Button("Continue") {
                showingSuccessAlert = false
                visitSaved = true
            }
        } message: {
            Text("Your visit has been successfully recorded and saved.")
        }
        .sheet(isPresented: $showingVisitDetails) {
            if visitSaved, let mostRecentVisit = visitViewModel.visits.first {
                // Show saved visit details
                VisitDetailView(visit: mostRecentVisit)
                    .environmentObject(visitViewModel)
            } else if let summary = visitViewModel.visitSummary {
                // Show unsaved visit details from summary
                VisitDetailView(visit: createTempVisitFromSummary(summary))
                    .environmentObject(visitViewModel)
            }
        }
        .onChange(of: visitViewModel.showingSuccess) { _, success in
            if success {
                showingSuccessAlert = true
            }
        }
        .onAppear {
            // Reset state when view appears
            visitViewModel.resetRecording()
            audioRecorder.resetRecording()
            visitSaved = false
            savedVisit = nil
            showingVisitDetails = false
        }
    }
    
    private var visitCompletionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("Visit Completed!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your medical visit has been successfully recorded and saved.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Visit Summary Card
                if let summary = visitViewModel.visitSummary {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Visit Summary")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            if !summary.specialty.isEmpty {
                                HStack {
                                    Text("Specialty:")
                                        .fontWeight(.medium)
                                    Text(summary.specialty)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                            
                            if !summary.tldr.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Quick Summary:")
                                        .fontWeight(.medium)
                                    Text(summary.tldr)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if !summary.medications.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Medications (\(summary.medications.count)):")
                                        .fontWeight(.medium)
                                    ForEach(summary.medications.prefix(3)) { medication in
                                        HStack {
                                            Text("•")
                                            Text(medication.name)
                                            Spacer()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    }
                                    if summary.medications.count > 3 {
                                        Text("... and \(summary.medications.count - 3) more")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button("View Full Details") {
                        showingVisitDetails = true
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Record Another Visit") {
                        visitViewModel.resetRecording()
                        audioRecorder.resetRecording()
                        visitSaved = false
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(8)
                    
                    Button("Return to Home") {
                        visitViewModel.resetRecording()
                        audioRecorder.resetRecording()
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
        .navigationTitle("Visit Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    visitViewModel.resetRecording()
                    audioRecorder.resetRecording()
                    dismiss()
                }
            }
        }
    }
    
    private var newVisitView: some View {
        ScrollView {
            VStack(spacing: 24) {
                newVisitHeader
                newVisitRecordingControls
                
                if !visitViewModel.transcript.isEmpty {
                    newVisitTranscriptSection
                }
                
                if let summary = visitViewModel.visitSummary {
                    if confirmingMedications {
                        MedicationConfirmationView(medications: $editableMedications) {
                            // On confirm, update summary and proceed to save options
                            visitViewModel.visitSummary?.medications = editableMedications
                            confirmingMedications = false
                        }
                    } else {
                        newVisitSummarySection(summary: summary)
                        
                        // Action buttons after summary
                        VStack(spacing: 12) {
                            // Medication confirmation button (always show if there are medications or actions)
                            if !summary.medications.isEmpty || !summary.medicationActions.isEmpty {
                                Button("Review & Confirm Medications") {
                                    editableMedications = summary.medications
                                    confirmingMedications = true
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            
                            // Save visit button
                            Button("Save Visit") {
                                Task {
                                    await saveVisit()
                                }
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .cornerRadius(8)
                            .disabled(visitViewModel.isLoading)
                            
                            // View Full Details button
                            Button("View Full Details") {
                                showingVisitDetails = true
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                            
                            // Cancel/Return without saving
                            Button("Cancel & Return Home") {
                                visitViewModel.resetRecording()
                                audioRecorder.resetRecording()
                                dismiss()
                            }
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("New Visit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    visitViewModel.resetRecording()
                    dismiss()
                }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { visitViewModel.errorMessage != nil },
            set: { newValue in if (!newValue) { visitViewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(visitViewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    visitViewModel.resetRecording()
                }
            )
        }
    }
    
    // MARK: - Missing Functions
    private func createTempVisitFromSummary(_ summary: VisitSummary) -> Visit {
        return Visit(
            id: UUID().uuidString,
            date: Date(),
            specialty: summary.specialty,
            summary: summary.summary,
            medications: summary.medications,
            keyInsights: summary.keyInsights,
            actionItems: summary.actionItems,
            followUpDate: summary.followUpDate,
            transcript: visitViewModel.transcript
        )
    }
    
    private func saveVisit() {
        Task {
            await visitViewModel.saveVisit()
            visitSaved = true
            savedVisit = visitViewModel.currentVisit
        }
    }
    
    private var newVisitRecordingControls: some View {
        VStack(spacing: 16) {
            if audioRecorder.isRecording {
                Button(action: {
                    audioRecorder.stopRecording()
                    Task {
                        await visitViewModel.processRecording()
                    }
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                        Text("Stop Recording")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }
            } else {
                Button(action: {
                    Task {
                        let permission = await audioRecorder.requestPermission()
                        if permission {
                            audioRecorder.startRecording()
                        } else {
                            showingPermissionAlert = true
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "mic.fill")
                        Text("Start Recording")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var newVisitTranscriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.headline)
                .fontWeight(.semibold)
            
            ScrollView {
                Text(visitViewModel.transcript)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 200)
        }
    }
    
    private func newVisitSummarySection(summary: VisitSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Visit Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !summary.specialty.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Specialty")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(summary.specialty)
                        .font(.body)
                }
            }
            
            if !summary.summary.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summary")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(summary.summary)
                        .font(.body)
                }
            }
            
            if !summary.medications.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Medications")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    ForEach(summary.medications) { medication in
                        HStack {
                            Text(medication.name)
                            Spacer()
                            Text(medication.dosage)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private var newVisitHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Record New Visit")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Capture your medical visit with AI-powered assistance")
                .font(.caption)
                .foregroundColor(.secondary)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
