//
//  ViewController.swift
//  BLEWatch
//
//  Created by Vass Gábor on 25/01/2019.
//  Copyright © 2019 gabor.vass. All rights reserved.
//

import UIKit
import CoreNFC


class ViewController: UIViewController {

    let ble = BLE()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        ble.startScanning(timeout: 30)
    }


}

