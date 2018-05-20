//
//  LoginViewController.swift
//  testmoon
//
//  Created by Jiameng Cen on 17/5/18.
//  Copyright © 2018 Jiameng Cen. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var userPasswordTextField: UITextField!
    @IBOutlet weak var userEmailTextField: UITextField!
    
    @IBOutlet weak var loginButton: UIButton!
    // @IBOutlet weak var userPasswordTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.addTarget(self, action: #selector(handleLoginButton), for: .touchUpInside)
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside) //不知道要不要放这里
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        let userEmail = userEmailTextField.text;
        let userPassword = userPasswordTextField.text;
        let userEmailStored = UserDefaults.standard.string(forKey: "userEmail");
        let userPasswordStored = UserDefaults.standard.string(forKey: "userPassword");
        if(userEmailStored == userEmail){
            if(userPasswordStored == userPassword)
            {
                //Login is successfull
                UserDefaults.standard.set(true,forKey:"isUserLoggedIn");
                UserDefaults.standard.synchronize();
                self.dismiss(animated: true,completion:nil);
                //let newWalkViewController = NewWalkViewController()
                //present(newWalkViewController,animated: true, completion: nil)
                //loginButton.addTarget(self, action: #selector(handleLogin), for : .touchUpInside)
                
                //let controller = self.storyboard?.instantiateViewController(withIdentifier: "NewWalkViewController") as! NewWalkViewController
                //self.present(controller, animated: true, completion: nil)
                handleLoginButton()
                handleLogin()
            }
        }
    }
   
    @objc func handleLoginButton(){
        let controller = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
        self.present(controller, animated: true, completion: nil)
    }
    
    /* @objc func handleLogin(){
     let newWalkViewController = NewWalkViewController()
     present(newWalkViewController, animated: true, completion: nil)
     } */
    
    @objc func handleLogin(){
        guard let email = userEmailTextField.text, let password = userPasswordTextField.text else{
            print("Form is not valid")
            return
        }
        Auth.auth().signIn(withEmail: email,password:password,completion:{  //check是不是email 和 password
            (user,error) in
            if error != nil{
                print(error)
                return
            }
            // successfully logged
        })
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}



