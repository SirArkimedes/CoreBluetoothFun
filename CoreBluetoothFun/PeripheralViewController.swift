//
//  PeripheralViewController.swift
//  CoreBluetoothFun
//
//  Created by Andrew Robinson on 7/7/17.
//  Copyright © 2017 Andrew Robinson. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController {

    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var successImageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!

    private var peripheralManager: CBPeripheralManager!
    private var transferCharacteristic: CBMutableCharacteristic!
    private var dataToSend: NSData!
    private var sendDataIndex: Int = 0

    private let cbIDTransfer = CBUUID(string: CBIDTransfer)
    private let cbIDCharacteristic = CBUUID(string: CBIDCharacteristic)

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = scanColor
        successImageView.tintColor = .clear

        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }

    private func sendData() {
        var sendingEOM = false

        if sendingEOM {
            let didSend = peripheralManager.updateValue("EOM".data(using: .utf8, allowLossyConversion: false)!, for: transferCharacteristic, onSubscribedCentrals: nil)
            if didSend {
                sendingEOM = false
            }
            return
        }

        if sendDataIndex >= dataToSend.length {
            return
        }

        var didSend = true

        while didSend {
            var amountToSend = dataToSend.length - sendDataIndex
            if amountToSend > 20 { amountToSend = 20 }

            let chunk = NSData(bytes: dataToSend.bytes + sendDataIndex, length: amountToSend)
            didSend = peripheralManager.updateValue(chunk as Data, for: transferCharacteristic, onSubscribedCentrals: nil)

            if !didSend {
                return
            }

            let stringFromData = String(data: chunk as Data, encoding: .utf8)
            print("Peripheral sent: \(stringFromData ?? "")")

            sendDataIndex += amountToSend

            if sendDataIndex >= dataToSend.length {
                sendingEOM = true
                let eomSent = peripheralManager.updateValue("EOM".data(using: .utf8, allowLossyConversion: false)!, for: transferCharacteristic, onSubscribedCentrals: nil)
                if eomSent {
                    sendingEOM = false
                    print("Sent: EOM")
                }

                return
            }
        }
    }

}

extension PeripheralViewController: CBPeripheralManagerDelegate {

    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [cbIDTransfer]])
            
            transferCharacteristic = CBMutableCharacteristic(type: cbIDCharacteristic, properties: .notify, value: nil, permissions: .readable)

            let service = CBMutableService(type: cbIDTransfer, primary: true)
            service.characteristics = [transferCharacteristic]
            peripheral.add(service)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        dataToSend = textView.text.data(using: .utf8, allowLossyConversion: false)! as NSData
        sendDataIndex = 0
        sendData()
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        sendData()
    }

}
