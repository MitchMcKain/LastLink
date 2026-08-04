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
        ZStack {
            NavigationStack {
                TabView(selection: $selection) {
                    MessagesView(userName: userName, bluetooth: bluetooth)
                        .tabItem { Label("Messages", systemImage: "message") }
                        .tag(AppTab.messages)

                    ConnectView(bluetooth: bluetooth)
                        .tabItem { Label("Connect", systemImage: "wifi") }
                        .tag(AppTab.connect)

                    StatusView(bluetooth: bluetooth)
                        .tabItem { Label("Status", systemImage: "antenna.radiowaves.left.and.right") }
                        .tag(AppTab.status)
                }
                .onAppear {
                    if let savedName = UserDefaults.standard.string(forKey: "userName") {
                        userName = savedName
                    }
                }
                .onChange(of: userName) { oldValue, newValue in
                    bluetooth.setUserName(newValue)
                }
                .navigationTitle("Last Link")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.yellow, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .sheet(isPresented: $showWelcome) {
                    WelcomeView(userName: $userName, isPresented: $showWelcome, bluetooth: bluetooth)
                        .interactiveDismissDisabled(true)
                }
            }

            if bluetooth.showInactivityWarning {
                InactivityWarningOverlay {
                    bluetooth.stayConnected()
                }
            }
        }
    }
}

struct InactivityWarningOverlay: View {
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Do you still require connection?")
                    .font(.headline)
                Text("You'll be disconnected in 10 seconds otherwise.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)

                Button("Yes!") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(40)
        }
        .transition(.opacity)
        .zIndex(1)
    }
}

#Preview {
    ContentView()
}
