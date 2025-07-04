//
//  HealthAssistantView.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// Views/HealthAssistantView.swift
import SwiftUI

struct HealthAssistantView: View {
    @StateObject private var viewModel = HealthAssistantViewModel()
    @State private var messageText: String = ""

    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(viewModel.messages, id: \.self) { message in
                            Text(message)
                                .padding(8)
                                .background(message.starts(with: "You:") ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .frame(maxWidth: .infinity, alignment: message.starts(with: "You:") ? .trailing : .leading)
                        }
                    }
                    .padding()
                }
                
                HStack {
                    TextField("Ask about your health...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: {
                        viewModel.sendMessage(messageText)
                        messageText = ""
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Health Assistant")
        }
    }
}