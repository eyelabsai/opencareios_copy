// Views/HomeView.swift
import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = VisitViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if viewModel.audioRecorder.isRecording {
                    VStack {
                        Text("Recording...")
                            .font(.headline)
                            .foregroundColor(.red)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.red)
                            .transition(.scale)
                    }
                    .padding(.vertical, 40)
                } else if viewModel.isProcessing {
                    // --- This is the updated section ---
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text(viewModel.processingState.rawValue)
                            .font(.caption)
                            .padding(.top, 8)
                    }
                    .padding()
                    // --- End of updated section ---
                } else if !viewModel.summary.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Summary").font(.headline)
                            Text(viewModel.summary)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            
                            Text("Transcript").font(.headline)
                            Text(viewModel.transcript)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                
                Button(action: viewModel.handleStartStop) {
                    Text(viewModel.audioRecorder.isRecording ? "Stop Recording" : "Start New Visit")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.audioRecorder.isRecording ? Color.red : (viewModel.isProcessing ? Color.gray : Color.blue))
                        .cornerRadius(10)
                }
                .disabled(viewModel.isProcessing)
            }
            .padding()
            .navigationTitle("AI Health Assistant")
        }
    }
}
