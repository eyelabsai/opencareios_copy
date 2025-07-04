// opencareaiApp.swift
import SwiftUI
import Firebase

@main
struct opencareaiApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // The AuthViewModel will be the single source of truth for authentication state
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            // Show AuthenticationView if the user is not logged in,
            // otherwise show the main ContentView.
            if authViewModel.userSession == nil {
                AuthenticationView()
                    .environmentObject(authViewModel)
            } else {
                ContentView()
                    .environmentObject(authViewModel)
            }
        }
    }
}
