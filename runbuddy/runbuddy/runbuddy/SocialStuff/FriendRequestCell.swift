//
//  FriendRequestCell.swift
//  runbuddy
//
//  Created by Gill, Nathan on 04/03/2024.
//

import UIKit
import FirebaseFirestore

///Custom logic for friend request cells including accept friend button logic 
class FriendRequestCell: UITableViewCell {
    @IBOutlet weak var lblUsername: UILabel!
    
    @IBAction func btnAccept(_ sender: Any) {
        Task {
            await removeFromRequest()
        }
    }
    
    var cellDelegate: FriendRequestCellDelegate?
    
    
    ///Removes a user from the friend request sent page, then calls addToFriends to add them to friends list
    ///Called when a friend is accepted
    public func removeFromRequest() async {
        do {
            //user currently logged in
            var UIDs = userDictionary["recievedFriendRequests"] as! [String]
            
            //user
            let userDocRef = db.collection("users").document(uid)
            
            //user to remove from requests
            let userToMove = try await db.collection("users").whereField("username", isEqualTo: lblUsername.text!).getDocuments()
            
            
            //search through UIDs to remove from recievedFriendRequests
            for i in 0..<UIDs.count{
                if UIDs[i] == userToMove.documents[0].documentID{
                    UIDs.remove(at: i)
                }
            }
            try await userDocRef.updateData(["recievedFriendRequests": UIDs])
            //reload the user data after the UID is removed
            await HomeViewController().loadData()
            
            //move to added friends
            await addToFriends(userToMove.documents[0].documentID, userToMove, userDocRef)
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    ///Appends each UID of the sending and recieving user to the other persons friends, e.g, the sending user is added to the recieving users friends
    ///and vice versa
    func addToFriends(_ uidToAdd: String, _ otherUser: QuerySnapshot, _ userDocRef: DocumentReference) async {
        do {
            //Append the sending users UID to the accepted users friends
            var addedFriends = userDictionary["acceptedFriendRequests"] as! [String]
            addedFriends.append(uidToAdd)
            try await userDocRef.updateData(["acceptedFriendRequests": addedFriends])
            
            //Append the recieving users UID to the sending users accepted friends
            var otherUsersFriends = otherUser.documents[0].data()["acceptedFriendRequests"] as! [String]
            otherUsersFriends.append(uid)
            let otherUserDocRef = db.collection("users").document(uidToAdd)
            try await otherUserDocRef.updateData(["acceptedFriendRequests": otherUsersFriends])
            await HomeViewController().loadData()
            cellDelegate?.reloadAllData()
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

///delegate protocol for reloading the table and the data associated with it
protocol FriendRequestCellDelegate {
    func reloadAllData()
}
