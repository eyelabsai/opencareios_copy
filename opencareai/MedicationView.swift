//
//  MedicationView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// Views/MedicationView.swift
import SwiftUI

struct MedicationView: View {
    @StateObject private var viewModel = MedicationViewModel()

    var body: some View {
        NavigationView {
            List(viewModel.medications) { medication in
                VStack(alignment: .leading) {
                    Text(medication.name).font(.headline)
                    Text(medication.dosage).font(.subheadline)
                    Text(medication.fullInstructions).font(.caption)
                }
            }
            .navigationTitle("Medications")
            .onAppear {
                viewModel.fetchMedications()
            }
        }
    }
}