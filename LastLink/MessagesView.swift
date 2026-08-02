//
//  MessagesView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

// MessagesView.swift
import SwiftUI

struct MessagesView: View {
    
    let userName: String
    @ObservedObject var bluetooth: BluetoothManager  // received from ContentView
    
    var body: some View {
            NavigationStack {
                VStack(spacing: 0) {
                    
                    if let emergency = bluetooth.emergencyMessage {
                        EmergencyBanner(message: emergency) {
                            bluetooth.emergencyMessage = nil
                        }
                    }
                    
                    List(bluetooth.visibleContacts) { contact in
                        NavigationLink(destination: ConversationView(
                            contact: contact,
                            userName: userName,
                            bluetooth: bluetooth
                        )) {
                            HStack {
                                Text(contact.name)
                                Spacer()
                                Circle()
                                    .fill(bluetooth.isConnected ? Color.green : Color.red)
                                    .frame(width: 20, height: 20)
                            }
                        }
                    }
                }
                .navigationTitle("Contacts")
            }
            .toolbarBackground(Color.yellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
}

// Banner at the top of the tab for Emergency messages
struct EmergencyBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            Text(message)
                .foregroundColor(.white)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.red)
    }
}
