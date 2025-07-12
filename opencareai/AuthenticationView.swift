// Views/AuthenticationView.swift
import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var isSignUp = false
    @State private var currentStep = 1
    @State private var totalSteps = 7
    
    // Registration fields
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var dob = Date()
    @State private var gender = ""
    @State private var phoneNumber = ""
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zip = ""
    @State private var insuranceProvider = ""
    @State private var insuranceMemberId = ""
    @State private var allergies = ""
    @State private var heightFeet = ""
    @State private var heightInches = ""
    @State private var weight = ""
    @State private var selectedConditions = Set<String>()
    @State private var otherConditions = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    // Options
    private let genderOptions = ["", "Male", "Female", "Other", "Prefer not to say"]
    private let insuranceOptions = ["", "Aetna", "Blue Cross", "Cigna", "UnitedHealthcare", "Kaiser", "None", "Other"]
    private let stateOptions = ["", "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]
    private let chronicConditions = ["Hypertension", "Diabetes", "Asthma", "Heart Disease", "Arthritis", "Depression", "Anxiety", "Obesity", "High Cholesterol", "Thyroid Disease", "Cancer", "Stroke", "Kidney Disease", "Liver Disease", "COPD", "Epilepsy", "Migraine", "Fibromyalgia", "Lupus", "Multiple Sclerosis"]
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case firstName, lastName, phone, street, city, zip, insuranceMemberId, allergies, otherConditions, email, password, confirmPassword
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("OpenCare")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Your AI-Powered Health Assistant")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 50)
                    
                    if isSignUp {
                        // Progress indicator
                        VStack(spacing: 8) {
                            ProgressView(value: Double(currentStep), total: Double(totalSteps))
                                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            
                            Text("Step \(currentStep) of \(totalSteps)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 30)
                        
                        // Multi-step registration form
                        registrationForm
                    } else {
                        // Simple login form
                        loginForm
                    }
                    
                    Spacer()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .password)
                    .textContentType(.password)
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Sign in button
            Button(action: handleSignIn) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.fill")
                    }
                    
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoginFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isLoginFormValid || viewModel.isLoading)
            
            // Toggle to sign up
            Button(action: {
                withAnimation {
                    isSignUp.toggle()
                    clearForm()
                }
            }) {
                Text("Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 30)
    }
    
    private var registrationForm: some View {
        VStack(spacing: 20) {
            Group {
                switch currentStep {
                case 1:
                    basicInfoStep
                case 2:
                    addressStep
                case 3:
                    insuranceStep
                case 4:
                    allergiesStep
                case 5:
                    physicalMeasurementsStep
                case 6:
                    chronicConditionsStep
                case 7:
                    accountSetupStep
                default:
                    EmptyView()
                }
            }
            
            // Error message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Navigation buttons
            HStack(spacing: 12) {
                if currentStep > 1 {
                    Button("Previous") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < totalSteps {
                    Button("Next") {
                        if validateCurrentStep() {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isCurrentStepValid)
                } else {
                    Button(action: handleRegistration) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.badge.plus")
                            }
                            
                            Text("Complete Registration")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isRegistrationFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isRegistrationFormValid || viewModel.isLoading)
                }
            }
            
            // Toggle to sign in
            Button(action: {
                withAnimation {
                    isSignUp.toggle()
                    clearForm()
                }
            }) {
                Text("Already have an account? Sign In")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 30)
    }
    
    // Step 1: Basic Information
    private var basicInfoStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .firstName)
                        .textContentType(.givenName)
                    
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .lastName)
                        .textContentType(.familyName)
                }
                
                DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    .datePickerStyle(CompactDatePickerStyle())
                
                Picker("Gender", selection: $gender) {
                    ForEach(genderOptions, id: \.self) { option in
                        Text(option.isEmpty ? "Select Gender" : option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                TextField("Phone Number", text: $phoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }
        }
    }
    
    // Step 2: Address Information
    private var addressStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Address Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Street Address", text: $street)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .street)
                    .textContentType(.streetAddressLine1)
                
                HStack {
                    TextField("City", text: $city)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .city)
                        .textContentType(.addressCity)
                    
                    Picker("State", selection: $state) {
                        ForEach(stateOptions, id: \.self) { option in
                            Text(option.isEmpty ? "State" : option).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    TextField("ZIP", text: $zip)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($focusedField, equals: .zip)
                        .textContentType(.postalCode)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
        }
    }
    
    // Step 3: Insurance Information
    private var insuranceStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insurance Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Picker("Insurance Provider", selection: $insuranceProvider) {
                    ForEach(insuranceOptions, id: \.self) { option in
                        Text(option.isEmpty ? "Select Provider" : option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                TextField("Insurance Member ID", text: $insuranceMemberId)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .insuranceMemberId)
            }
        }
    }
    
    // Step 4: Allergies
    private var allergiesStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allergies")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Known Allergies", text: $allergies, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .allergies)
                    .lineLimit(3...6)
            }
        }
    }
    
    // Step 5: Physical Measurements
    private var physicalMeasurementsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Physical Measurements")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Height:")
                    Picker("Feet", selection: $heightFeet) {
                        ForEach((4...7).map { String($0) }, id: \.self) { ft in
                            Text("\(ft) ft").tag(ft)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Inches", selection: $heightInches) {
                        ForEach((0...11).map { String($0) }, id: \.self) { inch in
                            Text("\(inch) in").tag(inch)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                HStack {
                    Text("Weight:")
                    Picker("Weight", selection: $weight) {
                        ForEach((80...400).map { String($0) }, id: \.self) { lbs in
                            Text("\(lbs) lbs").tag(lbs)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
        }
    }
    
    // Step 6: Chronic Conditions
    private var chronicConditionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chronic Conditions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Text("Select any chronic conditions you have:")
                    .font(.subheadline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(chronicConditions, id: \.self) { condition in
                        Button(action: {
                            if selectedConditions.contains(condition) {
                                selectedConditions.remove(condition)
                            } else {
                                selectedConditions.insert(condition)
                            }
                        }) {
                            Text(condition)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selectedConditions.contains(condition) ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedConditions.contains(condition) ? .white : .primary)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                TextField("Other conditions (optional)", text: $otherConditions, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .otherConditions)
                    .lineLimit(2...4)
            }
        }
    }
    
    // Step 7: Account Setup
    private var accountSetupStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Setup")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .password)
                    .textContentType(.newPassword)
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($focusedField, equals: .confirmPassword)
                    .textContentType(.newPassword)
            }
        }
    }
    
    // Validation
    private var isLoginFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        email.contains("@") && 
        password.count >= 6
    }
    
    private var isRegistrationFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isCurrentStepValid: Bool {
        switch currentStep {
        case 1:
            return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 3:
            return !insuranceProvider.isEmpty
        case 6:
            return !selectedConditions.isEmpty || !otherConditions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 7:
            return isRegistrationFormValid
        default:
            return true
        }
    }
    
    private func validateCurrentStep() -> Bool {
        return isCurrentStepValid
    }
    
    private func handleSignIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await viewModel.signIn(withEmail: trimmedEmail, password: trimmedPassword)
        }
    }
    
    private func handleRegistration() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dobString = dateFormatter.string(from: dob)
        
        let chronicConditionsString = Array(selectedConditions).joined(separator: ", ") + 
            (otherConditions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : ", " + otherConditions.trimmingCharacters(in: .whitespacesAndNewlines))
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            await viewModel.createUser(
                withEmail: trimmedEmail,
                password: trimmedPassword,
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                dob: dobString,
                gender: gender,
                phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
                street: street.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                state: state,
                zip: zip.trimmingCharacters(in: .whitespacesAndNewlines),
                insuranceProvider: insuranceProvider,
                insuranceMemberId: insuranceMemberId.trimmingCharacters(in: .whitespacesAndNewlines),
                allergies: allergies.trimmingCharacters(in: .whitespacesAndNewlines),
                chronicConditions: chronicConditionsString,
                heightFeet: heightFeet,
                heightInches: heightInches,
                weight: weight
            )
        }
    }
    
    private func clearForm() {
        firstName = ""
        lastName = ""
        dob = Date()
        gender = ""
        phoneNumber = ""
        street = ""
        city = ""
        state = ""
        zip = ""
        insuranceProvider = ""
        insuranceMemberId = ""
        allergies = ""
        heightFeet = ""
        heightInches = ""
        weight = ""
        selectedConditions.removeAll()
        otherConditions = ""
        email = ""
        password = ""
        confirmPassword = ""
        currentStep = 1
        viewModel.errorMessage = nil
        focusedField = nil
    }
}
