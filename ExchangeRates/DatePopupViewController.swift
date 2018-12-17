//
//  DatePopupViewController.swift
//  ExchangeRates
//
//  Created by Serhii PERKHUN on 12/16/18.
//  Copyright © 2018 Serhii PERKHUN. All rights reserved.
//

import UIKit

class DatePopupViewController: UIViewController {

    @IBOutlet weak var datePicker: UIDatePicker!
    
    var delegate: PopupDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func tapGesture(_ sender: UITapGestureRecognizer) {
        self.delegate.popupDateSelected(date: datePicker.date)
        dismiss(animated: true, completion: nil)
    }
    
}
