//
//  NewsTableViewController.swift
//  Profile
//
//  Created by Murat Çimen on 8.10.2023.
//
import UIKit

class NewsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var news: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var secondInputTextField: UITextField!
    @IBOutlet weak var secondDatePicker: UIDatePicker!
    @IBOutlet weak var searchButton: UIButton!

    let dateFormatter = DateFormatter()
    let secondDateFormatter = DateFormatter()

    struct News: Codable {
        let fromDate: String
        let toDate: String
        let memberType: String

        enum CodingKeys: String, CodingKey {
            case fromDate = "publishDate"
            case toDate = "kapTitle"
            case memberType = "disclosureClass"
        }
    }

    var newsData: [News] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setInitView()
        secondSetInitView()
        inputTextField.delegate = self
        secondInputTextField.delegate = self

        // Önce tarih biçimlerini belirleyin
        dateFormatter.dateFormat = "yyyy-MM-dd"
        secondDateFormatter.dateFormat = "yyyy-MM-dd"

        // Tarih seçicileri başlangıç ve bitiş tarihlerine ayarlayın
        datePicker.date = Date()
        secondDatePicker.date = Date()

        // Anında arama işlemini gerçekleştirin
        let fromDate = dateFormatter.string(from: datePicker.date)
        let toDate = secondDateFormatter.string(from: secondDatePicker.date)
        sendPostRequest(fromDate: fromDate, toDate: toDate)
    }

    private func setInitView() {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        inputTextField.inputView = datePicker
        datePicker.datePickerMode = .date
        inputTextField.placeholder = "Başlangıç tarihi seçiniz"
        inputTextField.isUserInteractionEnabled = false
        inputTextField.text = dateFormatter.string(from: datePicker.date)
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // Date picker'ı aç
        inputTextField.inputView = datePicker
        datePicker.isHidden = false
        inputTextField.placeholder = "Başlangıç tarihi seçiniz"
        return true
    }

    private func secondSetInitView() {
        secondDateFormatter.dateFormat = "yyyy-MM-dd"
        secondInputTextField.inputView = secondDatePicker
        secondDatePicker.datePickerMode = .date
        secondInputTextField.placeholder = "Bitiş tarihi seçiniz"
        secondInputTextField.isUserInteractionEnabled = false
        secondInputTextField.text = secondDateFormatter.string(from: secondDatePicker.date)
    }

    func secondTextFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        // Date picker'ı aç
        secondInputTextField.inputView = secondDatePicker
        secondDatePicker.isHidden = false
        secondInputTextField.placeholder = "Bitiş tarihi seçiniz"
        return true
    }

    @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
        inputTextField.text = dateFormatter.string(from: sender.date)
        view.endEditing(true)
    }

    @IBAction func secondDatePickerValueChanged(_ sender: UIDatePicker) {
        secondInputTextField.text = secondDateFormatter.string(from: sender.date)
        view.endEditing(true)
    }

    @IBAction func searchButton(_ sender: UIButton) {
        let fromDate = dateFormatter.date(from: inputTextField.text ?? "")
        let toDate = secondDateFormatter.date(from: secondInputTextField.text ?? "")

        if toDate != nil && fromDate != nil && toDate! < fromDate! {
            // Bitiş tarihi başlangıç tarihinden küçük
            let alert = UIAlertController(title: "Hata", message: "Bitiş tarihi başlangıç tarihinden küçük olamaz!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            // Tarihler uygun, "Ara" butonunu pasif hale getir
            self.searchButton.isEnabled = false

            // Yükleniyor uyarısını göster
            let loadingAlert = UIAlertController(title: nil, message: "Yükleniyor...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.medium
            loadingIndicator.startAnimating()

            loadingAlert.view.addSubview(loadingIndicator)
            self.present(loadingAlert, animated: true, completion: nil)

            // API'ye isteği gönder
            let fromDateStr = dateFormatter.string(from: fromDate!)
            let toDateStr = secondDateFormatter.string(from: toDate!)
            sendPostRequest(fromDate: fromDateStr, toDate: toDateStr)
        }
    }

    func sendPostRequest(fromDate: String, toDate: String) {
        var request = URLRequest(url: URL(string: "https://www.kap.org.tr/tr/api/memberDisclosureQuery")!)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestData: [String: String] = [
            "fromDate": fromDate,
            "toDate": toDate,
            "memberType": "IGS"
        ]

        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(requestData)
            request.httpBody = jsonData
        } catch {
            print("JSON verisi oluşturma hatası: \(error.localizedDescription)")
            self.searchButton.isEnabled = true
            return
        }

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if error != nil {
                print("Hata: \(error!.localizedDescription)")
                self.searchButton.isEnabled = true
                self.handleAPIDoneLoading() // API hatası durumunda yükleniyor ekranını kapat
                return
            }

            guard let data = data else {
                print("Veri alınamadı.")
                self.searchButton.isEnabled = true
                self.handleAPIDoneLoading() // Veri alınamadığında yükleniyor ekranını kapat
                return
            }

            do {
                let decoder = JSONDecoder()

                do {
                    let newsArray = try decoder.decode([News].self, from: data)

                    self.newsData = newsArray

                    DispatchQueue.main.async {
                        self.news.reloadData()
                        self.handleAPIDoneLoading() // API yanıtı geldiğinde yükleniyor ekranını kapat
                    }
                } catch DecodingError.dataCorrupted(let underlyingError) {
                    print("JSON verisi bozuk: \(underlyingError)")
                } catch DecodingError.keyNotFound(let key, let context) {
                    print("JSON verisinde beklenen bir anahtar bulunamadı: \(key), \(context)")
                } catch DecodingError.typeMismatch(let type, let context) {
                    print("JSON verisinde beklenen bir tür bulunamadı: \(type), \(context)")
                } catch DecodingError.valueNotFound(let type, let context) {
                    print("JSON verisinde beklenen bir değer bulunamadı: \(type), \(context)")
                }
            } catch {
                if let errorMessage = String(data: data, encoding: .utf8) {
                    print("JSON çözme hatası: \(error.localizedDescription), API hatası: \(errorMessage)")
                } else {
                    print("JSON çözme hatası: \(error.localizedDescription)")
                }
                self.searchButton.isEnabled = true
                self.handleAPIDoneLoading() // JSON çözme hatası durumunda yükleniyor ekranını kapat
            }
        }

        task.resume()
    }

    func handleAPIDoneLoading() {
        DispatchQueue.main.async {
            self.searchButton.isEnabled = true
            self.dismiss(animated: true, completion: nil) // Yükleniyor ekranını kapat
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = news.dequeueReusableCell(withIdentifier: "NewCells", for: indexPath) as! NewsTableViewCell
        cell.fromDate.text = newsData[indexPath.row].fromDate
        cell.toDate.text = newsData[indexPath.row].toDate
        cell.memberType.text = newsData[indexPath.row].memberType
        return cell
    }
}




/*
 import UIKit

 class NewsTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate {

     @IBOutlet weak var news: UITableView!
     @IBOutlet weak var inputTextField: UITextField!
     @IBOutlet weak var datePicker: UIDatePicker!
     @IBOutlet weak var secondInputTextField: UITextField!
     @IBOutlet weak var secondDatePicker: UIDatePicker!
     @IBOutlet weak var searchButton: UIButton!

     let dateFormatter = DateFormatter()
     let secondDateFormatter = DateFormatter()

     struct News: Codable {
         let fromDate: String
         let toDate: String
         let memberType: String

         enum CodingKeys: String, CodingKey {
             case fromDate = "publishDate"
             case toDate = "kapTitle"
             case memberType = "disclosureClass"
         }
     }

     var newsData: [News] = []

     override func viewDidLoad() {
         super.viewDidLoad()
         setInitView()
         secondSetInitView()
         inputTextField.delegate = self
         secondInputTextField.delegate = self

         // Önce tarih biçimlerini belirleyin
         dateFormatter.dateFormat = "yyyy-MM-dd"
         secondDateFormatter.dateFormat = "yyyy-MM-dd"

         // Tarih seçicileri başlangıç ve bitiş tarihlerine ayarlayın
         datePicker.date = Date()
         secondDatePicker.date = Date()

         // Anında arama işlemini gerçekleştirin
         let fromDate = dateFormatter.string(from: datePicker.date)
         let toDate = secondDateFormatter.string(from: secondDatePicker.date)
         sendPostRequest(fromDate: fromDate, toDate: toDate)
     }

     private func setInitView() {
         dateFormatter.dateFormat = "yyyy-MM-dd"
         inputTextField.inputView = datePicker
         datePicker.datePickerMode = .date
         inputTextField.placeholder = "Başlangıç tarihi seçiniz"
         inputTextField.isUserInteractionEnabled = false
         inputTextField.text = dateFormatter.string(from: datePicker.date)
     }

     func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
         // Date picker'ı aç
         inputTextField.inputView = datePicker
         datePicker.isHidden = false
         inputTextField.placeholder = "Başlangıç tarihi seçiniz"
         return true
     }

     private func secondSetInitView() {
         secondDateFormatter.dateFormat = "yyyy-MM-dd"
         secondInputTextField.inputView = secondDatePicker
         secondDatePicker.datePickerMode = .date
         secondInputTextField.placeholder = "Bitiş tarihi seçiniz"
         secondInputTextField.isUserInteractionEnabled = false
         secondInputTextField.text = secondDateFormatter.string(from: secondDatePicker.date)
     }

     func secondTextFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
         // Date picker'ı aç
         secondInputTextField.inputView = secondDatePicker
         secondDatePicker.isHidden = false
         secondInputTextField.placeholder = "Bitiş tarihi seçiniz"
         return true
     }

     @IBAction func datePickerValueChanged(_ sender: UIDatePicker) {
         inputTextField.text = dateFormatter.string(from: sender.date)
         view.endEditing(true)
     }

     @IBAction func secondDatePickerValueChanged(_ sender: UIDatePicker) {
         secondInputTextField.text = secondDateFormatter.string(from: sender.date)
         view.endEditing(true)
     }

     @IBAction func searchButton(_ sender: UIButton) {
         let fromDate = dateFormatter.date(from: inputTextField.text ?? "")
         let toDate = secondDateFormatter.date(from: secondInputTextField.text ?? "")

         if toDate != nil && fromDate != nil && toDate! < fromDate! {
             // Bitiş tarihi başlangıç tarihinden küçük
             let alert = UIAlertController(title: "Hata", message: "Bitiş tarihi başlangıç tarihinden küçük olamaz!", preferredStyle: .alert)
             alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
             self.present(alert, animated: true, completion: nil)
         } else {
             // Tarihler uygun, "Ara" butonunu pasif hale getir
             self.searchButton.isEnabled = false

             // Yükleniyor uyarısını göster
             let loadingAlert = UIAlertController(title: nil, message: "Yükleniyor...", preferredStyle: .alert)
             let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
             loadingIndicator.hidesWhenStopped = true
             loadingIndicator.style = UIActivityIndicatorView.Style.medium
             loadingIndicator.startAnimating()

             loadingAlert.view.addSubview(loadingIndicator)
             self.present(loadingAlert, animated: true, completion: nil)

             // API'ye isteği gönder
             let fromDateStr = dateFormatter.string(from: fromDate!)
             let toDateStr = secondDateFormatter.string(from: toDate!)
             sendPostRequest(fromDate: fromDateStr, toDate: toDateStr)
         }
     }

     func sendPostRequest(fromDate: String, toDate: String) {
         var request = URLRequest(url: URL(string: "https://www.kap.org.tr/tr/api/memberDisclosureQuery")!)

         request.httpMethod = "POST"
         request.setValue("application/json", forHTTPHeaderField: "Content-Type")

         let requestData: [String: String] = [
             "fromDate": fromDate,
             "toDate": toDate,
             "memberType": "IGS"
         ]

         do {
             let jsonEncoder = JSONEncoder()
             let jsonData = try jsonEncoder.encode(requestData)
             request.httpBody = jsonData
         } catch {
             print("JSON verisi oluşturma hatası: \(error.localizedDescription)")
             self.searchButton.isEnabled = true
             return
         }

         let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
             if error != nil {
                 print("Hata: \(error!.localizedDescription)")
                 self.searchButton.isEnabled = true
                 self.handleAPIDoneLoading() // API hatası durumunda yükleniyor ekranını kapat
                 return
             }

             guard let data = data else {
                 print("Veri alınamadı.")
                 self.searchButton.isEnabled = true
                 self.handleAPIDoneLoading() // Veri alınamadığında yükleniyor ekranını kapat
                 return
             }

             do {
                 let decoder = JSONDecoder()

                 do {
                     let newsArray = try decoder.decode([News].self, from: data)

                     self.newsData = newsArray

                     DispatchQueue.main.async {
                         self.news.reloadData()
                         self.handleAPIDoneLoading() // API yanıtı geldiğinde yükleniyor ekranını kapat
                     }
                 } catch DecodingError.dataCorrupted(let underlyingError) {
                     print("JSON verisi bozuk: \(underlyingError)")
                 } catch DecodingError.keyNotFound(let key, let context) {
                     print("JSON verisinde beklenen bir anahtar bulunamadı: \(key), \(context)")
                 } catch DecodingError.typeMismatch(let type, let context) {
                     print("JSON verisinde beklenen bir tür bulunamadı: \(type), \(context)")
                 } catch DecodingError.valueNotFound(let type, let context) {
                     print("JSON verisinde beklenen bir değer bulunamadı: \(type), \(context)")
                 }
             } catch {
                 if let errorMessage = String(data: data, encoding: .utf8) {
                     print("JSON çözme hatası: \(error.localizedDescription), API hatası: \(errorMessage)")
                 } else {
                     print("JSON çözme hatası: \(error.localizedDescription)")
                 }
                 self.searchButton.isEnabled = true
                 self.handleAPIDoneLoading() // JSON çözme hatası durumunda yükleniyor ekranını kapat
             }
         }

         task.resume()
     }

     func handleAPIDoneLoading() {
         DispatchQueue.main.async {
             self.searchButton.isEnabled = true
             self.dismiss(animated: true, completion: nil) // Yükleniyor ekranını kapat
         }
     }

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return newsData.count
     }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = news.dequeueReusableCell(withIdentifier: "NewCells", for: indexPath) as! NewsTableViewCell
         cell.fromDate.text = newsData[indexPath.row].fromDate
         cell.toDate.text = newsData[indexPath.row].toDate
         cell.memberType.text = newsData[indexPath.row].memberType
         return cell
     }
 }

 */
