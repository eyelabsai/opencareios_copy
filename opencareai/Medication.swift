// Models/Medication.swift
import Foundation
import FirebaseFirestore // Correct import

struct Medication: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let name: String
    let dosage: String
    let frequency: String
    let timing: String?
    let route: String?
    let laterality: String?
    let duration: String?
    let fullInstructions: String
}
