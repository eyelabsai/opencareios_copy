//
//  ProfileView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// Views/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = UserViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Details")) {
                    TextField("Name", text: $viewModel.user.name)
                    Text(viewModel.user.email).foregroundColor(.gray)
                }
                
                Section(header: Text("Chronic Conditions")) {
                    ForEach(viewModel.user.chronicConditions, id: \.self) { condition in
                        Text(condition)
                    }
                    .onDelete { indexSet in
                        viewModel.user.chronicConditions.remove(atOffsets: indexSet)
                    }
                    
                    HStack {
                        TextField("New Condition", text: $viewModel.newCondition)
                        Button(action: viewModel.addCondition) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
                
                Section {
                    Button("Save Profile", action: viewModel.updateUserProfile)
                    Button("Sign Out", role: .destructive) {
                        authViewModel.signOut()
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: viewModel.fetchUserProfile)
        }
    }
}