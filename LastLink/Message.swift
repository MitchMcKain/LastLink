//
//  Message.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/30/26.
//

import Foundation

struct Message: Identifiable{ // Text message information
    let id = UUID()
    let text: String
    let sender: String
    let timestamp: Date
}
