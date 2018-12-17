//
//  ViewController.swift
//  ExchangeRates
//
//  Created by Serhii PERKHUN on 12/15/18.
//  Copyright © 2018 Serhii PERKHUN. All rights reserved.
//

import UIKit

enum Result<Value> {
    case success(Value)
    case failure(Error)
}

class ViewController: UIViewController {
    
    var pbRates = [ExchangeRate]()
    var nbuRates = [NBUElement]()
    
    var pbDateIsSelected = false
    
    var pbDateFormatter = DateFormatter()
    var nbuDateFormatter = DateFormatter()
    
    @IBOutlet weak var pbDateButton: UIButton!
    @IBOutlet weak var nbuDateButton: UIButton!
    @IBOutlet weak var pbTableView: UITableView!
    @IBOutlet weak var nbuTableView: UITableView!
    @IBOutlet weak var stackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pbDateFormatter.dateFormat = "dd.MM.yyyy"
        nbuDateFormatter.dateFormat = "yyyyMMdd"
        
        if UIDevice.current.orientation.isLandscape {
            self.stackView.axis = .horizontal
            self.stackView.alignment = .top
        } else {
            self.stackView.axis = .vertical
            self.stackView.alignment = .fill
        }
        makeRequests(for: (true, true), on: Date())
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
            self.stackView.axis = .horizontal
            self.stackView.alignment = .top
        } else {
            self.stackView.axis = .vertical
            self.stackView.alignment = .fill
        }
    }
    
    @IBAction func pbSelectDateButton(_ sender: UIButton) {
        pbDateIsSelected = true
        performSegue(withIdentifier: "toDatePopUpControllerSegue", sender: sender)
    }
    
    @IBAction func nbuSelectDateButton(_ sender: UIButton) {
        pbDateIsSelected = false
        performSegue(withIdentifier: "toDatePopUpControllerSegue", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let popup = segue.destination as! DatePopupViewController
        popup.delegate = self
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        self.present(alert, animated: true)
        let when = DispatchTime.now() + 5
        DispatchQueue.main.asyncAfter(deadline: when){
            alert.dismiss(animated: true, completion: nil)
        }
    }
    
    func getNbuRates(date: Date, completion: ((Result<[NBUElement]>) -> Void)?) {
        var comp = URLComponents(string: "https://bank.gov.ua/NBUStatService/v1/statdirectory/exchange")
        let date = URLQueryItem(name: "date", value: nbuDateFormatter.string(from: date))
        let json = URLQueryItem(name: "json", value: nil)
        comp?.queryItems = [date, json]
        
        guard let url = comp?.url else { return }
        URLSession.shared.dataTask(with: url) { (responseData, response, responseError) in
            if let error = responseError {
                completion?(.failure(error))
            } else if let data = responseData {
                do {
                    let nbu = try JSONDecoder().decode(Nbu.self, from: data)
                    completion?(.success(nbu))
                }
                catch {
                    completion?(.failure(error))
                }
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                completion?(.failure(error))
            }
        }.resume()
    }
    
    func getPbRates(date: Date, completion: ((Result<PrivatBank>) -> Void)?) {
        var comp = URLComponents(string: "https://api.privatbank.ua/p24api/exchange_rates")
        let date = URLQueryItem(name: "date", value: pbDateFormatter.string(from: date))
        let json = URLQueryItem(name: "json", value: nil)
        comp?.queryItems = [json, date]

        guard let url = comp?.url else { return }
        URLSession.shared.dataTask(with: url) { (responseData, response, responseError) in
            if let error = responseError {
                completion?(.failure(error))
            } else if let data = responseData {
                do {
                    let pb = try JSONDecoder().decode(PrivatBank.self, from: data)
                    completion?(.success(pb))
                }
                catch {
                    completion?(.failure(error))
                }
            } else {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Data was not retrieved from request"]) as Error
                completion?(.failure(error))
            }
            }.resume()
    }
    
    func makeRequests(for bank: (pb: Bool, nbu: Bool), on date: Date) {
        
        if bank.pb {
            getPbRates(date: date) { (result) in
                switch result {
                case .success(let pb):
                    DispatchQueue.main.async {
                        if pb.exchangeRate == nil || pb.exchangeRate?.count == 0 {
                            self.showAlert(message: "Невiрна дата")
                        } else {
                            self.pbRates = pb.exchangeRate!.filter {$0.currency != nil && $0.purchaseRate != nil && $0.saleRate != nil}
                            self.pbDateButton.setTitle(self.pbDateFormatter.string(from: date), for: .normal)
                            self.pbTableView.reloadData()
                        }
                    }
                case .failure(let error):
                    print("error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert(message: "Щось пiшло не так, спробуйте, будь ласка, пiзнiше.")
                    }
                }
            }
        }
        if bank.nbu {
            getNbuRates(date: date) { (result) in
                switch result {
                case .success(let nbu):
                    DispatchQueue.main.async {
                        if nbu.count == 0 || nbu[0].message != nil {
                            self.showAlert(message: "Невiрна дата")
                        } else {
                            self.nbuRates = nbu
                            self.nbuTableView.reloadData()
                            self.nbuDateButton.setTitle(self.pbDateFormatter.string(from: date), for: .normal)
                        }
                    }
                case .failure(let error):
                    print("error: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.showAlert(message: "Щось пiшло не так, спробуйте, будь ласка, пiзнiше.")
                    }
                }
            }
        }
    }
    
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView.restorationIdentifier == "NBUTable" {
            return self.nbuRates.count
        } else {
            return pbRates.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView.restorationIdentifier == "NBUTable" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "nbuCell", for: indexPath) as! NbuTableViewCell
            cell.name.text = nbuRates[indexPath.row].txt
            cell.rate.text = String(describing: nbuRates[indexPath.row].rate!)
            cell.cc.text = "1 " + nbuRates[indexPath.row].cc!
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "pbCell", for: indexPath) as! PbTableViewCell
            if let currency = pbRates[indexPath.row].currency, let saleRate = pbRates[indexPath.row].saleRate, let purchaseRate = pbRates[indexPath.row].purchaseRate {
                cell.currency.text = currency
                cell.saleRate.text = String(describing: saleRate)
                cell.purchaseRate.text = String(describing: purchaseRate)
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView.restorationIdentifier == "NBUTable" {
            return 65
        } else {
            return tableView.frame.height / 3
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView.restorationIdentifier == "NBUTable" {
            let currency = nbuRates[indexPath.row].cc
            for i in 0..<pbRates.count {
                if pbRates[i].currency == currency {
                    let index = IndexPath(row: i, section: 0)
                    pbTableView.selectRow(at: index, animated: true, scrollPosition: .middle)
                }
            }
        } else {
            let currency = pbRates[indexPath.row].currency
            for i in 0..<nbuRates.count {
                if nbuRates[i].cc == currency {
                    let index = IndexPath(row: i, section: 0)
                    nbuTableView.selectRow(at: index, animated: true, scrollPosition: .middle)
                }
            }
        }
    }
}

extension ViewController: PopupDelegate {

    func popupDateSelected(date: Date) {
        if pbDateIsSelected {
            makeRequests(for: (true, false), on: date)
        } else {
            makeRequests(for: (false, true), on: date)
        }
    }
}
