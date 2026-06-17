//
//  Contact.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/16/26.

import Foundation

// Makes it easier to use in multiple files when declared outside
struct Contact: Identifiable {
    let id = UUID()
    let name: String
}
