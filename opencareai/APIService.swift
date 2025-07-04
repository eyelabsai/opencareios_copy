// Services/APIService.swift
import Foundation

// More specific network errors to help with debugging
enum NetworkError: LocalizedError {
    case badURL(String)
    case badResponse(statusCode: Int, responseBody: String)
    case decodingError(Error)
    case requestFailed(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .badURL(let message): return "Error creating URL: \(message)."
        case .badResponse(let statusCode, let responseBody): return "Server returned an invalid response: \(statusCode). Body: \(responseBody)"
        case .decodingError(let error): return "Failed to decode the server's response: \(error.localizedDescription)."
        case .requestFailed(let error): return "The network request failed: \(error.localizedDescription)"
        case .unknown: return "An unknown network error occurred."
        }
    }
}

class APIService {
    // This function now reads the server URL from your app's Info.plist
    private var baseURL: URL? {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "ServerURL") as? String else {
            print("CRITICAL ERROR: 'ServerURL' not found in Info.plist. Please add it.")
            return nil
        }
        return URL(string: urlString)
    }

    func transcribeAudio(fileURL: URL) async throws -> String {
        guard let baseURL = self.baseURL else { throw NetworkError.badURL("ServerURL not configured in Info.plist") }
        let url = baseURL.appendingPathComponent("/api/transcribe")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // This creates the body of the request, sending the audio file
        request.httpBody = createTranscribeBody(from: fileURL, boundary: boundary)
        
        // Make the network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check the server's response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.unknown
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            throw NetworkError.badResponse(statusCode: httpResponse.statusCode, responseBody: responseBody)
        }

        // Decode the JSON response from the server
        do {
            let result = try JSONDecoder().decode([String: String].self, from: data)
            return result["transcript"] ?? ""
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    // --- The rest of your APIService file remains the same ---
    // (summarizeText, sendHealthAssistantQuery, createTranscribeBody)
    
    func summarizeText(transcript: String) async throws -> SummarizationResponse {
        guard let url = baseURL?.appendingPathComponent("/api/summarise") else { throw NetworkError.badURL("ServerURL not configured in Info.plist") }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["transcript": transcript])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, responseBody: String(data: data, encoding: .utf8) ?? "")
        }
        do {
            return try JSONDecoder().decode(SummarizationResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    func sendHealthAssistantQuery(query: String, userId: String) async throws -> String {
        guard let url = baseURL?.appendingPathComponent("/api/health-assistant") else { throw NetworkError.badURL("ServerURL not configured in Info.plist") }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["query": query, "userId": userId])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.badResponse(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, responseBody: String(data: data, encoding: .utf8) ?? "")
        }
        do {
            let result = try JSONDecoder().decode([String: String].self, from: data)
            return result["answer"] ?? "No answer received."
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func createTranscribeBody(from fileURL: URL, boundary: String) -> Data {
        var body = Data()
        let filename = fileURL.lastPathComponent
        guard let audioData = try? Data(contentsOf: fileURL) else {
            return body
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}
