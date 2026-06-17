//
//  StatusView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

import SwiftUI

// Enum makes it clean to work with later — no typos, easy to switch on
enum NodeStatus {
    case online, offline
}

// Identifiable struct for each row
struct Node: Identifiable {
    let id = UUID()
    let name: String
    var status: NodeStatus   // var because this will change when bluetooth updates it
}

struct StatusView: View {
    
    // @State because these values will change when bluetooth data comes in
    @State private var nodes: [Node] = [
        Node(name: "Alpha", status: .online),
        Node(name: "Bravo", status: .online),
        Node(name: "Charlie", status: .offline),
        Node(name: "Delta", status: .online)
    ]
    
    var body: some View {
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
            }
            .padding()
            .background(Color.yellow.opacity(0.8))
            
            Divider()
            
            // Data rows
            ForEach(nodes) { node in
                HStack {
                    Text(node.name)
                        .frame(maxWidth: .infinity)
                    
                    // Status cell changes color based on value
                    Text(node.status == .online ? "Online" : "Offline")
                        .foregroundColor(node.status == .online ? .green : .red)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                
                Divider()
            }
            
//            Spacer()
        }
        .toolbarBackground(Color.yellow, for: .navigationBar)  // add these
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
