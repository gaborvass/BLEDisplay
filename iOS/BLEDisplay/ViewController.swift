//
//  ViewController.swift
//  BLEDisplay
//
//  Created by Vass, Gabor on 28/08/15.
//  Copyright (c) 2015 Gabor, Vass. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, BLEDelegate {
    @IBOutlet weak var statusLabel: UILabel!

    
    
    var bleManager : BLE = BLE()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        bleManager.delegate = self
        // TODO: only for demo
        //self.prepareForMessageSending()
    }

    
    func prepareForMessageSending() {
        NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: "sendMessage", userInfo: nil, repeats: true)
    }
    
    func sendMessage() {
        var msg : String = String()

        let date = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components(.CalendarUnitHour | .CalendarUnitMinute | .CalendarUnitSecond, fromDate: date)
        let hour = components.hour
        let minutes = components.minute
        let seconds = components.second
        
        self.bleManager.write(data: NSString(string: "\(hour):\(minutes):\(seconds)x").dataUsingEncoding(NSUTF8StringEncoding)!)
        println("\(hour):\(minutes):\(seconds)x")
    }
    
    
    @IBAction func tryToConnect(sender: AnyObject) {
        
    }
    
// MARK: - BLEDelegate implementation

    func peripheralFound(peripheral : CBPeripheral!){
        if peripheral.identifier.UUIDString == "A136FCCA-B028-AACA-B2F1-BC93F23E53C7" {
            self.statusLabel.text = "Found"
            self.bleManager.connectToPeripheral(peripheral)
        }
        
    }
    
    func bleDidUpdateState(central: CBCentralManager!) {
        if(central.state == .PoweredOn) {
            self.bleManager.startScanning(100)
        }
    }
    
    func bleDidConnectToPeripheral() {
        println("bleDidConnectToPeripheral")
        self.statusLabel.text = "Connected"
        self.prepareForMessageSending()
    }
    
    
    func bleDidDisconenctFromPeripheral() {
        self.statusLabel.text = "Disconnected"
        println("bleDidDisconenctFromPeripheral")
    }
    
    func bleDidReceiveData(data: NSData?) {
        println("bleDidReceiveData")
    }
    
    
}

