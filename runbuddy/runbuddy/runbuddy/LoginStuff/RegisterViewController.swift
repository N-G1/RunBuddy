//
//  RegisterViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 27/02/2024.
//

import UIKit
import FirebaseAuth
import Foundation
import FirebaseFirestore

class RegisterViewController: UIViewController {
    @IBOutlet weak var txtUserName: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
 var userSaved: Bool = false
    
    @IBAction func btnRegister(_ sender: Any) {
        Task {
            await Register()
        }
    }
    @IBAction func btnBack(_ sender: Any) {
        performSegue(withIdentifier: "unwindToLogin", sender: self)
    }
    
    //move into 1 view controller
    private func displayAlert(_ msg: String){
        let alert = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        present(alert, animated: true)
    }
    
    private func UsernameExists() async -> Bool {
        do {
            //perform check to see if username already exists
            let userCheck = try await db.collection("users").whereField("username", isEqualTo: txtUserName.text!).getDocuments()
            guard userCheck.documents.count == 0 else {
                CrossUsedMethods.displayAlert("Username already exists", self)
                return true
            }
        } catch {
            CrossUsedMethods.displayAlert("Invalid sign up credentials", self)
            print("error: \(error)")
        }
        return false
    }
    
    ///Seperate function as IBActions can't be async, checks if the username already exists and if it doesnt registers the new user
    private func Register() async{
        if await !(UsernameExists()){
            do {
                let authResult = try await Auth.auth().createUser(withEmail: txtEmail.text ?? "", password: txtPassword.text ?? "")
                await self.SaveUsername(authResult.user.uid)
                self.displayAlert("Successfully Registered!")
                self.performSegue(withIdentifier: "unwindToLogin", sender: self)
            } catch {
                CrossUsedMethods.displayAlert(error.localizedDescription, self)
                print("error: \(error.localizedDescription)")
            }
        }
    }

    
    ///Saves the users username to the firestore db and sets the email, user and UID for use through the view controllers
    ///Below is how saving to the db works, if you follow this format and just replace the variables with what you want to
    ///save, then it should work, it does have to be async otherwise it wont save.
    private func SaveUsername(_ uid: String) async {
        do {
            //perform check to see if username already exists
            let userCheck = try await db.collection("users").whereField("username", isEqualTo: txtUserName.text!).getDocuments()
            guard userCheck.documents.count == 0 else {
                displayAlert("Username already exists")
                return
            }
            //Save new user to db
            try await db.collection("users").document(uid).setData(["UID" : uid,"username" : txtUserName.text!, "email" : txtEmail.text!, "recievedFriendRequests": [], "acceptedFriendRequests": [], "completedRuns": [], "totalOverallSteps": 0, "level" : 1, "XP" : 0, "trophies": ["walk1000steps" : false, "addFirstFriend": false, "completeFirstRun": false, "walk5000steps": false, "walk10000steps": false, "complete5runs": false, "complete10runs": false, "complete50runs": false], "trophiesDisplayed": true, "levelDisplayed": true, "runsDisplayed": true, "dailySteps": 0], merge: true)
        } catch {
            print("error: \(error)")
        }
    }
    
    override func viewDidLoad() {
        txtPassword.isSecureTextEntry = true
        super.viewDidLoad()
    }
}
