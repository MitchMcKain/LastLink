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
    
    let contacts: [Contact] = [
        Contact(name: "General Broadcast")
    ]
    
    var body: some View {
        NavigationStack {
            List(contacts) { contact in
                NavigationLink(destination: ConversationView(
                    contact: contact,
                    userName: userName,
                    bluetooth: bluetooth  // pass it along to ConversationView
                )) {
                    HStack {
                        Text(contact.name)
                        Spacer()
                        // Show node connection status next to the contact
                        Circle()
                            .fill(bluetooth.isConnected ? Color.green : Color.red)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .navigationTitle("Contacts")
        }
        .toolbarBackground(Color.yellow, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
