//
//  Message.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/30/26.
//

import Foundation

enum MessageStatus {
    case sent, delivered
}

struct Message: Identifiable{ // Text message information
    let id = UUID()
    let text: String
    let sender: String
    let timestamp: Date
    var status: MessageStatus = .sent
    var firmwareID: Int?
    var conversationID: String
}
