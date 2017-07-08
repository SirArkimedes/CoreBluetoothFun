//
//  CentralViewController.swift
//  CoreBluetoothFun
//
//  Created by Andrew Robinson on 7/7/17.
//  Copyright © 2017 Andrew Robinson. All rights reserved.
//

import UIKit
import CoreBluetooth

let CBIDTransfer = "0C50D390-DC8E-436B-8AD0-A36D1B304B18"
let CBIDCharacteristic = "726C06CE-1E77-4707-BD8E-3B7E79632E97"

let scanColor = #colorLiteral(red: 0.1879530549, green: 0.4409630895, blue: 0.9288646579, alpha: 1)
let connectingColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
let foundColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)

class CentralViewController: UIViewController {

    @IBOutlet weak var searchingLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    private var central: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral!
    private var data: NSMutableData!

    private let cbIDTransfer = CBUUID(string: CBIDTransfer)
    private let cbIDCharacteristic = CBUUID(string: CBIDCharacteristic)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = scanColor

        central = CBCentralManager(delegate: self, queue: nil)
    }

    private func cleanup() {
        if let services = discoveredPeripheral.services {
            for service in services {
                if let chars = service.characteristics {
                    for char in chars {
                        if char.uuid == cbIDCharacteristic {
                            if char.isNotifying {
                                discoveredPeripheral.setNotifyValue(false, for: char)
                                return
                            }
                        }
                    }
                }
            }
        }

        central.cancelPeripheralConnection(discoveredPeripheral)
    }

}

extension CentralViewController: CBCentralManagerDelegate, CBPeripheralDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: [cbIDTransfer], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
            print("Started scanning!")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered peripheral: \(peripheral.name!) at \(RSSI)")

        if discoveredPeripheral != peripheral {
            discoveredPeripheral = peripheral

            view.backgroundColor = connectingColor

            print("Connecting to peripheral: \(peripheral)")
            central.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to: \(peripheral.name!)")
        cleanup()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name!)!")

        view.backgroundColor = foundColor

        central.stopScan()
        peripheral.delegate = self
        peripheral.discoverServices([cbIDTransfer])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let _ = error {
            cleanup()
        } else {
            if let s = peripheral.services {
                for service in s {
                    peripheral.discoverCharacteristics([cbIDCharacteristic], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let _ = error {
            cleanup()
        } else {
            for char in service.characteristics! {
                if char.uuid == cbIDCharacteristic {
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            cleanup()
        } else {
            let stringFromData = String.init(data: characteristic.value!, encoding: .utf8)

            if stringFromData == "EOM" {
                searchingLabel.text = String.init(data: data as Data, encoding: .utf8)
                peripheral.setNotifyValue(false, for: characteristic)
                central.cancelPeripheralConnection(peripheral)
            }

            if let value = characteristic.value {
                data.append(value)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == cbIDCharacteristic {
            if !characteristic.isNotifying {
                central.cancelPeripheralConnection(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        discoveredPeripheral = nil

        central.scanForPeripherals(withServices: [cbIDTransfer], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }

}
