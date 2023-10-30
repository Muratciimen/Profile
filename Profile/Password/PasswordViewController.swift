//
//  PasswordViewController.swift
//  Profile
//
//  Created by Murat Çimen on 3.08.2023.
//
import UIKit
import SwiftKeychainWrapper

class PasswordViewController: UIViewController {
    
    @IBOutlet weak var oldPassword: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var passwordRetry: UITextField!
    @IBOutlet weak var secondChange: UIButton!
    
    
    let authTokenKey = "AuthToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        oldPassword.layer.cornerRadius = 15
        password.layer.cornerRadius = 15
        passwordRetry.layer.cornerRadius = 15
        secondChange.layer.cornerRadius = 15
        oldPassword.isSecureTextEntry = true
        password.isSecureTextEntry = true
        passwordRetry.isSecureTextEntry = true
    
    }
    
    @IBAction func secondChange(_ sender: Any) {
        if let dataToken = KeychainWrapper.standard.string(forKey: authTokenKey) {
            change(dataToken: dataToken)
        } else {
            showAlert(message: "Token bulunamadı. Giriş yapmanız gerekmektedir.")
        }
        
        oldPassword.text = ""
        password.text = ""
        passwordRetry.text = ""
    }
    
    struct UpdateResponse: Codable {
        let success: Bool
        let message: String
    }
    
    func change(dataToken: String) {
        guard let oldPassword = oldPassword.text, !oldPassword.isEmpty,
              let password = password.text, !password.isEmpty,
              let passwordRetry = passwordRetry.text, !passwordRetry.isEmpty else {
            showAlert(message: "Tüm alanları doldurunuz.")
            return
            
        }
        
        guard let apiURL = URL(string: "http://localhost:8090/api/auth/update-password") else {
            print("Geçersiz API URL'si")
            return
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "PUT"
        
        let updateData = ["oldPassword": oldPassword, "password": password, "passwordRetry": passwordRetry]
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
        let okAction = UIAlertAction(title: "Tamam", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

