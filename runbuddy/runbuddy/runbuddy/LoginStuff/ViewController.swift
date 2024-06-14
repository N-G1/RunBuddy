//
//  ViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 22/02/2024.
//

import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

//global otherwise firestore wont accept if stored within home view controller
var uid: String = "nil"

class ViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    @IBAction func btnLogin(_ sender: Any) {
        Auth.auth().signIn(withEmail: txtEmail.text ?? "", password: txtPassword.text ?? "") { authResult, error in
            if let error = error {
                CrossUsedMethods.displayAlert(error.localizedDescription, self)
            }
            else {
                uid = authResult!.user.uid
                self.performSegue(withIdentifier: "segueHome", sender: sender)
                self.txtEmail.text = ""
                self.txtPassword.text = ""
            }
        }
    }
    
    @IBAction func btnBypassLogin(_ sender: Any) {
        performSegue(withIdentifier: "segueHome", sender: sender)
    }
    private func displayAlert(_ msg: String){
        let alert = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        present(alert, animated: true)
    }
    
    //dont remove this it is doing smthing
    @IBAction func unwindToLogin(_: UIStoryboardSegue){
        
    }
    
    public override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueHome" {
            //let homeVC = segue.destination as! HomeViewController
            //homeVC.userUID = Auth.auth().currentUser?.uid ?? "";
       }
   }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtPassword.isSecureTextEntry = true
        // Do any additional setup after loading the view.
    }

}

