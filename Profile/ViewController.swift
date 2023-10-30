//
//  ViewController.swift
//  Profile
//
//  Created by Murat Çimen on 1.08.2023.
//
import UIKit
import SwiftKeychainWrapper

class ViewController: UIViewController {

    @IBOutlet weak var loginEmail: UITextField!
    @IBOutlet weak var loginPassword: UITextField!
    @IBOutlet weak var loginRegister: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    let authTokenKey = "AuthToken"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginEmail.layer.cornerRadius = 15
        loginPassword.layer.cornerRadius = 15
        loginRegister.layer.cornerRadius = 15
        loginButton.layer.cornerRadius = 15
        loginPassword.isSecureTextEntry = true
        
        loadTokenFromKeychain()
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
    
    @IBAction func login(_ sender: UIButton) {
        guard let email = loginEmail.text, !email.isEmpty,
              let password = loginPassword.text, !password.isEmpty else {
            
            let alertController = UIAlertController(
                title: "Hata",
                message: "Kullanıcı adı veya şifre boş olamaz.",
                preferredStyle: .alert
            )
            
            let okAction = UIAlertAction(
                title: "Tamam",
                style: .default) { (action) in
                    print("Tamam butonuna basıldı")
            }
            
            alertController.addAction(okAction)
            present(alertController, animated: true, completion: nil)
            return
        }
        
        
        performLogin(email: email, password: password)
    }

    struct LoginResponse: Codable {
        let success: Bool
        let datas: TokenData?
        
        enum CodingKeys: String, CodingKey {
            case success
            case datas = "datas"
        }
    }
    
    struct TokenData: Codable {
        let token: String?
    }
  
    func performLogin(email: String, password: String) {
        var request = URLRequest(url: URL(string: "http://localhost:8090/api/users/login")!)
        request.httpMethod = "POST"
        let postString = "email=\(email)&password=\(password)"
        request.httpBody = postString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("Veri alınamadı.")
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Yanıtı: \(responseString)")
            }
            
            do {
                let decoder = JSONDecoder()
                let loginResponse = try decoder.decode(LoginResponse.self, from: data)
                
                if loginResponse.success {
                    guard let receivedToken = loginResponse.datas?.token else {
                        print("Hata: API'dan token alınamadı.")
                        return
                    }
                    
                    if KeychainWrapper.standard.set(receivedToken, forKey: self?.authTokenKey ?? "") {
                        print("Token başarılı bir şekilde kaydedildi: \(receivedToken)")
                        
                        DispatchQueue.main.async {
                            if let vc = self?.storyboard?.instantiateViewController(withIdentifier: "Connection") as? ConnectionViewController {
                                self?.navigationController?.pushViewController(vc, animated: true)
                            } else {
                                print("Storyboard veya ViewController yüklenirken bir hata oluştu.")
                            }
                        }
                    } else {
                        print("Token kaydedilirken bir hata oluştu.")
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        let alertController = UIAlertController(
                            title: "Hata",
                            message: "Kullanıcı adı veya şifre hatalı.",
                            preferredStyle: .alert
                        )
                        
                        let okAction = UIAlertAction(
                            title: "Tamam",
                            style: .default) { (action) in
                                print("Tamam butonuna basıldı")
                        }
                        
                        alertController.addAction(okAction)
                        self?.present(alertController, animated: true, completion: nil)
                    }
                }
            } catch {
                print("JSON çözme hatası: \(error.localizedDescription)")
            }
        }.resume()
    }


    func loadTokenFromKeychain() {
        if let storedToken = KeychainWrapper.standard.string(forKey: authTokenKey) {
            print("Stored Token: \(storedToken)")
        } else {
            print("Token bulunamadı. Giriş yapmanız gerekmektedir.")
        }
    }
}
