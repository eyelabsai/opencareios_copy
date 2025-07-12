//
//  HomeView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//  Revised 7/12/25 – fixed dynamicMember/scheduler issues and restored full views.
//  Updated to match web app layout and functionality
//

import SwiftUI
import AVFoundation

// MARK: - Main Home View
struct HomeView: View {
    @StateObject private var visitViewModel = VisitViewModel()
    @StateObject private var audioRecorder = AudioRecorder()
    @StateObject private var statsViewModel = StatsViewModel()
    @EnvironmentObject var appState: AppState
    
    @State private var showingNewVisit = false
    @State private var showingVisitDetail = false
    @State private var selectedVisit: Visit?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with welcome message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Ready to record your next medical visit?")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    
                    // Stats Grid - matching web app layout
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                        DashboardStatCard(
                            title: "Total Visits",
                            value: "\(visitViewModel.totalVisits)",
                            icon: "calendar",
                            color: .blue,
                            gradient: LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        
                        DashboardStatCard(
                            title: "This Month",
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
                            value: "\(visitViewModel.visitsBySpecialty.keys.count)",
                            icon: "stethoscope",
                            color: .purple,
                            gradient: LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Main Dashboard Layout - 2:1 grid like web app
                    HStack(alignment: .top, spacing: 20) {
                        // Main Content Column (2/3 width)
                        VStack(spacing: 20) {
                            // Quick Actions
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Quick Actions")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                                    QuickActionCard(
                                        title: "Record Visit",
                                        icon: "mic.fill",
                                        color: .blue
                                    ) {
                                        showingNewVisit = true
                                    }
                                    
                                    QuickActionCard(
                                        title: "View History",
                                        icon: "clock.fill",
                                        color: .green
                                    ) {
                                        // This will be handled by the tab navigation
                                    }
                                    
                                    QuickActionCard(
                                        title: "Medications",
                                        icon: "pills.fill",
                                        color: .orange
                                    ) {
                                        // This will be handled by the tab navigation
                                    }
                                    
                                    QuickActionCard(
                                        title: "Health Assistant",
                                        icon: "message.fill",
                                        color: .purple
                                    ) {
                                        // This will be handled by the tab navigation
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            
                            // Recent Visits
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Recent Visits")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    Button("View All") {
                                        // This will be handled by the tab navigation
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                                
                                if visitViewModel.isLoading {
                                    LoadingView(message: "Loading visits...")
                                        .frame(height: 200)
                                } else if visitViewModel.recentVisits.isEmpty {
                                    EmptyStateView(
                                        icon: "calendar.badge.plus",
                                        title: "No visits yet",
                                        message: "Record your first medical visit to get started",
                                        actionTitle: "Record Visit",
                                        action: { showingNewVisit = true }
                                    )
                                    .frame(height: 200)
                                } else {
                                    LazyVStack(spacing: 12) {
                                        ForEach(visitViewModel.recentVisits) { visit in
                                            VisitItem(
                                                visit: visit,
                                                onTap: {
                                                    selectedVisit = visit
                                                    showingVisitDetail = true
                                                },
                                                onDelete: {
                                                    visitViewModel.deleteVisit(visit)
                                                }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        // Sidebar Column (1/3 width)
                        VStack(spacing: 20) {
                            // Active Medications
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Active Medications")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                if statsViewModel.currentMedications.isEmpty {
                                    EmptyStateView(
                                        icon: "pills",
                                        title: "No active medications",
                                        message: "Your active medications will appear here",
                                        actionTitle: "Add Medication",
                                        action: { /* Navigate to medication view */ }
                                    )
                                    .frame(height: 150)
                                } else {
                                    LazyVStack(spacing: 8) {
                                        ForEach(statsViewModel.currentMedications.prefix(5)) { medication in
                                            MedicationItem(
                                                medication: medication,
                                                onTap: { },
                                                onDelete: { }
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            
                            // Quick Stats
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Health Summary")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 12) {
                                    HealthSummaryItem(
                                        title: "Last Visit",
                                        value: visitViewModel.recentVisits.first?.formattedDate ?? "None",
                                        icon: "calendar"
                                    )
                                    
                                    HealthSummaryItem(
                                        title: "Next Reminder",
                                        value: "Today",
                                        icon: "bell"
                                    )
                                    
                                    HealthSummaryItem(
                                        title: "Health Score",
                                        value: "Good",
                                        icon: "heart.fill"
                                    )
                                }
                            }
                            .padding(20)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("OpenCare")
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
                NewVisitView()
                    .environmentObject(visitViewModel)
                    .environmentObject(audioRecorder)
            }
            .sheet(isPresented: $showingVisitDetail) {
                if let visit = selectedVisit {
                    VisitDetailView(visit: visit)
                        .environmentObject(visitViewModel)
                }
            }
            .onAppear {
                Task {
                    await visitViewModel.loadVisitsAsync()
                    await statsViewModel.fetchStats()
                }
            }
        }
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            HStack {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Health Summary Item
struct HealthSummaryItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Medication Item (using the one from Components.swift)

// MARK: - New Visit View (Matching Web App)
struct NewVisitView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var visitViewModel: VisitViewModel
    @EnvironmentObject var audioRecorder: AudioRecorder
    
    @State private var showingPermissionAlert = false
    @State private var showingSuccessAlert = false
    
    var body: some View {
        NavigationView {
            newVisitView
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
                Button("OK") {
                    visitViewModel.resetRecording()
                    audioRecorder.resetRecording()
                    dismiss()
                }
            } message: {
                Text("Your visit has been successfully recorded and saved.")
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
                    newVisitSummarySection(summary: summary)
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
            set: { newValue in if !newValue { visitViewModel.errorMessage = nil } }
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
    
    private var newVisitHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Record New Visit")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Record your medical visit and get AI-powered insights")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var newVisitRecordingControls: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recording")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Recording Controls
            HStack(spacing: 12) {
                Button(action: {
                    if visitViewModel.currentStep == .ready {
                        Task {
                            await startRecording()
                        }
                    } else if visitViewModel.currentStep == .recording {
                        Task {
                            await stopRecording()
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: visitViewModel.currentStep == .recording ? "stop.fill" : "mic.fill")
                        Text(visitViewModel.currentStep == .recording ? "Stop Recording" : "Start Recording")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(visitViewModel.currentStep == .recording ? Color.red : Color.blue)
                    .cornerRadius(8)
                }
                .disabled(visitViewModel.isLoading)
                
                if visitViewModel.currentStep == .recording {
                    // Recording Timer
                    Text(audioRecorder.formatTime(audioRecorder.recordingTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            
            // Status Display
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(statusColor)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(statusColor.opacity(0.1))
            .cornerRadius(8)
            
            // Progress Bar (when processing)
            if visitViewModel.isLoading {
                ProgressView(value: visitViewModel.progressValue)
                    .progressViewStyle(LinearProgressViewStyle())
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var newVisitTranscriptSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transcription")
                .font(.title2)
                .fontWeight(.semibold)
            
            ScrollView {
                Text(visitViewModel.transcript)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
            .frame(maxHeight: 200)
            
            Button("Generate Summary") {
                Task {
                    await generateSummary()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(8)
            .disabled(visitViewModel.transcript.isEmpty || visitViewModel.isLoading)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func newVisitSummarySection(summary: VisitSummary) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Visit Summary")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Summary Grid (2 columns like web app)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    ScrollView {
                        Text(summary.summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
                
                // TLDR
                VStack(alignment: .leading, spacing: 8) {
                    Text("TL;DR")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    ScrollView {
                        Text(summary.tldr)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 150)
                }
            }
            
            // Specialty and Date
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Specialty")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(summary.specialty)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(summary.date)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
            }
            
            // Save Visit Button
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
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties for New Visit View
    private var statusIcon: String {
        switch visitViewModel.currentStep {
        case .ready:
            return "mic"
        case .recording:
            return "record.circle"
        case .processing:
            return "clock"
        case .reviewing:
            return "checkmark.circle"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch visitViewModel.currentStep {
        case .ready:
            return .secondary
        case .recording:
            return .red
        case .processing:
            return .orange
        case .reviewing:
            return .blue
        case .completed:
            return .green
        }
    }
    
    private var statusMessage: String {
        switch visitViewModel.currentStep {
        case .ready:
            return "Ready to record your medical visit"
        case .recording:
            return "Recording in progress... \(audioRecorder.formatTime(audioRecorder.recordingTime))"
        case .processing:
            return "Processing audio and generating transcript..."
        case .reviewing:
            return "Review your visit summary"
        case .completed:
            return "Visit completed successfully!"
        }
    }
    
    // MARK: - Recording Methods
    private func startRecording() async {
        await audioRecorder.startRecording()
        await MainActor.run {
            visitViewModel.currentStep = .recording
        }
    }
    
    private func stopRecording() async {
        guard let audioData = audioRecorder.stopRecording() else {
            await MainActor.run {
                visitViewModel.errorMessage = "Failed to get recording data"
            }
            return
        }
        
        await MainActor.run {
            visitViewModel.currentStep = .processing
        }
        
        await visitViewModel.processAudioRecording(audioData)
    }
    
    // MARK: - Summary Methods
    private func generateSummary() async {
        guard !visitViewModel.transcript.isEmpty else { return }
        
        await MainActor.run {
            visitViewModel.isLoading = true
            visitViewModel.progressValue = 0.0
        }
        
        do {
            // Step 1: Generate summary using the VisitViewModel's method
            await MainActor.run {
                visitViewModel.progressValue = 0.3
            }
            await visitViewModel.generateSummaryFromTranscript()
            
            // Step 2: Update progress
            await MainActor.run {
                visitViewModel.progressValue = 1.0
                visitViewModel.currentStep = .reviewing
            }
            
        } catch {
            await MainActor.run {
                visitViewModel.errorMessage = "Failed to generate summary: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            visitViewModel.isLoading = false
        }
    }
    
    private func saveVisit() async {
        guard let summary = visitViewModel.visitSummary else { return }
        
        await MainActor.run {
            visitViewModel.isLoading = true
        }
        
        do {
            // Use the VisitViewModel's save method
            await visitViewModel.saveCurrentVisit()
            await MainActor.run {
                visitViewModel.showingSuccess = true
            }
            
        } catch {
            await MainActor.run {
                visitViewModel.errorMessage = "Failed to save visit: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            visitViewModel.isLoading = false
        }
    }
}

// MARK: - Small Reusable Card & Rows
struct HomeStatCard: View {
    let title: String, value: String, icon: String, color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2).foregroundColor(color)
            Text(value).font(.title2).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct VisitRowView: View {
    let visit: Visit
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(visit.specialty ?? "")
                .font(.subheadline).fontWeight(.semibold)
            Text(formatDate(visit.date ?? Date()))
                .font(.caption).foregroundColor(.secondary)
            if !(visit.tldr ?? "").isEmpty {
                Text(visit.tldr ?? "")
                    .font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    private func formatDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: d)
    }
}

struct MedicationHistoryRowView: View {
    let medication: Medication
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medication.name)
                .font(.subheadline).fontWeight(.semibold).foregroundColor(.secondary)
            Text("Discontinued")
                .font(.caption).foregroundColor(.red)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Color.red.opacity(0.1)).cornerRadius(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SpecialtyPickerView: View {
    @Binding var selectedSpecialty: String
    let specialties: [String]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            List(specialties, id: \.self) { spec in
                Button {
                    selectedSpecialty = spec; dismiss()
                } label: {
                    HStack {
                        Text(spec)
                        Spacer()
                        if selectedSpecialty == spec {
                            Image(systemName: "checkmark").foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Specialty")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") { dismiss() }
            } }
        }
    }
}

// MARK: - Medication Scheduler helper
private struct _SchedulerHolder { static let shared = MedicationScheduler() }
extension MedicationViewModel {
    /// Shared scheduler instance the UI can use safely.
    var scheduler: MedicationScheduler { _SchedulerHolder.shared }
}
