//
//  ProfileView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//

import SwiftUI
import UIKit // Keep this import for the DocumentExporter
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var viewModel = UserViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    
    // EnvironmentObjects for the report
    @EnvironmentObject var visitViewModel: VisitViewModel
    @EnvironmentObject var medicationViewModel: MedicationViewModel
    
    @State private var reportURL: URL?
    
    @State private var showingAddCondition = false
    @State private var newCondition = ""
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var showingReauthAlert = false
    @State private var reauthPassword = ""
    @State private var showingPasswordPrompt = false
    
    private let genderOptions = ["", "Male", "Female", "Other", "Prefer not to say"]
    private let bloodTypeOptions = ["", "A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-", "Unknown"]
    private let insuranceOptions = ["", "Aetna", "Blue Cross", "Cigna", "UnitedHealthcare", "Kaiser", "None", "Other"]
    private let stateOptions = ["", "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    personalInfoSection
                    addressSection
                    insuranceSection
                    emergencySection
                    healthSection
                    healthKitSection
                    appearanceSection
                    reminderSettingsSection
                    chronicConditionsSection
                    accountActionsSection
                    
                    // Delete Account Section
                    deleteAccountSection
                    
                    if let errorMessage = viewModel.errorMessage {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            
                            if errorMessage.contains("User not found") {
                                Button("Create Profile") {
                                    Task {
                                        await viewModel.createUserProfile()
                                    }
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task { await viewModel.fetchUserProfile() }
            }
            .sheet(isPresented: $showingAddCondition) {
                AddConditionSheet(newCondition: $newCondition, onAdd: {
                    Task { await viewModel.addCondition(newCondition) }
                    newCondition = ""
                    showingAddCondition = false
                })
            }
            // --- This is the correct placement for the sheet modifier ---
        }
    }
    
    // MARK: - Subviews
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 100, height: 100)
                .overlay(
                    Text((viewModel.user.firstName.prefix(1) + viewModel.user.lastName.prefix(1)).uppercased())
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)
                )
            VStack(spacing: 4) {
                Text(viewModel.user.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "User" : viewModel.user.fullName)
                    .font(.title2).fontWeight(.semibold)
                Text(viewModel.user.email).font(.subheadline).foregroundColor(.secondary)
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }

    private var personalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal Information").font(.headline).fontWeight(.semibold)
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "person.fill").foregroundColor(.blue).frame(width: 20)
                    TextField("First Name", text: $viewModel.user.firstName).textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Last Name", text: $viewModel.user.lastName).textFieldStyle(RoundedBorderTextFieldStyle())
                }
                HStack {
                    Image(systemName: "calendar").foregroundColor(.blue).frame(width: 20)
                    DatePicker("Date of Birth", selection: Binding(
                        get: { dateFromString(viewModel.user.dob) ?? Date() },
                        set: { viewModel.user.dob = stringFromDate($0) }
                    ), displayedComponents: .date).labelsHidden()
                }
                HStack {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Picker("Gender", selection: $viewModel.user.gender) {
                        Text("Select").tag("")
                        ForEach(genderOptions.filter { !$0.isEmpty }, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                HStack {
                    Image(systemName: "phone.fill").foregroundColor(.blue).frame(width: 20)
                    TextField("Phone Number", text: $viewModel.user.phoneNumber).textFieldStyle(RoundedBorderTextFieldStyle()).keyboardType(.phonePad)
                }
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }

    private var addressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Address").font(.headline).fontWeight(.semibold)
            VStack(spacing: 12) {
                TextField("Street Address", text: $viewModel.user.street).textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    TextField("City", text: $viewModel.user.city).textFieldStyle(RoundedBorderTextFieldStyle())
                    Picker("State", selection: $viewModel.user.state) {
                        Text("Select").tag("")
                        ForEach(stateOptions.filter { !$0.isEmpty }, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    TextField("ZIP", text: $viewModel.user.zip)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numbersAndPunctuation)
                }
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }
    
    private var insuranceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insurance").font(.headline).fontWeight(.semibold)
            VStack(spacing: 12) {
                Picker("Insurance Provider", selection: $viewModel.user.insuranceProvider) {
                    Text("Select").tag("")
                    ForEach(insuranceOptions.filter { !$0.isEmpty }, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(MenuPickerStyle())
                TextField("Insurance Member ID", text: $viewModel.user.insuranceMemberId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }
    
    private var emergencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emergency Contact").font(.headline).fontWeight(.semibold)
            VStack(spacing: 12) {
                TextField("Contact Name", text: $viewModel.user.emergencyContactName).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Contact Phone", text: $viewModel.user.emergencyContactPhone).textFieldStyle(RoundedBorderTextFieldStyle()).keyboardType(.phonePad)
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }

    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Health").font(.headline).fontWeight(.semibold)
            VStack(spacing: 12) {
                TextField("Primary Physician", text: $viewModel.user.primaryPhysician).textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Known Allergies", text: Binding(
                    get: { viewModel.user.allergies.joined(separator: ", ") },
                    set: { newValue in
                        viewModel.user.allergies = newValue.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                    }
                )).textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Text("Height:")
                    Picker("Feet", selection: $viewModel.user.heightFeet) {
                        Text("Select").tag("")
                        ForEach((4...7).map { String($0) }, id: \.self) { Text("\($0) ft").tag(String($0)) }
                    }
                    .pickerStyle(MenuPickerStyle())
                    Picker("Inches", selection: $viewModel.user.heightInches) {
                        Text("Select").tag("")
                        ForEach((0...11).map { String($0) }, id: \.self) { Text("\($0) in").tag(String($0)) }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                HStack {
                    Text("Weight:")
                    Picker("Weight", selection: $viewModel.user.weight) {
                        Text("Select").tag("")
                        ForEach((80...400).map { String($0) }, id: \.self) { Text("\($0) lbs").tag(String($0)) }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                Picker("Blood Type", selection: $viewModel.user.bloodType) {
                    Text("Select").tag("")
                    ForEach(bloodTypeOptions.filter { !$0.isEmpty }, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apple Health")
                .font(.headline)
                .fontWeight(.semibold)

            Button(action: syncWithHealthKit) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Sync with Health App")
                    Spacer()

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance").font(.headline).fontWeight(.semibold)
            VStack(spacing: 12) {
                Picker("Theme", selection: $appState.colorScheme) {
                    ForEach(ColorSchemeOption.allCases, id: \.self) { scheme in
                        Text(scheme.displayName).tag(scheme)
                    }
                }.pickerStyle(MenuPickerStyle())
                Text("Choose your preferred app appearance").font(.subheadline).foregroundColor(.secondary)
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }
    
    private var reminderSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notification Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            NavigationLink(destination: MedicationTimeSettingsView()) {
                HStack {
                    Text("Medication Reminder Times")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    private var chronicConditionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Chronic Conditions").font(.headline).fontWeight(.semibold)
                Spacer()
                Button(action: { showingAddCondition = true }) {
                    Image(systemName: "plus.circle.fill").foregroundColor(.blue).font(.title2)
                }
            }
            if viewModel.user.chronicConditions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square").font(.system(size: 40)).foregroundColor(.gray)
                    Text("No chronic conditions added").font(.subheadline).foregroundColor(.secondary)
                    Button("Add Condition") { showingAddCondition = true }.buttonStyle(.bordered)
                }.padding().frame(maxWidth: .infinity).background(Color(.systemGray6)).cornerRadius(12)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(viewModel.user.chronicConditions, id: \.self) { condition in
                        HStack {
                            Text(condition).font(.subheadline).lineLimit(1)
                            Spacer()
                            Button(action: { Task { await viewModel.removeCondition(condition) } }) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.caption)
                            }
                        }.padding(.horizontal, 12).padding(.vertical, 8).background(Color.blue.opacity(0.1)).cornerRadius(8)
                    }
                }
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }

    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button(action: generateAndExportReport) {
                HStack {
                    Image(systemName: "square.and.arrow.down.fill")
                    Text("Export Health Report")
                }.frame(maxWidth: .infinity).padding().background(Color.green).foregroundColor(.white).cornerRadius(12)
            }
            Button(action: { Task { await viewModel.updateUserProfile() } }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Changes")
                }.frame(maxWidth: .infinity).padding().background(Color.blue).foregroundColor(.white).cornerRadius(12)
            }.disabled(viewModel.isLoading)
            Button(action: { authViewModel.signOut() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                }.frame(maxWidth: .infinity).padding().background(Color.red).foregroundColor(.white).cornerRadius(12)
            }
        }.padding().background(Color(.systemBackground)).cornerRadius(16).shadow(radius: 2)
    }

    // MARK: - Functions
    
    private func syncWithHealthKit() {
        HealthKitManager.shared.requestAuthorization { success in
            guard success else { return }
            
            // Fetch Height
            HealthKitManager.shared.fetchMostRecentHeight { heightInInches in
                if let height = heightInInches {
                    let feet = Int(height / 12)
                    let inches = Int(height.truncatingRemainder(dividingBy: 12))
                    viewModel.user.heightFeet = String(feet)
                    viewModel.user.heightInches = String(inches)
                }
            }
            
            // Fetch Weight
            HealthKitManager.shared.fetchMostRecentWeight { weightInPounds in
                if let weight = weightInPounds {
                    viewModel.user.weight = String(Int(weight.rounded()))
                }
            }
            
        }
    }
    
    private func generateAndExportReport() {
            // 1. Create the report view
            let reportView = HealthReportView(
                userViewModel: self.viewModel,
                visitViewModel: self.visitViewModel,
                medicationViewModel: self.medicationViewModel
            )
            
            // 2. Generate the PDF and get its URL
            guard let url = PDFGenerator.generate(from: reportView) else {
                print("Failed to generate PDF URL.")
                return
            }
            self.reportURL = url
            
            // 3. Present the document picker using UIKit
            guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?
                .windows
                .first?
                .rootViewController else {
                print("Could not find root view controller.")
                return
            }
            
            let documentPicker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
            
            // We don't need a delegate for this simple save operation
            
            rootViewController.present(documentPicker, animated: true, completion: nil)
        }
    
    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Delete My Account")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text("This action will permanently delete your account and all associated data including visits, medications, and health records. This cannot be undone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                HStack {
                    if isDeletingAccount {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "trash.fill")
                    }
                    Text(isDeletingAccount ? "Deleting Account..." : "Delete My Account")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(8)
            }
            .disabled(isDeletingAccount)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete My Account", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This will permanently erase all your saved data including visits, medications, and health records. This action cannot be undone.")
        }
        .alert("Account Deletion Failed", isPresented: $showingDeleteAccountAlert) {
            Button("OK") { }
        } message: {
            Text("There was an error deleting your account. Please try again or contact support if the problem persists.")
        }
        .alert("Re-authentication Required", isPresented: $showingReauthAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Re-authenticate") {
                showingPasswordPrompt = true
            }
        } message: {
            Text("For security reasons, you need to re-enter your password before deleting your account.")
        }
        .sheet(isPresented: $showingPasswordPrompt) {
            ReauthenticationView(
                password: $reauthPassword,
                onAuthenticate: { password in
                    Task {
                        await reauthenticateAndDelete(password: password)
                    }
                },
                onCancel: {
                    showingPasswordPrompt = false
                    reauthPassword = ""
                }
            )
        }
    }
    
    // Helper functions for date conversion
>>>>>>> 5ea5c47 (delete account feature)
    private func dateFromString(_ str: String) -> Date? {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; return formatter.date(from: str)
    }
    
    private func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; return formatter.string(from: date)
    }
    
    // MARK: - Account Deletion
    private func deleteAccount() {
        isDeletingAccount = true
        
        Task {
            do {
                // First, delete user data from Firestore
                try await deleteUserData()
                
                // Then delete the Firebase Auth account
                try await deleteFirebaseAccount()
                
                // Success - user will be automatically signed out
                await MainActor.run {
                    isDeletingAccount = false
                }
                
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    
                    // Check if it's a re-authentication error
                    let errorDescription = error.localizedDescription
                    if errorDescription.contains("requires recent authentication") || 
                       errorDescription.contains("ERROR_REQUIRES_RECENT_LOGIN") {
                        showingReauthAlert = true
                    } else {
                        showingDeleteAccountAlert = true
                    }
                }
                print("❌ Error deleting account: \(error)")
                print("❌ Error domain: \(error._domain)")
                print("❌ Error code: \(error._code)")
                print("❌ Error description: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteUserData() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "AccountDeletion", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        let firebaseService = OpenCareFirebaseService.shared
        
        // Delete user profile
        try await firebaseService.deleteUserData(userId: userId)
        
        // Delete user visits
        try await firebaseService.deleteUserVisits(userId: userId)
        
        // Delete user medications
        try await firebaseService.deleteUserMedications(userId: userId)
        
        print("✅ User data deleted successfully")
    }
    
    private func deleteFirebaseAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "AccountDeletion", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await user.delete()
        print("✅ Firebase account deleted successfully")
    }
    
    private func reauthenticateAndDelete(password: String) async {
        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            await MainActor.run {
                showingDeleteAccountAlert = true
            }
            return
        }
        
        do {
            // Re-authenticate the user
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await user.reauthenticate(with: credential)
            
            // Now try to delete the account again
            try await deleteUserData()
            try await user.delete()
            
            await MainActor.run {
                isDeletingAccount = false
                showingPasswordPrompt = false
                reauthPassword = ""
            }
            
            print("✅ Account deleted successfully after re-authentication")
            
        } catch {
            await MainActor.run {
                isDeletingAccount = false
                showingPasswordPrompt = false
                reauthPassword = ""
                showingDeleteAccountAlert = true
            }
            print("❌ Error during re-authentication: \(error)")
        }
    }
}

// MARK: - Reauthentication View
struct ReauthenticationView: View {
    @Binding var password: String
    let onAuthenticate: (String) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    
                    Text("Security Verification")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("For your security, please enter your password to confirm account deletion.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    SecureField("Enter your password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        isLoading = true
                        onAuthenticate(password)
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "trash.fill")
                            }
                            Text(isLoading ? "Verifying..." : "Delete Account")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    .disabled(password.isEmpty || isLoading)
                    
                    Button(action: {
                        onCancel()
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    .disabled(isLoading)
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Verify Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
}
>>>>>>> 5ea5c47 (delete account feature)

// MARK: - Helper Structs
struct AddConditionSheet: View {
    @Binding var newCondition: String
    let onAdd: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let commonConditions = ["Hypertension", "Diabetes", "Asthma"]
    
    var body: some View {
        NavigationView {
            VStack {
                // UI for adding a condition
                Text("Add a new condition").font(.headline)
                TextField("Condition name", text: $newCondition).textFieldStyle(.roundedBorder)
                HStack {
                    Button("Cancel") { dismiss() }.buttonStyle(.bordered)
                    Button("Add") { onAdd() }.buttonStyle(.borderedProminent).disabled(newCondition.isEmpty)
                }
            }.padding()
        }
    }
}

