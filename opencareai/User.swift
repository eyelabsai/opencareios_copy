// Models/User.swift
import Foundation
import FirebaseFirestore // Correct import

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    var name: String
    var chronicConditions: [String]
}
