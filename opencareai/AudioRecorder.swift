//  AudioRecorder.swift
import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var timer: Timer?
    private var recordingStartTime: Date?
    
    private let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission(completionHandler: { granted in
                    continuation.resume(returning: granted)
                })
            }
        } else {
            return await withCheckedContinuation { continuation in
                audioSession.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    func startRecording() async {
        guard await requestMicrophonePermission() else {
            errorMessage = "Microphone permission is required to record visits"
            return
        }
        
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("visit_recording_\(Date().timeIntervalSince1970).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            recordingStartTime = Date()
            errorMessage = nil
            
            startTimer()
            
            print("🎤 Recording started: \(audioFilename)")
        } catch {
            print("❌ Recording error: \(error)")
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        timer?.invalidate()
    }
    
    func resumeRecording() {
        audioRecorder?.record()
        isPaused = false
        startTimer()
    }
    
    func stopRecording() -> Data? {
        audioRecorder?.stop()
        timer?.invalidate()
        stopAudioLevelMonitoring()
        
        isRecording = false
        isPaused = false
        
        guard let url = audioRecorder?.url else { return nil }
        
        do {
            let audioData = try Data(contentsOf: url)
            // Clean up the temporary file
            try FileManager.default.removeItem(at: url)
            return audioData
        } catch {
            errorMessage = "Failed to get recording data: \(error.localizedDescription)"
            return nil
        }
    }
    
    func resetRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        stopAudioLevelMonitoring()
        
        isRecording = false
        isPaused = false
        recordingTime = 0
        audioLevel = 0.0
        errorMessage = nil
        recordingStartTime = nil
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingTime = Date().timeIntervalSince(startTime)
        }
    }
    
    private func startAudioLevelMonitoring() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            
            let channelData = buffer.floatChannelData?[0]
            let frameLength = UInt(buffer.frameLength)
            
            var sum: Float = 0
            for i in 0..<Int(frameLength) {
                let sample = channelData?[i] ?? 0
                sum += sample * sample
            }
            
            let rms = sqrt(sum / Float(frameLength))
            let db = 20 * log10(rms)
            
            DispatchQueue.main.async {
                self.audioLevel = max(0, min(1, (db + 60) / 60)) // Normalize to 0-1
            }
        }
        
        do {
            try audioEngine?.start()
        } catch {
            errorMessage = "Failed to start audio monitoring: \(error.localizedDescription)"
        }
    }
    
    private func stopAudioLevelMonitoring() {
        inputNode?.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
    }
    
    func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            errorMessage = "Recording failed to complete successfully"
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            errorMessage = "Recording error: \(error.localizedDescription)"
        }
    }
}
