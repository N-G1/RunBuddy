//
//  SocialViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 29/02/2024.
//

import UIKit
import FirebaseFirestore

//store a list element containing the uid's of each member who has sent a request to a particular user, followed by a list called 'accepted requests' (which will act as the friends list)
//users can send friend requests based on username, which will correspond to a UID which will correspond to a document, which will be able to access all info on that particular member

//remove friend = delete from acceptedFriendRequests,
//decline friend request = remove from recievedFriendRequests,
//accept = move from recievedFriendRequests to acceptedFriendRequests
//secondary feature: unsend request = remove from that users recievedFriendRequests


//TODO: Friends only refresh when visiting the homepage, fix
class SocialViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FriendCellDelegate {
    @IBOutlet weak var table: UITableView!
    
    //when removing a friend, it seems redundant to get the UID again when they are stored here, however the order is not guaranteed to
    //be the same each time, so instead of getting it here, it is grabbed again when removefriend is pressed in friendCell
    var usersFriends: [String] = []
    var friendUsernames: [String] = []
    
    var tappedUserUID: String!
    var tappedUserData: QuerySnapshot!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersFriends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FriendCell
        
        guard friendUsernames.count != 0 else{
            return cell
        }
        cell.cellDelegate = self
        cell.lblUsername.text = friendUsernames[indexPath.row]
        return cell
    }
    
    /*
     Handles when a cell is tapped to view a friends profile
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
        let cell = tableView.cellForRow(at: indexPath) as! FriendCell
        //set the UID of the tapped user to be passed to the profile page
        Task {
            tappedUserData = try await db.collection("users").whereField("username", isEqualTo: cell.lblUsername.text!).getDocuments()
            tappedUserUID = tappedUserData.documents[0].documentID
            performSegue(withIdentifier: "toFriendProfile", sender: self)
        }
    }
    
    func getFriends() async{
        do {
            for i in 0..<usersFriends.count{
                //get each UID of the users friends and save their username for display
                friendUsernames.append(try await (db.collection("users").document(usersFriends[i]).getDocument().data()!["username"] as? String)!)
            }
        } catch{
          print("error: \(error)")
        }
    }
    
    func loadFriendData(){
        usersFriends = userDictionary["acceptedFriendRequests"] as! [String]
        friendUsernames = []
        Task {
            await getFriends()
            table.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toFriendProfile" {
            let friendVC = segue.destination as! FriendProfileViewController
            friendVC.passedUserDocRef = db.collection("users").document(tappedUserUID!)
            friendVC.passedUserData = tappedUserData
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadFriendData()
        Task {
            await HomeViewController().loadData()
            
            //check users first friend achievement
            let trophies = userDictionary["trophies"] as! [String:Bool]
            if (trophies["addFirstFriend"] != true && usersFriends.count == 1){
                await CrossUsedMethods.checkTrophy("addFirstFriend")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //register the custom cell in the table
        table.register(UINib(nibName: "FriendCell", bundle: nil), forCellReuseIdentifier: "cell")
    }
}
