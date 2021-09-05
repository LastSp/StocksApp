//
//  ViewController.swift
//  StocksApp
//
//  Created by Андрей Колесников on 03.09.2021.
//

import UIKit

class ChartsViewController: UIViewController {
    
    //MARK: - IBOutlets
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyLabel: UIImageView!
    
    //MARK: - private properties
    
    private let companies: [String: String] = ["Apple": "AAPL",
                                               "Microsoft": "MSFT",
                                               "Amazon": "AMZN",
                                               "Facebook": "FB"]
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //DataSource
        companyPickerView.dataSource = self
        companyPickerView.delegate = self

        // Activity Indicator
        activityIndicator.hidesWhenStopped = true

        //Network request
        requestQuoteUpdate()
    }

    //MARK: - Work with Network
    
    private func requestQuote(for symbol: String) {
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=pk_be229b1f698543539a1e4c12fa1d816f")!
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                print(error as Any)
                DispatchQueue.main.async {
                    self.createAlert()
                }
                return
            }
            guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                print("response error")
                print("Status Code: \(String(describing: (response as! HTTPURLResponse).statusCode))")
                return
            }
            guard  let data = data else {
                print("data error")
                return
                
            }
            self.fetchImage(for: symbol)
            self.parseQuote(data: data)
            }
        
        dataTask.resume()
    }
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard let json = jsonObject as? [String: Any],
                  let companyName = json["companyName"] as? String,
                  let companySymbol = json["symbol"] as? String,
                  let price = json["latestPrice"] as? Double,
                  let priceChange = json["change"] as? Double
                  
            else {
                print("Invalid JSON")
                return
            }
            
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName, companySymbol: companySymbol, price: price, change: priceChange)
            }
        } catch {
            print("Json parsing error: \(error.localizedDescription)")
        }
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = .black
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
    }
    
    private func fetchImage(for symbol: String) {
        guard let url = URL(string: "https://storage.googleapis.com/iex/api/logos/\(symbol).png") else { return }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, _ , error) in
            guard let data = data, error == nil else {
                print("Network Error with loading the image")
                return
        }
            
        let image = UIImage(data: data)
        
            DispatchQueue.main.async {
                self.companyLabel.image = image
            }
        }
        
        dataTask.resume()
     }
    
    //MARK: - Methods, showing the data
    private func displayStockInfo(companyName: String, companySymbol: String, price: Double, change: Double) {
        activityIndicator.stopAnimating()
        companyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(change)"
        
        changePriceChangeColor(priceChange: change)
    }
    
    private func changePriceChangeColor(priceChange: Double) {
        if priceChange > 0 {
            priceChangeLabel.textColor = .green
        } else {
            priceChangeLabel.textColor = .red
        }
    }
    
    //UIAlertController showing that there's a problem with network
    private func createAlert() {
        let alertController = UIAlertController(title: "Ошибка", message: "Нет подключения к интернету. Проверьте интернет соеденение и попробуйте перезагрузить приложение.", preferredStyle: .alert)
        let dismissAction = UIAlertAction(title: "Отменить", style: .cancel)
        alertController.addAction(dismissAction)
        present(alertController, animated: true)
    }
}

//MARK: - Work with UIPickerView
extension ChartsViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.activityIndicator.startAnimating()
        
        let selectedSymbol = Array(companies.values)[row]
        print("selected symbol: \(selectedSymbol)")
        requestQuote(for: selectedSymbol)
    }
}

