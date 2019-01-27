import Foundation
import CoreBluetooth

protocol BLEDelegate {
    func bleDidUpdateState(central: CBCentralManager!)
    func bleDidConnectToPeripheral()
    func bleDidDisconenctFromPeripheral()
    func bleDidReceiveData(data: Data?)
    func peripheralFound(peripheral : CBPeripheral!)
}

class BLE: NSObject {
    
    let RBL_SERVICE_UUID = "A136FCCA-B028-AACA-B2F1-BC93F23E53C7"
    let RBL_CHAR_TX_UUID = "713D0002-503E-4C75-BA94-3148F18D941E"
    let RBL_CHAR_RX_UUID = "713D0003-503E-4C75-BA94-3148F18D941E"
    
    var delegate: BLEDelegate?
    
    private      var centralManager:   CBCentralManager!
    private      var activePeripheral: CBPeripheral?
    private      var characteristics = [String : CBCharacteristic]()
    private      var data:             NSMutableData?
    private(set) var peripherals     = [CBPeripheral]()
    private      var RSSICompletionHandler: ((NSNumber?, Error?) -> ())?
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.data = NSMutableData()
        
    }
    
    @objc func scanTimeout() {
        
        print("[DEBUG] Scanning stopped")
        self.centralManager.stopScan()
        //println(self.peripherals.count)
    }
    
    func initialScan() {
        self.startScanning(timeout: 0)
    }
    
    // MARK: Public methods
    func startScanning(timeout: Double) {
        
        if self.centralManager.state != .poweredOn {
            
            print("[ERROR] Couldn´t start scanning")
            return
        }
        
        print("[DEBUG] Scanning started")
        
        // CBCentralManagerScanOptionAllowDuplicatesKey
        
        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(scanTimeout), userInfo: nil, repeats: false)
        
        let services = [CBUUID(string: RBL_SERVICE_UUID)]
        self.centralManager.scanForPeripherals(withServices: services, options: nil)
        
    }
    
    func connectToPeripheral(peripheral: CBPeripheral) -> Bool {
        
        if self.centralManager.state != .poweredOn {
            
            print("[ERROR] Couldn´t connect to peripheral")
            return false
        }
        
        print("[DEBUG] Connecting to peripheral: \(peripheral.identifier.uuidString)")
        
        self.centralManager.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : NSNumber(value: true)])
        
        return true
    }
    
    func disconnectFromPeripheral(peripheral: CBPeripheral) -> Bool {
        
        if self.centralManager.state != .poweredOn {
            
            print("[ERROR] Couldn´t disconnect from peripheral")
            return false
        }
        
        self.centralManager.cancelPeripheralConnection(peripheral)
        
        return true
    }
    
    func read() {
        
        self.activePeripheral?.readValue(for: self.characteristics[RBL_CHAR_TX_UUID]!)
    }
    
    func write(_ data: Data) {
        self.activePeripheral?.writeValue(data, for: self.characteristics[RBL_CHAR_RX_UUID]!, type: .withoutResponse)
    }
    
    func enableNotifications(enable: Bool) {
        
        self.activePeripheral?.setNotifyValue(enable, for: self.characteristics[RBL_CHAR_TX_UUID]!)
    }
    
    func readRSSI(completion: @escaping (NSNumber?, Error?) -> ()) {
        
        self.RSSICompletionHandler = completion
        self.activePeripheral?.readRSSI()
    }
}

extension BLE: CBCentralManagerDelegate {
    
    // MARK: CBCentralManager delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("[DEBUG] Central manager state: Unknown")
            break
            
        case .resetting:
            print("[DEBUG] Central manager state: Resseting")
            break
            
        case .unsupported:
            print("[DEBUG] Central manager state: Unsupported")
            break
            
        case .unauthorized:
            print("[DEBUG] Central manager state: Unauthorized")
            break
            
        case .poweredOff:
            print("[DEBUG] Central manager state: Powered off")
            break
            
        case .poweredOn:
            print("[DEBUG] Central manager state: Powered on")
            break
        }
        
        self.delegate?.bleDidUpdateState(central: central)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("[DEBUG] Find peripheral: \(peripheral.identifier.uuidString) RSSI: \(RSSI)")
        
        if !self.peripherals.contains(where: { $0.identifier.uuidString == peripheral.identifier.uuidString}) {
            self.peripherals.append(peripheral)
        }
        self.delegate!.peripheralFound(peripheral: peripheral)
        
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[ERROR] Could not connect to peripheral \(peripheral.identifier.uuidString) error: \(error.debugDescription)")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[DEBUG] Connected to peripheral \(peripheral.identifier.uuidString)")
        
        self.activePeripheral = peripheral
        
        self.activePeripheral?.delegate = self
        self.activePeripheral?.discoverServices(nil)
        
        //self.delegate?.bleDidConnectToPeripheral()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        var text = "[DEBUG] Disconnected from peripheral: \(peripheral.identifier.uuidString)"
        
        if error != nil {
            text += ". Error: \(error.debugDescription)"
        }
        
        print(text)
        
        self.activePeripheral?.delegate = nil
        self.activePeripheral = nil
        self.characteristics.removeAll(keepingCapacity: false)
        
        self.delegate?.bleDidDisconenctFromPeripheral()
    }
}

extension BLE: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("[ERROR] Error discovering services. \(error.debugDescription)")
            return
        }
        
        print("[DEBUG] Found services for peripheral: \(peripheral.identifier.uuidString)")
        
        for service in peripheral.services! {
            
            let theCharacteristics = [CBUUID(string: RBL_CHAR_RX_UUID), CBUUID(string: RBL_CHAR_TX_UUID)]
            
            peripheral.discoverCharacteristics(theCharacteristics, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(error.debugDescription)")
            return
        }
        
        print("[DEBUG] Found characteristics for peripheral: \(peripheral.identifier.uuidString)")
        
        if let foundCharacteristics = service.characteristics {
            for characteristic in foundCharacteristics {
                self.characteristics[characteristic.uuid.uuidString] = characteristic
            }
        }
        
        enableNotifications(enable: true)
        self.delegate!.bleDidConnectToPeripheral()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            
            print("[ERROR] Error updating value. \(error.debugDescription)")
            return
        }
        
        if characteristic.uuid.uuidString == RBL_CHAR_TX_UUID {
            
            self.delegate?.bleDidReceiveData(data:characteristic.value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.RSSICompletionHandler?(RSSI, error)
        self.RSSICompletionHandler = nil
    }
}
