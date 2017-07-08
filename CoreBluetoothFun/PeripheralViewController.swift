//
//  PeripheralViewController.swift
//  CoreBluetoothFun
//
//  Created by Andrew Robinson on 7/7/17.
//  Copyright © 2017 Andrew Robinson. All rights reserved.
//

import UIKit

class PeripheralViewController: UIViewController {

    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var successImageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
        successImageView.tintColor = .clear

    }

}
