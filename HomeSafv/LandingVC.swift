//
//  LandingVC.swift
//  HomeSafv
//
//  Created by Alex Tan, Desmond, Yanling, Lei Jun on 1/5/17.
//  Copyright © 2017 SG4207. All rights reserved.
//

import UIKit

class LandingVC: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask.portrait
        }
    }
    
    func showView(viewController: ViewControllerType)  {
        switch viewController {
        case .conversations:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "Navigation") as! MainVC
            self.present(vc, animated: false, completion: nil)
        case .welcome:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "Login") as! LoginVC
            self.present(vc, animated: false, completion: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let userInformation = UserDefaults.standard.dictionary(forKey: "userInformation") {
            let email = userInformation["email"] as! String
            let password = userInformation["password"] as! String
            User.loginUser(withEmail: email, password: password, completion: { [weak weakSelf = self] (status) in
                DispatchQueue.main.async {
                    if status == true {
                        weakSelf?.showView(viewController: .conversations)
                    } else {
                        weakSelf?.showView(viewController: .welcome)
                    }
                    weakSelf = nil
                }
            })
        } else {
            self.showView(viewController: .welcome)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
