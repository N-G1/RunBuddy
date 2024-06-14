//
//  SettingsViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 27/03/2024.
//

import UIKit
import FirebaseAuth
var btnPresssed: String!

class SettingsViewController: UIViewController {
    @IBOutlet weak var switchTrophies: UISwitch!
    @IBOutlet weak var switchRuns: UISwitch!
    @IBOutlet weak var switchLevel: UISwitch!
    
    let userRef = db.collection("users").document(uid)
    
    @IBAction func actSwitchTrophies(_ sender: Any) {
        if switchTrophies.isOn {
            userRef.updateData(["trophiesDisplayed": true])
        }
        else {
            userRef.updateData(["trophiesDisplayed": false])
        }
        
        //reload data after change
        Task{
            await HomeViewController().loadData()
        }
    }
    
    @IBAction func actSwitchRuns(_ sender: Any) {
        if switchRuns.isOn {
            userRef.updateData(["runsDisplayed": true])
        }
        else {
            userRef.updateData(["runsDisplayed": false])
        }
        
        Task{
            await HomeViewController().loadData()
        }
    }
    
    @IBAction func actSwitchLevel(_ sender: Any) {
        if switchLevel.isOn {
            userRef.updateData(["levelDisplayed": true])
        }
        else {
            userRef.updateData(["levelDisplayed": false])
        }
        
        Task{
            await HomeViewController().loadData()
        }
    }
    
    
    @IBAction func btnChangeUser(_ sender: Any) {
        changeDetailAlert("Confirm", "Enter your username", "New username", false, nil)
    }
    
    @IBAction func btnChangePassword(_ sender: Any) {
        reAuthUser("Confirm", "Enter your details")
    }
    
    @IBAction func btnDelRuns(_ sender: Any) {
        confirmationAlert("Confirm", "Are you sure you want to delete your run data?", "delRuns")
    }
    
    @IBAction func btnDelAcc(_ sender: Any) {
        confirmationAlert("Confirm", "Are you sure you want to delete your account?", "delAccount")
    }
    
    func confirmationAlert(_ title: String, _ msg: String, _ btn: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: {(action: UIAlertAction!) in
            return
        }))
        
        if btn == "delRuns" {
            //deletes a users runs
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction!) in
                self.userRef.updateData(["completedRuns": []])
                userDictionary["completedRuns"] = []
            }))
        }
        else if btn == "delAccount"{
            //Deletes a users account
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action: UIAlertAction!) in
                self.userRef.delete()
                Auth.auth().currentUser?.delete { error in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    else {
                        
                    }
                }
                self.performSegue(withIdentifier: "unwindToLogin", sender: self)
            }))
        }
        present(alert, animated: true)
    }
    
    /*
     request for new information
     */
    func changeDetailAlert(_ title: String, _ msg: String, _ placeholderNewTxt: String, _ password: Bool, _ reAuth: AuthCredential?){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        
        alert.addTextField { text in text.placeholder = placeholderNewTxt
            text.isSecureTextEntry = password
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(_: UIAlertAction!) in 
            return
        }))
        
        //changes the password if came from password change btn, changes username otherwise, checks if username already exists
        alert.addAction(UIAlertAction(title: "Change", style: .default, handler: {(_: UIAlertAction!) in
            if password {
                Auth.auth().currentUser?.reauthenticate(with: reAuth!) { authResult, error in
                    if let error = error {
                        CrossUsedMethods.displayAlert("Invalid username or password", self)
                        print("error: \(error)")
                    }
                    else {
                        Auth.auth().currentUser?.updatePassword(to: alert.textFields![0].text!)
                        CrossUsedMethods.displayAlert("Password successfully changed", self)
                    }
                }
            }
            else {
                Task{
                    do {
                        //check if username exists
                        let userCheck = try await db.collection("users").whereField("username", isEqualTo: alert.textFields![0].text!).getDocuments()
                        guard userCheck.documents.count == 0 else {
                            CrossUsedMethods.displayAlert("Username already exists", self)
                            return
                        }
                        try await self.userRef.updateData(["username": alert.textFields![0].text!])
                        CrossUsedMethods.displayAlert("Username successfully changed", self)
                    } catch {
                        CrossUsedMethods.displayAlert("Error", self)
                        print("error: \(error)")
                    }
                }
            }

        }))
        present(alert, animated: true)
    }
    
    /*
     Requests the user to reauthenticate their details before they enter their new information
     */
    func reAuthUser(_ title: String,_ msg: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        var email: String!
        var password: String!
        
        alert.addTextField { email in
            email.placeholder = "Enter your email"
        }
        alert.addTextField { password in
            password.placeholder = "Enter your password"
            password.isSecureTextEntry = true
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: {(_: UIAlertAction!) in 
            return
        }))
        
        alert.addAction(UIAlertAction(title: "Enter", style: .default, handler: {(_: UIAlertAction!) in
            
            guard alert.textFields![0].text! != "" else {
                return
            }
            guard alert.textFields![1].text! != "" else {
                return
            }
            email = alert.textFields![0].text!
            password = alert.textFields![1].text!
            self.changeDetailAlert("Confirm", "Change your password", "Enter new password", true, EmailAuthProvider.credential(withEmail: email, password: password))
        }))
        present(alert, animated: true)
    }
    
    /*
     Sets the switches tso the correct state depending on the users privacy settings
     */
    func checkPrivacy(){
        let trophyPrivacy = userDictionary["trophiesDisplayed"] as! Bool
        let levelPrivacy = userDictionary["levelDisplayed"] as! Bool
        let runPrivacy = userDictionary["runsDisplayed"] as! Bool
        
        if trophyPrivacy {
            switchTrophies.isOn = true
        }
        else if !trophyPrivacy{
            switchTrophies.isOn = false
        }
        
        if levelPrivacy {
            switchLevel.isOn = true
        }
        else if !levelPrivacy{
            switchLevel.isOn = false
        }
        
        if runPrivacy {
            switchRuns.isOn = true
        }
        else if !runPrivacy{
            switchRuns.isOn = false
        }
        
        switchTrophies.isEnabled = true
        switchLevel.isEnabled = true
        switchRuns.isEnabled = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkPrivacy()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switchTrophies.isEnabled = false
        switchLevel.isEnabled = false
        switchRuns.isEnabled = false
    }
}
