//
//  ConversationView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

// ConversationView.swift
import SwiftUI

// Simple model to represent a sent message
struct Message: Identifiable {
    let id = UUID()
    let text: String
    let sender: String
    let timestamp: Date
}

struct ConversationView: View {
    
    let contact: Contact
    let userName: String
    @ObservedObject var bluetooth: BluetoothManager
    
    @State private var messageInput: String = ""
    @State private var messages: [Message] = []   // stores all sent messages
    
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
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(messages) { message in
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(message.text)
                                        .padding(10)
                                        .background(Color.yellow)
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                    Text(formatTime(message.timestamp))
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            .id(message.id)   // needed for ScrollViewReader to find this message
                        }
                    }
                    .padding(.top, 8)
                }
                .onChange(of: messages.count) {
                    // Automatically scroll to the latest message when a new one is added
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack {
                TextField("Type here...", text: $messageInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Send") {
                    let newMessage = Message(
                        text: messageInput,
                        sender: userName,
                        timestamp: Date()
                    )
                    messages.append(newMessage)         // add to history
                    bluetooth.sendMessage(messageInput) // send over bluetooth
                    messageInput = ""                   // clear the field
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
    
    // Formats the timestamp as a readable time string
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
