//
//  BluetoothManager.swift
//  LastLink
//
//  Created by McKain, Mitch T on 6/10/26.
//

import Foundation
import CoreBluetooth
import Combine

class BluetoothManager: NSObject, ObservableObject {
    
    private var centralManager: CBCentralManager! // This acts as user's device
    private var connectedPeripheral: CBPeripheral? // This will be the ESP32
    private var writeCharacteristic: CBCharacteristic?
    
    let targetServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") // Fixed service UUID for iPad peripheral
    let targetCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // Fixed characteristic UUID for iPad peripheral
    let targetNotifyUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // TX from ESP32's perspective
    
    // Variables for connection process
    @Published var isAuthorized: Bool = false
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var deviceNames: [UUID: String] = [:]
    @Published var messages: [Message] = []
    @Published var emergencyMessage: String? = "Evacuate ASAP"
    @Published var nodeRoutingTable: [String: String] = [
        "C": "Cole"
        // add more as you learn which node maps to which person
    ]
//    @Published var contacts: [Contact] = []
//    @Published var conversations: [String: [Message]] = [:]  // keyed by nodeID

//    private func resolveSender(for nodeID: String?) -> String {
//        guard let nodeID = nodeID else { return "Unknown Node" }
//        return nodeRoutingTable[nodeID] ?? "Node \(nodeID)"
//    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // Scanning function for finding nearby devices
    func startScanning() {
        discoveredDevices = []
        deviceNames = [:]
        centralManager.scanForPeripherals(
            withServices: nil,    // scan for everything
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        isScanning = true
        print("Scanning for all devices...")
    }
    
    // Stop scanning function to stop looking for new devices
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    // Connect function to connect to the selected peripheral in list
    func connect(to peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        print("Attempting to connect to \(peripheral.name ?? "unknown")")
    }
    
    
    // Disconnect function to disconnect from peripheral
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // Send Message function, same message as ConversationView message
    func sendMessage(_ message: String, sender: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = message.data(using: .utf8) else {
            print("Not ready to send")
            return
        }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)

        let outgoing = Message(text: message, sender: sender, timestamp: Date())
        messages.append(outgoing)
        print("Sent: \(message)")
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    // Ensure that permission has been granted
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            isAuthorized = true
        case .unauthorized:
            isAuthorized = false
        case .poweredOff:
            isAuthorized = false
        default:
            isAuthorized = false
        }
    }
    
    // Function for adding a device to the list once its discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        var deviceName = peripheral.name
        if deviceName == nil {
            if let nsName = advertisementData[CBAdvertisementDataLocalNameKey] as? NSString {
                deviceName = String(nsName)
            }
        }
        
        // Store whatever name we have
        deviceNames[peripheral.identifier] = deviceName ?? "Unknown"
        
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
            print("Found: \(deviceName ?? "unnamed") | \(peripheral.identifier)")
        }
    }
    // Handle connceting to a peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect fired")
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("discoverServices called")
    }
    
    // Handle failing to connect to a peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
    }
    
    // Handle disconencting from a peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        writeCharacteristic = nil    // clear this on disconnect
        print("Disconnected from \(peripheral.name ?? "unknown")")
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
    // Handle discovering the services that the connected peripheral has
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // Handle discovering the characterisitics that the conneted peripheral has
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")

            if characteristic.uuid == targetCharacteristicUUID {
                writeCharacteristic = characteristic
                print("Write characteristic found, ready to send!")
            }

            if characteristic.uuid == targetNotifyUUID {
                peripheral.setNotifyValue(true, for: characteristic)
                print("Subscribing to notifications on \(characteristic.uuid)")
            }
        }
    }
    
    // Confirm message is received by peripheral
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Write failed: \(error.localizedDescription)")
        } else {
            print("Write confirmed by peripheral")
        }
    }
    
    // Read in message that was sent and is availabl on ESP32
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value,
              let text = String(data: data, encoding: .utf8) else {
            print("Failed to decode incoming data")
            return
        }

        if text.hasPrefix("EMERGENCY:") {
            let alertText = text.replacingOccurrences(of: "EMERGENCY:", with: "").trimmingCharacters(in: .whitespaces)
            emergencyMessage = alertText
            print("Emergency received: \(alertText)")
            return   // don't also treat this as a normal chat message
        }

        let parseResult = parseIncoming(text)
        let incoming = Message(text: parseResult.text, sender: "Node", timestamp: Date())
        messages.append(incoming)
        print("Received: \(parseResult.text)")
    }
}

    // Splits "C: Hello" into ("C", "Hello"). Falls back to (nil, original text) if no prefix found.
    private func parseIncoming(_ raw: String) -> (nodeID: String?, text: String) {
        guard let colonIndex = raw.firstIndex(of: ":") else {
            return (nil, raw)
        }
        let prefix = raw[raw.startIndex..<colonIndex].trimmingCharacters(in: .whitespaces)
        let remainder = raw[raw.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)
        // Basic sanity check: only treat as a node prefix if it's short (e.g. single letter/word)
        guard prefix.count <= 3 else {
            return (nil, raw)
        }
        return (prefix, remainder)
    }
