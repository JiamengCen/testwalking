//
//  RegisterViewController.swift
//  testmoon
//
//  Created by Jiameng Cen on 17/5/18.
//  Copyright © 2018 Jiameng Cen. All rights reserved.
//

import UIKit
import Firebase

class RegisterViewController: UIViewController {
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var userEmailTextField: UITextField!
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var userPasswordTextField: UITextField!
    
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
  
    var userUid: String!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        registerButton.addTarget(self, action: #selector(handleRegister), for : .touchUpInside)
    }
    
    @objc func handleRegister(){
        guard let email = userEmailTextField.text, let password = userPasswordTextField.text, let name = nameTextField.text else{
            print("Form is not valid")
            return
        }
        Auth.auth().createUser(withEmail: email,password: password,completion: {(user, error) in
            if error != nil{
                print(error)
                return
            }
            let userId = Auth.auth().currentUser!.uid
            //guard let uid = user?.uid else{
            guard let uid = userId as? String else{
                return
            }
            // successfully quthenticated user
            let ref = Database.database().reference(fromURL: "https://gowalk-37cec.firebaseio.com/")
            //let ref = Database.database().reference()
            let userRefenrence = ref.child("users").child(uid) //加节点
            let values = ["name": name,"email":email,"paaword":password]
            userRefenrence.updateChildValues(values,withCompletionBlock:{ (err,ref) in
                if err != nil {
                    print(err)
                    return
                }
                print("Saved user successfully into Firebase db")
            })
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func loadView() {
        super.loadView()
    }
    @IBAction func regiserButtonTapped(_ sender: Any) {
        let userName = nameTextField.text;
        let userEmail = userEmailTextField.text;
        let userPassword = userPasswordTextField.text;
        let userRepeatPassword = repeatPasswordTextField.text;
        // check for empty fields
        
        
        if ((userEmail!.isEmpty) || (userPassword?.isEmpty)! || (userRepeatPassword?.isEmpty)! )
        {
            // Display an alert message
            displayMyAlertMessage(userMesaage: "All dields are required");
            return;
        }
        
        // check if password match
        if (userPassword != userRepeatPassword ){
            // display an alert message
            displayMyAlertMessage(userMesaage: "Passwords do not match");
            return;
    }
        
        //Store data
        UserDefaults.standard.set(userEmail,forKey:"userEmail");
        UserDefaults.standard.set(userPassword,forKey:"userPassword");
        UserDefaults.standard.set(userName,forKey:"userName");
        UserDefaults.standard.synchronize();
        
        
        // display alert message with confirmation.
        var myAlert = UIAlertController(title:"Alert",message:"Register Sucessfully.Thank you!",preferredStyle:UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title:"Ok",style:UIAlertActionStyle.default){
            action in self.dismiss( animated: true);
        }
        myAlert.addAction(okAction);
        self.present(myAlert,animated: true,completion:nil)
        
    }
    
    func displayMyAlertMessage(userMesaage:String){
        var myAlert = UIAlertController(title:"Alert",message:userMesaage,preferredStyle:UIAlertControllerStyle.alert);
        let okAction = UIAlertAction(title:"Ok",style:UIAlertActionStyle.default,handler:nil);
        
        myAlert.addAction(okAction)
        self.present(myAlert,animated:true,completion:nil)
        //self.present(_, myAlert,animated, flag: true,completion: (() -> Void)? = nil);
    }
    
}

