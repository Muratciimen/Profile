//
//  ConnectionViewController.swift
//  Profile
//
//  Created by Murat Çimen on 6.08.2023.
//
import SwiftKeychainWrapper
import UIKit

class ConnectionViewController: UIViewController {
    
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var surname: UILabel!
    @IBOutlet weak var email: UILabel!
    
    @IBOutlet weak var secondEmail: UIButton!
    @IBOutlet weak var password: UIButton!
    @IBOutlet weak var logout: UIButton!
    
    @IBOutlet weak var newsButton: UIButton!
    let authTokenKey = "AuthToken"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        secondEmail.layer.cornerRadius = 15
        password.layer.cornerRadius = 15
        logout.layer.cornerRadius = 15
        newsButton.layer.cornerRadius = 15
        
        if let dataToken = KeychainWrapper.standard.string(forKey: authTokenKey) {
            fetchData(dataToken: dataToken)
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
        let code: Int
        let message: String
        let datas: ResponseData
    }
    
    struct ResponseData: Codable {
        let name: String
        let surname: String
        let email: String
    }
    
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
                    self.name.text = updateResponse.datas.name
                    self.surname.text = updateResponse.datas.surname
                    self.email.text = updateResponse.datas.email
                }
                
            } catch {
                print("JSON çözme hatası: \(error)")
            }
        }.resume()
    }
    
    @IBAction func logout(_ sender: Any) {
        performLogout()
    }
    
    func performLogout() {
        if let storedToken = KeychainWrapper.standard.string(forKey: authTokenKey) {
            performServerLogout(dataToken: storedToken) { [weak self] success, code in
                if success || code == 401 {
                    if KeychainWrapper.standard.removeObject(forKey: self?.authTokenKey ?? "authToken") {
                        print("Token başarılı bir şekilde silindi.")
                    } else {
                        print("Token silinirken bir hata oluştu.")
                    }
                    DispatchQueue.main.async {
                        let vc = self?.storyboard?.instantiateViewController(identifier: "Login") as! ViewController
                        self?.navigationController?.pushViewController(vc, animated: true)
                    }
                } else {
                    print("Sunucu logout işlemi başarısız.")
                }
            }
        } else {
            print("Token bulunamadı. Zaten çıkış yapılmış olabilir.")
        }
    }
    
    func performServerLogout(dataToken: String, completion: @escaping (Bool, Int) -> Void) {
        guard let apiURL = URL(string: "http://localhost:8090/api/auth/logout") else {
            print("Geçersiz API URL'si")
            completion(false, 0)
            return
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(dataToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                completion(false, 0)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Çıkış başarılı.")
                    completion(true, httpResponse.statusCode)
                } else {
                    print("Çıkış başarısız: \(httpResponse.statusCode)")
                    completion(false, httpResponse.statusCode)
                }
            }
        }.resume()
    }
}
