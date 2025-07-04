// Views/ContentView.swift
import SwiftUI

struct ContentView: View {
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

            HealthAssistantView()
                .tabItem {
                    Label("Assistant", systemImage: "message.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}
