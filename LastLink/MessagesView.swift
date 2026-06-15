//
//  MessagesView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

import SwiftUI

struct Contact: Identifiable {
    let id = UUID()
    let name: String
}

struct MessagesView: View {
    
    @State private var messageInput = ""
    let userName: String
    
    let contacts: [Contact] = [
        Contact(name: "General Broadcast"),
        Contact(name: "Cole"),
        Contact(name: "Ben")
    ]
    
    var body: some View {
//        VStack {
//            Text("You appear to others as \"\(userName)\"")
//                .padding()
//            Text("Type Message Here:")
//            
//            TextField("Type here...", text: $messageInput)
//                .textFieldStyle(.roundedBorder)
//                .keyboardType(.default)
//                .textInputAutocapitalization(.never)
//            
//            Button("Send") {
//                print("Message Sent!")
//            }
//            .disabled(messageInput.isEmpty)
//            .tint(.yellow)
//            .buttonStyle(.borderedProminent)
//            
//            Spacer()// pushes everything above it to the top
//        }
        NavigationStack {
            Text("You are appearing as \"\(userName)\"")
                .padding()
            
            List(contacts) { contact in
                NavigationLink(destination: ConversationView(contact: contact, userName: userName)){
                    Text(contact.name)
                }
            }
            .navigationTitle("Contacts")
        }
    }
}
