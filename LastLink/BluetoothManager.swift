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
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    
    let targetServiceUUID = CBUUID(string: "1111")
    let targetCharacteristicUUID = CBUUID(string: "2222")
    
    @Published var isAuthorized: Bool = false
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var deviceNames: [UUID: String] = [:]
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
//    func startScanning() {
//        discoveredDevices = []
//        deviceNames = [:]
//        let serviceUUID = CBUUID(string: "1111")
//        centralManager.scanForPeripherals(
//            withServices: [serviceUUID],
//            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
//        )
//        isScanning = true
//        print("Scanning for Last Link Node...")
//    }
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
    
    func stopScanning() {
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        print("Attempting to connect to \(peripheral.name ?? "unknown")")
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // sendMessage belongs here in the main class, not inside an extension
    func sendMessage(_ message: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = message.data(using: .utf8) else {
            print("Not ready to send")
            return
        }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
        print("Sent: \(message)")
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    
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
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect fired")
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("discoverServices called")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        writeCharacteristic = nil    // clear this on disconnect
        print("Disconnected from \(peripheral.name ?? "unknown")")
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            print("Discovered service: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            print("Discovered characteristic: \(characteristic.uuid)")
            
            // This was missing — store the characteristic so sendMessage can use it
            if characteristic.uuid == targetCharacteristicUUID {
                writeCharacteristic = characteristic
                print("Write characteristic found, ready to send!")
            }
        }
    }
    
    // This was missing — confirms message was received by peripheral
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Write failed: \(error.localizedDescription)")
        } else {
            print("Write confirmed by peripheral")
        }
    }
}
