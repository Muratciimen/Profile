//
//  RegisterViewController.swift
//  Profile
//
//  Created by Murat Çimen on 1.08.2023.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet weak var registerName: UITextField!
    @IBOutlet weak var registerSurname: UITextField!
    @IBOutlet weak var registerEmail: UITextField!
    @IBOutlet weak var registerPassword: UITextField!
    @IBOutlet weak var registerPasswordRetry: UITextField!
    @IBOutlet weak var register: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        registerName.layer.cornerRadius = 15
        registerSurname.layer.cornerRadius = 15
        registerEmail.layer.cornerRadius = 15
        registerPassword.layer.cornerRadius = 15
        registerPasswordRetry.layer.cornerRadius = 15
        register.layer.cornerRadius = 15
        
        registerPassword.isSecureTextEntry = true
        registerPasswordRetry.isSecureTextEntry = true
        
    }

    @IBAction func registerButton(_ sender: UIButton) {
        registerFunc()
        
            }

    func registerFunc() {
        guard let name = registerName.text, !name.isEmpty,
              let surname = registerSurname.text, !surname.isEmpty,
              let email = registerEmail.text, !email.isEmpty,
              let password = registerPassword.text, !password.isEmpty,
              let password_retry = registerPasswordRetry.text, !password_retry.isEmpty
        else {
            showAlert(message: "Tüm alanları doldurunuz.")
            return
        }

        var request = URLRequest(url: URL(string: "http://localhost:8090/api/users/register")!)

        request.httpMethod = "POST"

        let postString = "name=\(name)&surname=\(surname)&email=\(email)&password=\(password)&password_retry=\(password_retry)"

        request.httpBody = postString.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, response, error in

            if error != nil || data == nil {
                print("Hata")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] {
                    print(json)
                    // Kayıt işlemi başarılıysa input alanlarını temizle
                    DispatchQueue.main.async {
                        if let success = json["success"] as? Bool, success {
                            self.registerName.text = ""
                            self.registerSurname.text = ""
                            self.registerEmail.text = ""
                            self.registerPassword.text = ""
                            self.registerPasswordRetry.text = ""
                        }
                        self.showAlert(title: "Bilgi", message: "Verileriniz kaydedildi.")
                    }
                }

            } catch {
                print(error.localizedDescription)
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
