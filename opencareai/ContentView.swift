// Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var medicationViewModel = MedicationViewModel() // Shared instance
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
                .tag(0)
                .environmentObject(medicationViewModel)
                .environmentObject(VisitViewModel())
                .environmentObject(StatsViewModel())
                .environmentObject(AudioRecorder())
            
            VisitHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)
                .environmentObject(medicationViewModel)

            MedicationView()
                .tabItem {
                    Label("Meds", systemImage: "pills.fill")
                }
                .tag(2)
                .environmentObject(medicationViewModel)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
                .environmentObject(medicationViewModel)
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
