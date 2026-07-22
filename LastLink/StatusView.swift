//
//  StatusView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/10/26.
//

import SwiftUI

struct StatusView: View {
    
    @ObservedObject var bluetooth: BluetoothManager
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("MESH NETWORK OPERATIONAL STATUS")
                    .font(.system(size: 20))
                    .padding()
                
                // Header row
                HStack {
                    Text("Node")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    Text("Status")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    Text("User")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.yellow.opacity(0.8))
                
                Divider()
                
                // Data rows, driven by BluetoothManager.nodeStatusList
                ForEach(bluetooth.nodeStatusList) { node in
                    HStack {
                        Text(node.id)
                            .frame(maxWidth: .infinity)
                        
                        // Status cell changes color based on value
                        Text(node.isOnline ? "Online" : "Offline")
                            .foregroundColor(node.isOnline ? .green : .red)
                            .frame(maxWidth: .infinity)
                        
                        Text(node.userName)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    
                    Divider()
                }
                
    //            Spacer()
            }
            .blur(radius: bluetooth.isConnected ? 0 : 6)
            .disabled(!bluetooth.isConnected)
            
            if !bluetooth.isConnected {
                notConnectedOverlay
            }
        }
        .toolbarBackground(Color.yellow, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    private var notConnectedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
            Text("Not Connected")
                .font(.headline)
            Text("Connect to a node to see who's online.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding()
    }
}
