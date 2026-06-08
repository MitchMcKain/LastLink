//
//  ContentView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//

import SwiftUI

// Define the possible tab options as an enum
enum AppTab {
    case login, messages, status
}

struct ContentView: View {

    // @State lives inside the struct; the $ prefix when used passes a "binding" (two-way connection)
    @State private var selection: AppTab = .messages
    @State private var userName: String = ""
    @State private var showWelcome: Bool = true
    
    var body: some View {
        NavigationStack{
            TabView(selection: $selection) {
                
                MessagesView(userName: userName)
                    .tabItem { Label("Messages", systemImage: "message") }
                    .tag(AppTab.messages)   // .tag() is how TabView knows which tab is which
                
                StatusView()
                    .tabItem { Label("Status", systemImage: "antenna.radiowaves.left.and.right") }
                    .tag(AppTab.status)
                
            }
            .navigationTitle("Last Link")
            .navigationBarTitleDisplayMode(.inline)  // keeps title centered on one line
            .toolbarBackground(Color.yellow, for: .navigationBar)  // sets the background color
            .toolbarBackground(.visible, for: .navigationBar)
            
            .sheet(isPresented: $showWelcome) {
                WelcomeView(userName: $userName, isPresented: $showWelcome)
                    .interactiveDismissDisabled(true)
            }
        }
    }
}

#Preview {
    ContentView()
}
