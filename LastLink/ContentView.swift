//
//  ContentView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/8/26.
//
import SwiftUI

// Define the possible tab options as an enum
enum AppTab {
    case login, messages, connect, status
}

struct ContentView: View {

    // @State lives inside the struct; the $ prefix when used passes a "binding" (two-way connection)
    @State private var selection: AppTab = .connect // Begin with the Connect tab
    @State private var userName: String = ""
    @State private var showWelcome: Bool = true
    @StateObject private var bluetooth = BluetoothManager() // Instance of BluetoothManager so that it can be used everywhere else

    
    var body: some View {
        NavigationStack{
            TabView(selection: $selection) {
                
                // Messages tab navigation
                MessagesView(userName: userName, bluetooth: bluetooth)
                    .tabItem { Label("Messages", systemImage: "message") }
                    .tag(AppTab.messages)   // .tag() is how TabView knows which tab is which
                
                // Connect tab navigation
                ConnectView(bluetooth: bluetooth)
                    .tabItem { Label("Connect", systemImage: "wifi") }
                    .tag(AppTab.connect)   // .tag() is how TabView knows which tab is which
                
                // Status tab navigation
                StatusView()
                    .tabItem { Label("Status", systemImage: "antenna.radiowaves.left.and.right") }
                    .tag(AppTab.status)
                
            }
            .onAppear {
                // If a name was previously saved, load it automatically
                if let savedName = UserDefaults.standard.string(forKey: "userName") {
                    userName = savedName
                }
            }
            .onChange(of: userName)  { oldValue, newValue in
                    bluetooth.setUserName(newValue)
                }
            
            .navigationTitle("Last Link")
            .navigationBarTitleDisplayMode(.inline)  // Center title on one line
            .toolbarBackground(Color.yellow, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            
            // Welcome screen as pop-up
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
