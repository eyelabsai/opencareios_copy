// ViewModels/VisitViewModel.swift
import Foundation
import AVFoundation




enum ProcessingState: String {
    case uploading = "Uploading audio..."
    case transcribing = "Transcribing visit..."
    case summarizing = "Summarizing notes..."
    case saving = "Saving visit..."
    case none = ""
}

@MainActor
class VisitViewModel: ObservableObject {
    @Published var audioRecorder = AudioRecorder()
    @Published var transcript: String = ""
    @Published var summary: String = ""
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let apiService = APIService()

    func handleStartStop() {
        if audioRecorder.isRecording {
            stopRecordingAndProcess()
        } else {
            // Use a Task to handle the async permission request
            Task {
                await startRecording()
            }
        }
    }

    private func startRecording() {
            // 1. Use the new AVAudioApplication API for iOS 17+
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                guard let self = self else { return }

                // 2. Handle the response on the main thread
                DispatchQueue.main.async {
                    if granted {
                        do {
                            // We still use AVAudioSession to configure the audio hardware
                            let recordingSession = AVAudioSession.sharedInstance()
                            try recordingSession.setCategory(.record, mode: .default)
                            try recordingSession.setActive(true)
                            
                            // 3. Start recording if permission is granted
                            self.transcript = ""
                            self.summary = ""
                            self.errorMessage = nil
                            try self.audioRecorder.startRecording()
                        } catch {
                            self.errorMessage = "Failed to start recording: \(error.localizedDescription)"
                        }
                    } else {
                        // Permission was denied
                        self.errorMessage = "Microphone permission was denied. Please grant it in Settings."
                    }
                }
            }
        }
    
    @Published var processingState: ProcessingState = .none

        private func stopRecordingAndProcess() {
            guard let audioURL = audioRecorder.stopRecording() else {
                self.errorMessage = "Could not get the audio file."
                return
            }

            isProcessing = true
            errorMessage = nil

            Task {
                do {
                    // Step 1: Uploading
                    self.processingState = .uploading
                    let transcriptResult = try await apiService.transcribeAudio(fileURL: audioURL)
                    
                    // Step 2: Summarizing
                    self.processingState = .summarizing
                    let summaryResponse = try await apiService.summarizeText(transcript: transcriptResult)

                    self.transcript = transcriptResult
                    self.summary = summaryResponse.summary
                    
                    // Step 3: Saving
                    self.processingState = .saving
                    let newVisit = Visit(
                        date: summaryResponse.date == "TODAY" ? Date().ISO8601Format() : summaryResponse.date,
                        summary: summaryResponse.summary,
                        specialty: summaryResponse.specialty,
                        tldr: summaryResponse.tldr,
                        transcript: transcriptResult,
                        medications: summaryResponse.medications
                    )
                    
                    FirebaseService.shared.saveVisit(newVisit) { error in
                        if let error = error { self.errorMessage = "Failed to save visit: \(error.localizedDescription)" }
                    }
                    
                    FirebaseService.shared.saveMedications(summaryResponse.medications) { error in
                         if let error = error { self.errorMessage = "Failed to save medications: \(error.localizedDescription)" }
                    }

                } catch {
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "An unknown error occurred."
                }
                
                // 4. Final UI update
                self.isProcessing = false
                self.processingState = .none
            }
        }
}
