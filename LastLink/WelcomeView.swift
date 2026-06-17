//
//  WelcomeView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

import SwiftUI

struct WelcomeView: View {
    
    @Binding var userName: String        // Binding means this value is owned elsewhere, we just write to it
    @Binding var isPresented: Bool       // controls whether the sheet is showing
    
    @State private var nameInput: String = ""   // temporary holder while they type
    @State private var showNameField: Bool = false
    
    // Recall the user's name from previous instance
    let savedName: String? = UserDefaults.standard.string(forKey: "userName")
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            Text("Welcome to Last Link!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let name = savedName, !showNameField {
                Text("Welcome back, \(name)!")
                    .foregroundColor(.gray)
                
                Button("Continue as, \(name)"){
                    userName = name
                    isPresented = false
                }
                    .buttonStyle(.borderedProminent)
                    .tint(.yellow)
                
                Button("New User"){
                    showNameField = true
                }
                    .buttonStyle(.borderedProminent)
                    .tint(.gray)
            }
            else{
                Text("Enter your display name to get started")
                    .foregroundColor(.gray)
                
                TextField("Display name", text: $nameInput) // Space where user enters their name
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                
                Button("Continue") {
                    if !nameInput.isEmpty {
                        userName = nameInput
                        UserDefaults.standard.set(nameInput, forKey: "userName")  // save username to device
                        isPresented = false
                    }
                }
                .disabled(nameInput.isEmpty) // button is greyed out until they type something
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
            }
            
            Spacer()
        }
    }
}
