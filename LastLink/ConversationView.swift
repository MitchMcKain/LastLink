//
//  ConversationView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

import SwiftUI

struct ConversationView: View {
    
    let contact: Contact
    let userName: String
    
    @State private var messageInput: String = ""
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("Type Message Here:")
            
            TextField("Type here...", text: $messageInput)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.default)
                .textInputAutocapitalization(.never)
                .padding()
            
            Button("Send") {
                print("Message sent to \(contact.name)")
            }
            .disabled(messageInput.isEmpty)
            .tint(.yellow)
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(contact.name)
        .toolbarBackground(Color.yellow, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
