//
//  ConnectView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/10/26.
//

import SwiftUI

struct ConnectView: View {
    
    // @StateObject owns the BluetoothManager instance for this view
    @StateObject private var bluetooth = BluetoothManager()
    
    var body: some View {
        VStack {
            
            // Show different text depending on authorization state
            if bluetooth.isAuthorized {
                Text("Bluetooth is ready")
                    .foregroundColor(.green)
                    .padding()
            } else {
                Text("You are not connected to a node, please connect to a node.")
                    .padding()
            }
            
            Button("Connect") {
                print("Connecting via Bluetooth...")
            }
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
            .disabled(!bluetooth.isAuthorized)  // greyed out until bluetooth is authorized
        }
    }
}
