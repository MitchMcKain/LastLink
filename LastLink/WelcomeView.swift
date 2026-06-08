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
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            Text("Welcome to Last Link!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Enter your display name to get started")
                .foregroundColor(.gray)
            
            TextField("Display name", text: $nameInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 40)
            
            Button("Continue") {
                if !nameInput.isEmpty {
                    userName = nameInput      // write the name back to ContentView
                    isPresented = false       // dismiss the sheet
                }
            }
            .disabled(nameInput.isEmpty)     // button is greyed out until they type something
            .buttonStyle(.borderedProminent)
            .tint(.yellow)
            
            Spacer()
        }
    }
}
