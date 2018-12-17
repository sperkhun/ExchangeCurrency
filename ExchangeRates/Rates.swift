//
//  Rates.swift
//  ExchangeRates
//
//  Created by Serhii PERKHUN on 12/15/18.
//  Copyright © 2018 Serhii PERKHUN. All rights reserved.
//

import Foundation

struct PrivatBank: Codable {
    let exchangeRate: [ExchangeRate]?
}

struct ExchangeRate: Codable {
    let currency: String?
    let saleRate, purchaseRate: Double?
}


typealias Nbu = [NBUElement]

struct NBUElement: Codable {
    let txt: String?
    let rate: Double?
    let cc: String?
    let message: String?
}
