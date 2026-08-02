//
//  ConversationView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

// ConversationView.swift
import SwiftUI

struct ConversationView: View {
    
    let contact: Contact
    let userName: String
    @ObservedObject var bluetooth: BluetoothManager
    
    @State private var messageInput: String = ""
    
    var body: some View {
        VStack {
            
            // Connection status
            if bluetooth.isConnected {
                Text("Connected to node")
                    .foregroundColor(.green)
                    .font(.caption)
                    .padding(.top, 4)
            } else {
                Text("Not connected — go to Connect tab first")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, 4)
            }
            
            // Message history
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) { // Allows messages to be added smoothly
                        ForEach(bluetooth.messages) { message in
                            HStack {
                                if message.sender == userName {
                                    Spacer()
                                }
                                VStack(alignment: message.sender == userName ? .trailing : .leading, spacing: 2) {
                                    Text(message.text)
                                        .padding(10)
                                        .background(message.sender == userName ? Color.yellow : Color.gray.opacity(0.3))
                                        .foregroundColor(.primary)
                                        .cornerRadius(12)

                                    HStack(spacing: 4) {
                                        Text(formatTime(message.timestamp))
                                            .font(.caption2)
                                            .foregroundColor(.gray)

                                        if message.sender == userName {
                                            Image(systemName: message.status == .delivered ? "checkmark.circle.fill" : "checkmark.circle")
                                                .font(.caption2)
                                                .foregroundColor(message.status == .delivered ? .green : .gray)
                                        }
                                    }
                                }
                                if message.sender != userName {
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                            .id(message.id)
                        }
                    }
                    .padding(.top, 8)
                }
                .onChange(of: bluetooth.messages.count) {
                    // Automatically scroll to the latest message when a new one is added
                    if let last = bluetooth.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Message input area
            HStack {
                TextField("Type here...", text: $messageInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: messageInput) {
                        if messageInput.count > 200 {
                            messageInput = String(messageInput.prefix(200))
                        }
                    }
                
                Text("\(messageInput.count)/200")
                        .font(.caption2)
                        .foregroundColor(messageInput.count >= 200 ? .red : .gray)
                
                Button("Send") {
                    if contact.nodeID == "BROADCAST" {
                        bluetooth.sendEmergencyBroadcast(messageInput, sender: userName)
                    } else {
                        bluetooth.sendMessage(messageInput, sender: userName, destination: contact.nodeID)
                    }
                    messageInput = ""
                }
                .disabled(messageInput.isEmpty || !bluetooth.isConnected)
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
            .padding()
        }
        .navigationTitle(contact.name)
        .toolbarBackground(Color.yellow, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    // Formats the timestamp
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
