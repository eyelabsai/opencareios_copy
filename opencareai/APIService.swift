// Services/APIService.swift
import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    // Base URL - should match your web app server
    private let baseURL = "https://opencare-gpt.vercel.app/api" // Updated to use deployed Vercel backend
    
    private init() {}
    
    // MARK: - Transcription API
    func transcribeAudio(audioData: Data, filename: String) async throws -> TranscriptionResponse {
        print("🌐 API: Starting transcription request...")
        print("🌐 API: Audio data size: \(audioData.count) bytes")
        print("🌐 API: Filename: \(filename)")
        
        guard let url = URL(string: "\(baseURL)/transcribe") else {
            print("❌ API: Invalid URL")
            throw APIError.invalidURL
        }
        
        print("🌐 API: URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add the audio file with correct M4A extension
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("🌐 API: Request body size: \(body.count) bytes")
        print("🌐 API: Sending request...")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        print("🌐 API: Response received")
        print("🌐 API: Response data size: \(data.count) bytes")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ API: Invalid response type")
            throw APIError.invalidResponse
        }
        
        print("🌐 API: HTTP status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API: Server error with status code: \(httpResponse.statusCode)")
            print("❌ API: Error response: \(errorString)")
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        do {
            let transcriptionResponse = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
            print("✅ API: Transcription successful")
            return transcriptionResponse
        } catch {
            print("❌ API: JSON decode error: \(error)")
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Summarization API
    func summarizeTranscript(transcript: String) async throws -> SummarizationResponseAPI {
        guard let url = URL(string: "\(baseURL)/summarise") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["transcript": transcript]
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            let summarizationResponse = try JSONDecoder().decode(SummarizationResponseAPI.self, from: data)
            
            if !summarizationResponse.success {
                throw APIError.summarizationFailed(summarizationResponse.error ?? "Unknown error")
            }
            
            return summarizationResponse
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Health Assistant API
    func askHealthAssistant(question: String, context: String? = nil) async throws -> HealthAssistantResponse {
        guard let url = URL(string: "\(baseURL)/assistant") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var requestBody: [String: Any] = ["question": question]
        if let context = context {
            requestBody["context"] = context
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            let assistantResponse = try JSONDecoder().decode(HealthAssistantResponse.self, from: data)
            
            if !assistantResponse.success {
                throw APIError.assistantFailed(assistantResponse.error ?? "Unknown error")
            }
            
            return assistantResponse
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Test API Connection
    func testConnection() async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/test") else {
            throw APIError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw APIError.serverError(httpResponse.statusCode)
            }
            
            let testResponse = try JSONDecoder().decode([String: Bool].self, from: data)
            return testResponse["success"] ?? false
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    // MARK: - Combined Visit Processing
    func processVisit(audioData: Data, filename: String) async throws -> VisitSummary {
        // Step 1: Transcribe audio
        let transcriptionResponse = try await transcribeAudio(audioData: audioData, filename: filename)
        
        guard let transcript = transcriptionResponse.transcript else {
            throw APIError.transcriptionFailed("No transcript received")
        }
        
        // Step 2: Summarize transcript
        let summarizationResponse = try await summarizeTranscript(transcript: transcript)
        
        // Step 3: Convert to VisitSummary
        // Convert MedicationAction objects to strings for VisitSummary
        let medicationActionStrings = (summarizationResponse.medicationActions ?? []).map { $0.action.rawValue }
        
        let visitSummary = VisitSummary(
            summary: summarizationResponse.summary ?? "",
            tldr: summarizationResponse.tldr ?? "",
            specialty: summarizationResponse.specialty ?? "General",
            date: summarizationResponse.date ?? "TODAY",
            medications: summarizationResponse.medications ?? [],
            medicationActions: medicationActionStrings,
            chronicConditions: summarizationResponse.chronicConditions ?? []
        )
        
        return visitSummary
    }
}

// MARK: - API Configuration
extension APIService {
    func configureBaseURL(_ url: String) {
        // This allows dynamic configuration of the base URL
        // For example, when deploying to different environments
    }
    
    func getBaseURL() -> String {
        return baseURL
    }
}
