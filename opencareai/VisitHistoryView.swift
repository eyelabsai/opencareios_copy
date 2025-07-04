//
//  VisitHistoryView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// Views/VisitHistoryView.swift
import SwiftUI

struct VisitHistoryView: View {
    @StateObject private var viewModel = VisitHistoryViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.visits) { visit in
                NavigationLink(destination: VisitDetailView(visit: visit)) {
                    VStack(alignment: .leading) {
                        Text(visit.specialty).font(.headline)
                        Text(visit.date).font(.subheadline)
                        Text(visit.tldr).font(.caption).lineLimit(1)
                    }
                }
            }
            .navigationTitle("Visit History")
            .onAppear {
                viewModel.fetchVisits()
            }
        }
    }
}

struct VisitDetailView: View {
    let visit: Visit

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Text(visit.specialty).font(.largeTitle)
                Text(visit.date).font(.subheadline).padding(.bottom)
                
                Text("Summary").font(.headline)
                Text(visit.summary)
                
                if !visit.medications.isEmpty {
                    Text("Medications Prescribed").font(.headline).padding(.top)
                    ForEach(visit.medications) { med in
                        Text("- \(med.name) (\(med.dosage))")
                    }
                }
                
                Text("Full Transcript").font(.headline).padding(.top)
                Text(visit.transcript)
            }
            .padding()
        }
        .navigationTitle("Visit Details")
    }
}