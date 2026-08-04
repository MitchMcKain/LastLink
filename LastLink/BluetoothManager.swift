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
    private var hasAnnouncedPresence = false
    private var pendingMessageID: UUID?
    private var emsPassword = "ece412"
    private var pendingTableRequest = false
    private var tableRequestRetries = 0
    private let maxTableRequestRetries = 3
    
    // Variables for monitoring user activity
    @Published var showInactivityWarning = false
    private var lastActivityDate = Date()
    private var inactivityTimer: Timer?
    private let inactivityThreshold: TimeInterval = 60
    private let responseGracePeriod: TimeInterval = 10

    let targetCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // Fixed characteristic UUID for iPad peripheral
    let targetNotifyUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // TX from ESP32's perspective
    
    // Variables that can be accessed by other files
    @Published var myUserName: String? = nil
    @Published var isAuthorized: Bool = false
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false
    @Published var discoveredDevices: [CBPeripheral] = []
    @Published var deviceNames: [UUID: String] = [:]
    @Published var messages: [Message] = []
    @Published var myNodeID: String? = nil
    @Published var emergencyMessage: String? = nil
    @Published var nodeRoutingTable: [String: String] = [:]
    @Published var lastAckedMessageID: UUID?
    @Published var onlineNodeIDs: Set<String> = []
    @Published var isEMSAuthenticated: Bool = false
    
    var contacts: [Contact] {
        nodeRoutingTable
            .filter { $0.key != myNodeID } // Do not display yourself as a contact
            .map { nodeID, name in
                Contact(name: name, nodeID: nodeID)
            }
    }
    
    var visibleContacts: [Contact] {
        isEMSAuthenticated ? contacts + [Contact.emergencyBroadcast] : contacts
    }
    
    
    let knownNodeIDs: [String] = ["A", "B", "C"]
    
    var nodeStatusList: [NodeStatusInfo] {
        knownNodeIDs.map { nodeID in
            let userName = nodeRoutingTable[nodeID] ?? "N/A"
            let isOnline = onlineNodeIDs.contains(nodeID)
            return NodeStatusInfo(id: nodeID, userName: userName, isOnline: isOnline)
        }
        .sorted { $0.id < $1.id }
    }
    
    struct NodeStatusInfo: Identifiable {
        let id: String
        let userName: String
        let isOnline: Bool
    }
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    private func recordActivity() {
        lastActivityDate = Date()
        if showInactivityWarning {
            showInactivityWarning = false
        }
    }
    
    func stayConnected() {
        recordActivity()
    }
    
    private func startInactivityMonitor() {
        inactivityTimer?.invalidate()
        lastActivityDate = Date()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkInactivity()
        }
    }
    
    private func stopInactivityMonitor() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        showInactivityWarning = false
    }
    
    private func checkInactivity() {
        guard isConnected else { return }
        let elapsed = Date().timeIntervalSince(lastActivityDate)
        if elapsed >= inactivityThreshold + responseGracePeriod {
            print("No response to inactivity warning, disconnecting")
            DispatchQueue.main.async {
                self.disconnect()
            }
        } else if elapsed >= inactivityThreshold {
            DispatchQueue.main.async {
                self.showInactivityWarning = true
            }
        }
    }
    
    private func extractStringID(from text: String) -> String? {
        for token in text.split(separator: " ") {
            if token.hasPrefix("id=") {
                return String(token.dropFirst(3))
            }
        }
        return nil
    }
    
    private func handleNodesTable(_ text: String) {
        // "[NODES] A:A:0,C:C:1" — first field of each entry is a reachable destination
        // Extract the active nodes from message
        guard let payload = text.split(separator: " ", maxSplits: 1).last else { return }
        let destinations = payload.split(separator: ",").compactMap { entry -> String? in
            entry.split(separator: ":").first.map(String.init)
        }
        print("Destins: \(destinations)")
        // Toggle online nodes to online
        for node in destinations {
            handleNodeOnline(id: node)
        }
    }
    
    private func handleNodeOnline(id: String) {
        onlineNodeIDs.insert(id)
        print("updated online node...")
        print(onlineNodeIDs)
    }
    
    private func handleNodeOffline(id: String) {
        onlineNodeIDs.remove(id)
        print("updated online node...")
        print(onlineNodeIDs)
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
        announceDisconnect()
        guard let peripheral = connectedPeripheral else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.centralManager.cancelPeripheralConnection(peripheral)
            }
    }
    
    // Send Message function, same message as ConversationView message
    func sendMessage(_ message: String, sender: String, destination: String) {
        recordActivity()
        guard message.count <= 200 else {
                print("Message exceeds 200 character limit — not sent")
                return
            }
        let outgoingMessage = "@\(destination) \(message)"
        
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = outgoingMessage.data(using: .utf8) else {
            print("Not ready to send")
            return
        }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)

        let outgoing = Message(text: message, sender: sender, timestamp: Date(), conversationID: destination)
        pendingMessageID = outgoing.id
        messages.append(outgoing)
        print("Sent to \(destination): \(message)")
    }
    
    private func handleAck() {
        guard let id = pendingMessageID else { return }
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages[index].status = .delivered
        }
        pendingMessageID = nil
    }
    
    func authenticateEMS(password: String) -> Bool {
        if password == emsPassword {
            isEMSAuthenticated = true
            return true
        }
        return false
    }

    func sendEmergencyBroadcast(_ message: String, sender: String) {
        guard message.count <= 200 else {
            print("Message exceeds 200 character limit — not sent")
            return
        }
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = "EMERGENCY:\(message)".data(using: .utf8) else {
            print("Not ready to send")
            return
        }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)

        let outgoing = Message(text: message, sender: sender, timestamp: Date(), conversationID: "BROADCAST")
        messages.append(outgoing)
        print("Emergency broadcast sent: \(message)")
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
        
        // Only care about our own devices — filters out everything that isn't "LastLink-X"
        guard let name = deviceName, name.hasPrefix("LastLink-") else {
            return
        }
        
        deviceNames[peripheral.identifier] = name
        
        if !discoveredDevices.contains(peripheral) {
            discoveredDevices.append(peripheral)
            print("Found: \(name) | \(peripheral.identifier)")
        }
    }
    
    // Handle connceting to a peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("didConnect fired")
        isConnected = true
        myNodeID = extractNodeID(from: peripheral.name)
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        startInactivityMonitor()
        print("discoverServices called, myNodeID = \(myNodeID ?? "nil")")
    }
    
    // Handle failing to connect to a peripheral
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        connectedPeripheral = nil
        print("Failed to connect: \(error?.localizedDescription ?? "unknown error")")
    }
    
    // Handle disconencting from a peripheral
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeripheral = nil
            self.writeCharacteristic = nil
            self.hasAnnouncedPresence = false
            self.nodeRoutingTable.removeAll()
            self.stopInactivityMonitor()
            print("Disconnected from \(peripheral.name ?? "unknown")")
        }
    }
    
    private func extractNodeID(from peripheralName: String?) -> String? {
        guard let name = peripheralName, name.hasPrefix("LastLink-") else { return nil }
        return String(name.dropFirst("LastLink-".count))
    }
    
    func setUserName(_ name: String) {
        myUserName = name
    }
    
    func requestRoutingTable() {
        guard let nodeID = myNodeID,
              let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = "REQUEST:\(nodeID)".data(using: .utf8) else {
            print("Not ready to request")
            return
        }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            peripheral.writeValue(data, for: characteristic, type: writeType)
            self.pendingTableRequest = true
            print("requested RT (attempt \(self.tableRequestRetries + 1))")
            self.scheduleTableRequestTimeout()
        }
    }
    
    private func scheduleTableRequestTimeout() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            guard let self = self, self.pendingTableRequest else { return }  // TABLE already arrived, nothing to do

            guard self.tableRequestRetries < self.maxTableRequestRetries else {
                print("Routing table request failed after \(self.maxTableRequestRetries) attempts")
                self.pendingTableRequest = false
                self.tableRequestRetries = 0
                return
            }

            self.tableRequestRetries += 1
            self.requestRoutingTable()
        }
    }
    
    func sendRoutingTable() {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic else {
            print("Not ready to send routing table")
            return
        }
        let encoded = nodeRoutingTable.map { "\($0.key)=\($0.value)" }.joined(separator: ",")
        guard let data = "TABLE:\(encoded)".data(using: .utf8) else { return }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            peripheral.writeValue(data, for: characteristic, type: writeType)
        }
        print("Sent routing table: \(encoded)")
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
        announceIfReady()
    }
    
    // Confirm message is received by peripheral
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Write failed: \(error.localizedDescription)")
        } else {
            print("Write confirmed by peripheral")
        }
    }
    
    // Read in message that was sent and is available on ESP32
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil, let data = characteristic.value,
              let text = String(data: data, encoding: .utf8) else {
            print("Failed to decode incoming data")
            return
        }
        
        print("Raw: \(text)")
        
        let parseResult = parseIncoming(text)
        let appText = parseResult.text
        
        print("")

        // If message is an Emergency message
        if appText.hasPrefix("EMERGENCY:") {
            let alertText = appText.replacingOccurrences(of: "EMERGENCY:", with: "").trimmingCharacters(in: .whitespaces)
            emergencyMessage = alertText
            print("Emergency received: \(alertText)")
            return   // don't also treat this as a normal chat message
        }
        
        if appText.hasPrefix("[ACK]") {
            handleAck()
            return
        }
        
        if appText.hasPrefix("[NODES]") {
            handleNodesTable(appText)
        }
        
        if appText.hasPrefix("[NODE+]") {
            print("adding a node...")
            guard let nodeID = extractStringID(from: text) else { return }
            print("still adding a node")
            handleNodeOnline(id: nodeID)
        }
        
        if appText.hasPrefix("[NODE-]") {
            print("removing a node...")
            guard let nodeID = extractStringID(from: text) else { return }
            print("still removing")
            handleNodeOffline(id: nodeID)
        }
            
        
        if appText.hasPrefix("[") {
            print("Ignored firmware message: \(appText)")
            return
        }
        
        // If message is a presence announcement...
        if appText.hasPrefix("PRESENCE:") {
            let parts = appText.dropFirst("PRESENCE:".count).split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else {
                print("Malformed presence message: \(appText)")
                return
            }
            let name = String(parts[0])
            let nodeID = String(parts[1])
            handlePresence(nodeID: nodeID, name: name)
            return
        }
        
        // If message is a routing table...
        if appText.hasPrefix("TABLE:") {
            print("recieved a routing table")
            let encoded = appText.dropFirst("TABLE:".count)
            let pairs = encoded.split(separator: ",")
            for pair in pairs {
                let kv = pair.split(separator: "=", maxSplits: 1)
                guard kv.count == 2 else { continue }
                let nodeID = String(kv[0])
                let name = String(kv[1])
                handlePresence(nodeID: nodeID, name: name)
            }
            pendingTableRequest = false
            tableRequestRetries = 0
            return
        }
                
        // If message is a request for the routing table...
        if appText.hasPrefix("REQUEST:") {
            print("Received routing table request")
            sendRoutingTable()
            return
        }
        
        if appText.hasPrefix("DISCONNECT:") {
            let nodeID = String(appText.dropFirst("DISCONNECT:".count))
            handleDisconnect(nodeID: nodeID)
            return
        }

        recordActivity() // may not fire?
        let incoming = Message(text: appText, sender: "Node", timestamp: Date(), conversationID: parseResult.nodeID ?? "Unknown")
        messages.append(incoming)
        print("Received: \(appText)")
    }
    
    // Update the routing table
    func handlePresence(nodeID: String, name: String) {
        nodeRoutingTable[nodeID] = name
        print("Presence update: \(name) is at Node \(nodeID)")
        print("Current routing table: \(nodeRoutingTable)")
    }
    
    // Announcing to the node that you are connected to it
    func announcePresence(userName: String) {
        guard let nodeID = myNodeID,
              let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = "PRESENCE:\(userName):\(nodeID)".data(using: .utf8) else {
            print("Not ready to announce presence")
            return
        }
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
        print("Announced presence: \(userName) at \(nodeID)")
        
        handlePresence(nodeID: nodeID, name: userName)
    }
    
    private func announceIfReady() {
        guard writeCharacteristic != nil else {
            print("Write characteristic not ready yet")
            return
        }
        guard let name = myUserName else {
            print("No userName set yet, skipping presence announcement")
            return
        }
        guard !hasAnnouncedPresence else {
            return   // already handled this connection, ignore repeat discovery callbacks
        }
        hasAnnouncedPresence = true
        
        for _ in 1...3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.announcePresence(userName: name)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.requestRoutingTable()
        }
    }
    
    func handleDisconnect(nodeID: String) {
//        print("In handleDisconnect")
        nodeRoutingTable.removeValue(forKey: nodeID)
        print("Node \(nodeID) disconnected, removed from routing table")
    }
    
    func announceDisconnect() {
//        print("In anounceDisconnect")
        guard let nodeID = myNodeID,
              let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              let data = "DISCONNECT:\(nodeID)".data(using: .utf8) else {
            print("Not ready to announce disconnect")
            return
        }
        
        let writeType: CBCharacteristicWriteType = characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
        print("Announced disconnect for node \(nodeID)")
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
