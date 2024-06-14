//
//  FriendRequestsViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 01/03/2024.
//

import UIKit



//TODO: Add max friend limit, max amount of requests limit 
class FriendRequestsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FriendRequestCellDelegate {
    @IBOutlet weak var txtUserToAdd: UITextField!
    @IBOutlet weak var lblNoPending: UILabel!
    @IBOutlet weak var table: UITableView!
    
    var sentReqUID: [String] = userDictionary["recievedFriendRequests"] as! [String]
    var sentReqUsernames: [String] = []
    
    @IBAction func btnAddFriend(_ sender: Any) {
        guard txtUserToAdd.text != nil else {
            return
        }
        
        Task {
            await sendRequest()
        }
        
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return sentReqUID.count
    }
    
    func sendRequest() async {
        do {
            let user = try await db.collection("users").whereField("username", isEqualTo: txtUserToAdd.text!).getDocuments()
            
            //check if the user exists
            guard user.documents.count == 1 else{
                CrossUsedMethods.displayAlert("User does not exist", self)
                txtUserToAdd.text! = ""
                return
            }
            
            let usersFriends = user.documents[0].data()["acceptedFriendRequests"] as! [String]
            var requests = user.documents[0].data()["recievedFriendRequests"] as! [String]
            
            //check if you are friends with the user already
            guard !(checkUserIsAlreadyFriend(usersFriends)) else {
                CrossUsedMethods.displayAlert("You are already friends with this user", self)
                return
            }
            //check if you already sent a friend request to this user 
            guard !(checkExistingRequests(requests)) else {
                CrossUsedMethods.displayAlert("You have already requested to friend this user", self)
                return
            }
            
            //document reference is required to update data as .data() is immutable
            let docRef = db.collection("users").document(user.documents[0].documentID)
            
            //check if the user tries their own username
            guard docRef.documentID != uid else {
                CrossUsedMethods.displayAlert("You can't send a request to yourself", self)
                return
            }
            
            //append new request to existng requests
            requests.append(uid)
            
            //update the requests with the user that sent the friend request
            try await docRef.updateData(["recievedFriendRequests": requests])
            CrossUsedMethods.displayAlert("Friend request sent", self)
            Task {
               await HomeViewController().loadData()
            }
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    ///Checks if the sending user is already a friend of the recieving user
    func checkUserIsAlreadyFriend(_ friends: [String]) -> Bool {
        for i in 0..<friends.count{
            if friends[i] == uid {
                return true
            }
        }
        return false
    }
    
    ///Checks if the sending users UID is already in the recieving users existing friend requests
    func checkExistingRequests(_ existingRequests: [String]) -> Bool {
        for i in 0..<existingRequests.count{
            if existingRequests[i] == uid {
                return true
            }
        }
        return false
    }
    
    func getRequestingUsers() async{
        do {
            for i in 0..<sentReqUID.count{
                //get each UID stored in the userDictionaries pending requests, get their usernnames and save them to be displayed
                sentReqUsernames.append(try await (db.collection("users").document(sentReqUID[i]).getDocument().data()!["username"] as? String)!)
            }
        } catch{
          print("error: \(error)")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendRequestCell
        
        guard sentReqUsernames.count != 0 else{
            return cell
        }
        
        //delegate control to cell for reloading data if a user adds a friend (without this, table cant be reloaded afterwards)
        cell.cellDelegate = self
        
        cell.lblUsername.text = sentReqUsernames[indexPath.row]
        return cell
    }
    
    ///Called after a user has accepted a request via the accept button a cell
    ///Resets UID's and usernames to be displayed
    func reloadAllData(){
        sentReqUID = userDictionary["recievedFriendRequests"] as! [String]
        sentReqUsernames = []
        Task {
            await getRequestingUsers()
        }
        table.reloadData()
    }
    
    override func viewDidLoad() {
        Task{
            await getRequestingUsers()
            table.reloadData()
        }
        //register the custom cell in the table
        table.register(UINib(nibName: "FriendRequestCell", bundle: nil), forCellReuseIdentifier: "cell")
        
        if sentReqUID.count == 0{
            lblNoPending.isEnabled = true
        }
        else {
            lblNoPending.isHidden = true
        }
        super.viewDidLoad()
    }
}


//MARK: UI Tests
///Sent request when user is already friends
///Sent when they have an existing request
///Sent when they are not friends
///Sent if the user doesnt exist
///Sent request to self
