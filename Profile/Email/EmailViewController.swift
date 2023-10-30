//
//  EmailViewController.swift
//  Profile
//
//  Created by Murat Çimen on 3.08.2023.
//

import UIKit
import SwiftKeychainWrapper

class EmailViewController: UIViewController {
    
    @IBOutlet weak var emailName: UITextField!
    @IBOutlet weak var emailSurname: UITextField!
    @IBOutlet weak var emailSecond: UITextField!
    @IBOutlet weak var changeButton: UIButton!
    
    let authTokenKey = "AuthToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailName.layer.cornerRadius = 15
        emailSurname.layer.cornerRadius = 15
        emailSecond.layer.cornerRadius = 15
        changeButton.layer.cornerRadius = 15
        
        if let dataToken = KeychainWrapper.standard.string(forKey: authTokenKey) {
            fetchData(dataToken: dataToken)
        } else {
            showAlert(message: "Token bulunamadı. Giriş yapmanız gerekmektedir.")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    struct UpdateResponse: Codable {
        let success: Bool
        let message: String
        let datas: ResponseData
    }
    
    struct ResponseData: Codable {
        let name: String
        let surname: String
        let email: String
    }
    
    var responseData: ResponseData?
    
    func fetchData(dataToken: String) {
        guard let url = URL(string: "http://localhost:8090/api/auth/me") else {
            print("Geçersiz URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(dataToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Veri alınamadı.")
                return
            }
            do {
                let decoder = JSONDecoder()
                let updateResponse = try decoder.decode(UpdateResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.emailName.text = updateResponse.datas.name
                    self.emailSurname.text = updateResponse.datas.surname
                    self.emailSecond.text = updateResponse.datas.email
                }
                
            } catch {
                print("JSON çözme hatası: \(error)")
            }
        }.resume()
    }
    
    @IBAction func changeButton(_ sender: Any) {
        if let dataToken = KeychainWrapper.standard.string(forKey: authTokenKey) {
            change(dataToken: dataToken)
        } else {
            showAlert(message: "Token bulunamadı. Giriş yapmanız gerekmektedir.")
        }
    }
    
    func change(dataToken: String) {
        guard let apiURL = URL(string: "http://localhost:8090/api/auth/update-me") else {
            print("Geçersiz API URL'si")
            return
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "PUT"
        
        let updateData = ["name": emailName.text, "surname": emailSurname.text, "email": emailSecond.text]
        let jsonData = try? JSONSerialization.data(withJSONObject: updateData)
        request.httpBody = jsonData
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(dataToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Veri alınamadı.")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let updateResponse = try decoder.decode(UpdateResponse.self, from: data)
                
                if updateResponse.success {
                    print("Başarıyla güncellendi: \(updateResponse.message)")
                    DispatchQueue.main.async {
                        self.showAlert(title: "Bilgi", message: "Verileriniz başarıyla güncellendi.")
                    }
                } else {
                    print("Güncelleme başarısız: \(updateResponse.message)")
                }
            } catch {
                print("JSON çözme hatası: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func showAlert(title: String = "Hata", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Tamam", style: .default) { [weak self] _ in
            // Tamam butonuna basıldığında güncelleme işlemi başarılıysa ConnectionViewController'a geçiş yap
            if let vc = self?.storyboard?.instantiateViewController(identifier: "Connection") as? ConnectionViewController {
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}
