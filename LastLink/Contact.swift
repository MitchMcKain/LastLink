//
//  Contact.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/16/26.

import Foundation

// Makes it easier to use in multiple files when declared outside
struct Contact: Identifiable, Hashable {
    let name: String
    let nodeID: String
    
    var id: String{ nodeID }
}

extension Contact {
    static let emergencyBroadcast = Contact(name: "Emergency Broadcast", nodeID: "BROADCAST")
}
