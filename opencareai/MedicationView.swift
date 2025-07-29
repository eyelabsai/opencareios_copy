//
//  MedicationView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//  Revised 7/12/25 – added explicit `medication:` argument labels.
//

import SwiftUI

// MARK: - Medication List
struct MedicationView: View {
    @EnvironmentObject var medicationViewModel: MedicationViewModel
    @StateObject private var scheduler = MedicationScheduler()
    
    @State private var searchText          = ""
    @State private var showingActiveOnly   = true
    @State private var selectedMedication: Medication?
    @State private var showingDetailSheet  = false
    
    private var displayedMedications: [Medication] {
        let filtered = medicationViewModel.filteredMedications
        let searchFiltered = searchText.isEmpty ? filtered : filtered.filter { medication in
            medication.name.localizedCaseInsensitiveContains(searchText) ||
            medication.dosage.localizedCaseInsensitiveContains(searchText) ||
            medication.frequency.localizedCaseInsensitiveContains(searchText)
        }
        
        // Apply "Active Only" filter if enabled
        if showingActiveOnly {
            return searchFiltered.filter { $0.isActive ?? true }
        }
        
        return searchFiltered
    }
    
    private var activeMedications: [Medication] {
        displayedMedications.filter { $0.isActive ?? true }
    }
    
    private var discontinuedMedications: [Medication] {
        displayedMedications.filter { !($0.isActive ?? true) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ───── Search / filter bar ─────
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Search medications…", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Button {
                            showingActiveOnly.toggle()
                            medicationViewModel.filterType = showingActiveOnly ? .active : .all
                        } label: {
                            HStack {
                                Image(systemName: showingActiveOnly ? "checkmark.circle.fill" : "circle")
                                Text("Active Only")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(showingActiveOnly ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                            .cornerRadius(16)
                        }
                        Spacer()
                        if showingActiveOnly {
                            Text("\(activeMedications.count) active")
                                .font(.caption).foregroundColor(.secondary)
                        } else {
                            Text("\(displayedMedications.count) total")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // ───── List ─────
                if medicationViewModel.isLoading {
                    Spacer(); ProgressView("Loading medications…"); Spacer()
                } else if displayedMedications.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "pills").font(.system(size: 60)).foregroundColor(.gray)
                        Text("No medications found").font(.title2).fontWeight(.semibold)
                        Text("Your medications will appear here after recording visits")
                            .font(.body).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding()
                    Spacer()
                } else {
                    List {
                        if showingActiveOnly {
                            // Show only active medications when filter is on
                            if !activeMedications.isEmpty {
                                Section {
                                    ForEach(activeMedications) { med in
                                        MedicationRowView(medication: med, scheduler: scheduler)
                                            .onTapGesture {
                                                print("[DEBUG] Medication tapped: \(med)")
                                                selectedMedication = med
                                                showingDetailSheet = true
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button("Discontinue", role: .destructive) {
                                                    Task {
                                                        await medicationViewModel.discontinueMedication(med)
                                                    }
                                                }
                                                Button("Delete", role: .destructive) {
                                                    Task {
                                                        await medicationViewModel.deleteMedication(med)
                                                    }
                                                }
                                            }
                                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                    }
                                } header: {
                                    HStack {
                                        Text("Active Medications")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(activeMedications.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                        } else {
                            // Show both active and discontinued when filter is off
                            if !activeMedications.isEmpty {
                                Section {
                                    ForEach(activeMedications) { med in
                                        MedicationRowView(medication: med, scheduler: scheduler)
                                            .onTapGesture {
                                                print("[DEBUG] Medication tapped: \(med)")
                                                selectedMedication = med
                                                showingDetailSheet = true
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button("Discontinue", role: .destructive) {
                                                    Task {
                                                        await medicationViewModel.discontinueMedication(med)
                                                    }
                                                }
                                                Button("Delete", role: .destructive) {
                                                    Task {
                                                        await medicationViewModel.deleteMedication(med)
                                                    }
                                                }
                                            }
                                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                    }
                                } header: {
                                    HStack {
                                        Text("Active Medications")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("\(activeMedications.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                            
                            if !discontinuedMedications.isEmpty {
                                Section {
                                    ForEach(discontinuedMedications) { med in
                                        MedicationRowView(medication: med, scheduler: scheduler)
                                            .onTapGesture {
                                                print("[DEBUG] Medication tapped: \(med)")
                                                selectedMedication = med
                                                showingDetailSheet = true
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button("Reactivate") {
                                                    Task {
                                                        await medicationViewModel.reactivateMedication(med)
                                                    }
                                                }
                                                .tint(.green)
                                                Button("Delete", role: .destructive) {
                                                    Task {
                                                        await medicationViewModel.deleteMedication(med)
                                                    }
                                                }
                                            }
                                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                            .listRowSeparator(.hidden)
                                            .listRowBackground(Color.clear)
                                    }
                                } header: {
                                    HStack {
                                        Text("Discontinued Medications")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        Text("\(discontinuedMedications.count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Medications")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { 
                Task {
                    await medicationViewModel.loadMedicationsAsync()
                }
            }
            .refreshable { 
                await medicationViewModel.loadMedicationsAsync()
            }
            .sheet(isPresented: $showingDetailSheet) {
                if let med = selectedMedication {
                    MedicationDetailView(medication: med, scheduler: scheduler)
                }
            }
        }
    }
}

// MARK: - Row
struct MedicationRowView: View {
    let medication: Medication
    let scheduler: MedicationScheduler
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(medication.isActive ?? true ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(medication.name)
                            .font(.headline).fontWeight(.semibold)
                            .foregroundColor(medication.isActive ?? true ? .primary : .secondary)
                            .lineLimit(2)
                        Spacer()
                        
                        // Medication type badge
                        HStack(spacing: 4) {
                            if medication.hasSmartSchedule {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                Text("Smart Schedule")
                                    .font(.caption2)
                            } else if medication.medicationType == "chronic" {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption2)
                                Text("Ongoing")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                        
                        Text(medication.dosage)
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2)).cornerRadius(4)
                    }
                    
                    Text(medication.frequency)
                        .font(.subheadline).foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let timing = medication.timing, !timing.isEmpty {
                        Text("Timing: \(timing)").font(.caption).foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    // Start date and duration information
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            if medication.isActive ?? true {
                                Text("Started: \(medication.formattedStartDate)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Text("Duration: \(medication.durationUsed)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            } else {
                                Text("Started: \(medication.formattedStartDate)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                if let stopDate = medication.formattedStopDate {
                                    Text("Stopped: \(stopDate)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Text("Duration: \(medication.durationUsed)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    
                    if !(medication.isActive ?? true) {
                        Text(medication.medicationStatus)
                            .font(.caption).foregroundColor(.red)
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Color.red.opacity(0.1)).cornerRadius(4)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Progress bar for short-term medications
            if medication.medicationType != "chronic" && medication.progressPercentage > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(medication.progressPercentage)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    ProgressView(value: Double(medication.progressPercentage), total: 100.0)
                        .progressViewStyle(.linear)
                        .scaleEffect(y: 0.6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(2)
                }
            }
            
            // Smart-schedule preview
            if let schedule = scheduler.processUniversalMedication(medication: medication),
               schedule.hasSchedule {
                SmartScheduleView(schedule: schedule, scheduler: scheduler)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .opacity(medication.isActive ?? true ? 1 : 0.6)
    }
}

// MARK: - Smart-Schedule snippet
struct SmartScheduleView: View {
    let schedule: MedicationSchedule
    let scheduler: MedicationScheduler
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: schedule.type == "chronic" ? "arrow.clockwise" : "calendar")
                    .font(.caption).foregroundColor(.blue)
                Text(schedule.type == "chronic" ? "Ongoing Medication" : "Smart Schedule")
                    .font(.caption).fontWeight(.semibold).foregroundColor(.blue)
                Spacer()
                if schedule.hasSchedule, schedule.overallProgress > 0 {
                    Text("\(schedule.overallProgress)% Complete")
                        .font(.caption2).foregroundColor(.secondary)
                }
            }
            
            if schedule.hasSchedule {
                // Overall progress bar
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: Double(schedule.overallProgress), total: 100)
                        .progressViewStyle(.linear)
                        .scaleEffect(y: 0.6)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(2)
                }
                
                let status = scheduler.getMedicationStatus(medicationSchedule: schedule)
                
                // Current status
                HStack {
                    Text(status.message)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .fontWeight(.medium)
                    Spacer()
                    if let days = status.daysRemaining, days > 0 {
                        Text("\(days) days left")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
                
                // Timeline phases (show first 3 phases)
                if schedule.timeline.count > 1 {
                    VStack(spacing: 4) {
                        ForEach(Array(schedule.timeline.prefix(3).enumerated()), id: \.offset) { index, phase in
                            HStack(spacing: 8) {
                                // Phase indicator
                                Circle()
                                    .fill(phase.isCompleted ? Color.green : phase.isActive ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Phase \(phase.phase): \(phase.instruction)")
                                        .font(.caption2)
                                        .foregroundColor(phase.isActive ? .primary : .secondary)
                                    
                                    Text("\(formatDate(phase.startDate)) - \(formatDate(phase.endDate))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if phase.isCompleted {
                                    Text("✓")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                } else if phase.isActive && phase.daysRemaining > 0 {
                                    Text("\(phase.daysRemaining)d")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        if schedule.timeline.count > 3 {
                            Text("... and \(schedule.timeline.count - 3) more phases")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Detail Sheet
struct MedicationDetailView: View {
    let medication: Medication
    let scheduler: MedicationScheduler
    @Environment(\.dismiss) private var dismiss
    
    var allFieldsEmpty: Bool {
        let emptyOrNotSpecified: (String?) -> Bool = { $0 == nil || $0 == "" || $0 == "Not specified" }
        return emptyOrNotSpecified(medication.name) &&
               emptyOrNotSpecified(medication.dosage) &&
               emptyOrNotSpecified(medication.frequency) &&
               emptyOrNotSpecified(medication.fullInstructions)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if allFieldsEmpty {
                        VStack(spacing: 24) {
                            Image(systemName: "pills").font(.system(size: 60)).foregroundColor(.gray)
                            Text("No details available for this medication.").font(.title3).foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(medication.name).font(.largeTitle).fontWeight(.bold)
                                Spacer()
                                if !(medication.isActive ?? true) {
                                    Text("DISCONTINUED")
                                        .font(.caption).fontWeight(.bold).foregroundColor(.white)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.red).cornerRadius(4)
                                }
                            }
                            Text("Dosage: \(medication.dosage)")
                                .font(.title3).foregroundColor(.secondary)
                        }
                        // Smart Schedule
                        if let schedule = scheduler.processUniversalMedication(medication: medication) {
                            SmartScheduleDetailView(schedule: schedule, scheduler: scheduler)
                        }
                        // Basic info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basic Information").font(.headline).fontWeight(.semibold)
                            InfoRow(label: "Frequency",   value: medication.frequency)
                            if let timing = medication.timing     { InfoRow(label: "Timing",     value: timing) }
                            if let route  = medication.route      { InfoRow(label: "Route",      value: route) }
                            if let lat    = medication.laterality { InfoRow(label: "Laterality", value: lat) }
                            if let dur    = medication.duration   { InfoRow(label: "Duration",   value: dur) }
                        }
                        .padding().background(Color(.systemGray6)).cornerRadius(12)
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions").font(.headline).fontWeight(.semibold)
                            Text(medication.fullInstructions ?? "No instructions available").font(.body).lineSpacing(4)
                        }
                        .padding().background(Color.blue.opacity(0.1)).cornerRadius(12)
                        // Discontinued info
                        if !(medication.isActive ?? true) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Discontinuation").font(.headline).fontWeight(.semibold)
                                if let reason = medication.discontinuationReason {
                                    Text("Reason: \(reason)").font(.body)
                                }
                                if let date = medication.discontinuedDate {
                                    Text("Date: \(format(date))").font(.body).foregroundColor(.secondary)
                                }
                            }
                            .padding().background(Color.red.opacity(0.1)).cornerRadius(12)
                        }
                    }
                }
                .padding()
                .navigationTitle("Medication Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                } }
            }
        }
    }
    
    private func format(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
}

// MARK: - Smart-Schedule full view
struct SmartScheduleDetailView: View {
    let schedule: MedicationSchedule
    let scheduler: MedicationScheduler
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Schedule").font(.headline).fontWeight(.semibold)
            if schedule.hasSchedule {
                // Overall progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Overall Progress").font(.subheadline).fontWeight(.medium)
                        Spacer()
                        Text("\(schedule.overallProgress)%").font(.subheadline).fontWeight(.semibold).foregroundColor(.blue)
                    }
                    ProgressView(value: Double(schedule.overallProgress), total: 100)
                        .progressViewStyle(.linear)
                }
                // Timeline
                if !schedule.timeline.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Timeline").font(.subheadline).fontWeight(.medium)
                        ForEach(schedule.timeline, id: \.phase) { phase in
                            PhaseRowView(phase: phase, scheduler: scheduler)
                        }
                    }
                }
            } else {
                Text(schedule.message ?? "Continue as prescribed").font(.body).foregroundColor(.secondary)
            }
        }
        .padding().background(Color(.systemGray6)).cornerRadius(12)
    }
}

// MARK: - Timeline Phase
struct PhaseRowView: View {
    let phase: MedicationPhase
    let scheduler: MedicationScheduler
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Phase \(phase.phase)").font(.subheadline).fontWeight(.semibold)
                Text(phase.instruction).font(.caption).foregroundColor(.secondary)
                Text("\(scheduler.formatDate(phase.startDate)) – \(scheduler.formatDate(phase.endDate))")
                    .font(.caption2).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: phase.isCompleted ? "checkmark.circle.fill"
                                                : (phase.isActive ? "circle.fill" : "circle"))
                .foregroundColor(phase.isCompleted ? .green : (phase.isActive ? .blue : .gray))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Simple info row
struct InfoRow: View {
    let label: String, value: String
    var body: some View {
        HStack {
            Text(label).font(.subheadline).foregroundColor(.secondary).frame(width: 80, alignment: .leading)
            Text(value).font(.subheadline).fontWeight(.medium)
            Spacer()
        }
    }
}
