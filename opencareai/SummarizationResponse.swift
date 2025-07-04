// Models/SummarizationResponse.swift
import Foundation

struct SummarizationResponse: Codable {
    let summary: String
    let tldr: String
    let specialty: String
    let date: String
    let medications: [Medication]
}
