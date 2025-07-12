// Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
            
            VisitHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            MedicationView()
                .tabItem {
                    Label("Meds", systemImage: "pills.fill")
                }

            // HealthAssistantView()
            //     .tabItem {
            //         Label("Assistant", systemImage: "message.fill")
            //     }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .accentColor(.blue)
        .onAppear {
            // Set tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
