//
//  WelcomeView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

import SwiftUI

struct WelcomeView: View {
    
    @Binding var userName: String
    @Binding var isPresented: Bool       // Controls whether the sheet is showing
    @ObservedObject var bluetooth: BluetoothManager
    
    @State private var nameInput: String = ""   // Temporary holder while user types
    @State private var showNameField: Bool = false
    
    @State private var showEMSField: Bool = false
    @State private var emsPasswordInput: String = ""
    @State private var emsError: Bool = false
    
    // Recall the user's name from previous instance
    let savedName: String? = UserDefaults.standard.string(forKey: "userName")
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            Text("Welcome to Last Link!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if showEMSField {
                Text("Emergency Service Sign-In")
                    .foregroundColor(.gray)
                
                SecureField("Password", text: $emsPasswordInput)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                
                if emsError {
                    Text("Incorrect password")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button("Sign In") {
                    if bluetooth.authenticateEMS(password: emsPasswordInput) {
                        userName = "Pittsburgh EMS"
                        isPresented = false
                    } else {
                        emsError = true
                        emsPasswordInput = ""
                    }
                }
                .disabled(emsPasswordInput.isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(.red)
                
                Button("Cancel") {
                    showEMSField = false
                    emsPasswordInput = ""
                    emsError = false
                }
                .buttonStyle(.bordered)
                .tint(.gray)
            }
            else if let name = savedName, !showNameField {
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
                
                Button("Sign in as Emergency Service") {
                    showEMSField = true
                }
                .buttonStyle(.bordered)
                .tint(.red)
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
                        UserDefaults.standard.set(nameInput, forKey: "userName")  // Save username to device
                        isPresented = false
                    }
                }
                .disabled(nameInput.isEmpty) // Button is greyed out until they type something
                .buttonStyle(.borderedProminent)
                .tint(.yellow)
                
                Button("Sign in as Emergency Service") {
                    showEMSField = true
                    userName = "Pittsburgh EMS"
                    UserDefaults.standard.set(nameInput, forKey: "userName")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            
            Spacer()
        }
    }
}
