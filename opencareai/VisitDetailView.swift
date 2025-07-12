import SwiftUI

struct VisitDetailView: View {
    let visit: Visit
    @EnvironmentObject var visitViewModel: VisitViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Visit Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visit.specialty ?? "Unknown Specialty")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(visit.formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { showingEditSheet = true }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        if visit.medicationsCount > 0 {
                            HStack {
                                Image(systemName: "pills")
                                    .foregroundColor(.blue)
                                Text("\(visit.medicationsCount) medication(s)")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    
                    // Visit Summary
                    if let summary = visit.summary, !summary.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Visit Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(summary)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    
                    // Quick Summary (TL;DR)
                    if let tldr = visit.tldr, !tldr.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Summary")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(tldr)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    
                    // Medications
                    if let medications = visit.medications, !medications.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Medications")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            LazyVStack(spacing: 8) {
                                ForEach(medications) { medication in
                                    MedicationItem(
                                        medication: medication,
                                        onTap: { },
                                        onDelete: { }
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        PrimaryButton("Share Visit Summary") {
                            shareVisitSummary()
                        }
                        
                        SecondaryButton(title: "Export to PDF") {
                            exportToPDF()
                        }
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Visit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDeleteAlert = true }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Delete Visit", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    visitViewModel.deleteVisit(visit)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this visit? This action cannot be undone.")
            }
            .sheet(isPresented: $showingEditSheet) {
                EditVisitView(visit: visit)
                    .environmentObject(visitViewModel)
            }
        }
    }
    
    private func shareVisitSummary() {
        var shareText = "Medical Visit Summary\n\n"
        shareText += "Specialty: \(visit.specialty ?? "Unknown")\n"
        shareText += "Date: \(visit.formattedDate)\n\n"
        
        if let tldr = visit.tldr {
            shareText += "Quick Summary: \(tldr)\n\n"
        }
        
        if let summary = visit.summary {
            shareText += "Full Summary: \(summary)\n\n"
        }
        
        if let medications = visit.medications, !medications.isEmpty {
            shareText += "Medications:\n"
            for medication in medications {
                shareText += "• \(medication.formattedInstructions)\n"
            }
        }
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
    
    private func exportToPDF() {
        // PDF export functionality would be implemented here
        // For now, just show a placeholder
    }
}

// MARK: - Edit Visit View
struct EditVisitView: View {
    let visit: Visit
    @EnvironmentObject var visitViewModel: VisitViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var specialty: String
    @State private var summary: String
    @State private var tldr: String
    
    init(visit: Visit) {
        self.visit = visit
        _specialty = State(initialValue: visit.specialty ?? "")
        _summary = State(initialValue: visit.summary ?? "")
        _tldr = State(initialValue: visit.tldr ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Visit Information") {
                    TextField("Specialty", text: $specialty)
                    
                    TextField("Quick Summary (TL;DR)", text: $tldr, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Full Summary") {
                    TextField("Visit Summary", text: $summary, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Edit Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        // Update visit with new data
        var updatedVisit = visit
        updatedVisit.specialty = specialty
        updatedVisit.summary = summary
        updatedVisit.tldr = tldr
        
        // Save to Firebase
        Task {
            // This would update the visit in Firebase
            // For now, just dismiss
            dismiss()
        }
    }
}

#Preview {
    let sampleVisit = Visit(
        id: "1",
        date: Date(),
        specialty: "Cardiology",
        summary: "Patient presented with chest pain. EKG was normal. Prescribed nitroglycerin for emergency use.",
        tldr: "Chest pain evaluation - normal EKG, prescribed nitroglycerin",
        medications: [
            Medication(
                name: "Nitroglycerin",
                dosage: "0.4mg",
                frequency: "as needed",
                fullInstructions: "0.4mg sublingual as needed for chest pain"
            )
        ]
    )
    
    VisitDetailView(visit: sampleVisit)
        .environmentObject(VisitViewModel())
}