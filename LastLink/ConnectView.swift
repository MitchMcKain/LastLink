//
//  ConnectView.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/10/26.
//
import SwiftUI
import CoreBluetooth

struct ConnectView: View {
    
    @ObservedObject var bluetooth: BluetoothManager  // @ObservedObject because ContentView owns it
    
    var body: some View {
        VStack {
            if bluetooth.isAuthorized {
                Text("Bluetooth is ready")
                    .foregroundColor(.green)
                    .padding()
            } else {
                Text("Bluetooth is not available.")
                    .padding()
            }
            
            if !bluetooth.isConnected {
                Button(bluetooth.isScanning ? "Scanning..." : "Scan for Devices") {
                    if bluetooth.isScanning {
                        bluetooth.stopScanning()
                    } else {
                        bluetooth.startScanning()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(bluetooth.isScanning ? .gray : .green)
                .disabled(!bluetooth.isAuthorized)
                
                List(bluetooth.discoveredDevices, id: \.identifier) { device in
                    let name = bluetooth.deviceNames[device.identifier] ?? "Unknown Device"
                    Button(name) {
                        bluetooth.stopScanning()
                        bluetooth.connect(to: device)
                    }
                }
            } else {
                Text("Connected!")
                    .foregroundColor(.green)
                    .padding()
                
                Button("Disconnect") {
                    bluetooth.disconnect()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .padding()
            }
        }
        .toolbarBackground(Color.yellow, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}
