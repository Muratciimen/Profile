//
//  ScreenViewController.swift
//  Profile
//
//  Created by Murat Çimen on 21.09.2023.
//
import UIKit
import SwiftKeychainWrapper

class ScreenViewController: UIViewController {

    let authTokenKey = "AuthToken"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if let storedToken = KeychainWrapper.standard.string(forKey: self.authTokenKey) {
                print("Stored Token: \(storedToken)")
                self.redirectToCollectionView()
            } else {
                print("Token bulunamadı. Giriş yapmanız gerekmektedir.")
                self.redirectToLogin()
            }
        }
    }

    func redirectToCollectionView() {
        if let vc = self.storyboard?.instantiateViewController(identifier: "Connection") as? ConnectionViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func redirectToLogin() {
        if let secondVc = self.storyboard?.instantiateViewController(identifier: "Login") as? ViewController {
            self.navigationController?.pushViewController(secondVc, animated: true)
        }
    }
}

