// Models/Visit.swift
import Foundation
import FirebaseFirestore // Correct import

struct Visit: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let date: String
    let summary: String
    let specialty: String
    let tldr: String
    let transcript: String
    let medications: [Medication]
}
