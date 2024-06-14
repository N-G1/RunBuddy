//
//  FriendCell.swift
//  runbuddy
//
//  Created by Gill, Nathan on 05/03/2024.
//

import UIKit

class FriendCell: UITableViewCell {
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblUID: UILabel!
    
    var cellDelegate: FriendCellDelegate?
    
    @IBAction func btnRemoveFriend(_ sender: Any) {
        Task {
            await removeFriend()
        }
    }
    
    func removeFriend() async {
        do {
            
            //User to remove
            let userToRemove = try await db.collection("users").whereField("username", isEqualTo: lblUsername.text!).getDocuments()
            //Reference to user to removes document
            let userToRemoveRef = db.collection("users").document(userToRemove.documents[0].documentID)
            //User logged in
            let userDocRef = db.collection("users").document(uid)
            
            var addedFriends = userDictionary["acceptedFriendRequests"] as! [String]
            var otherUsersFriends = userToRemove.documents[0].data()["acceptedFriendRequests"] as! [String]
            
            //remove from logged in users friends
            for i in 0..<addedFriends.count{
                if addedFriends[i] == userToRemove.documents[0].documentID{
                    addedFriends.remove(at: i)
                }
            }
            try await userDocRef.updateData(["acceptedFriendRequests": addedFriends])
            
            //remove from other users friends
            for i in 0..<otherUsersFriends.count{
                if otherUsersFriends[i] == uid{
                    otherUsersFriends.remove(at: i)
                }
            }
            try await userToRemoveRef.updateData(["acceptedFriendRequests": otherUsersFriends])
            
            
            await HomeViewController().loadData()
            cellDelegate?.loadFriendData()
            
        } catch {
            print("error: \(error.localizedDescription)")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

///delegate protocol for reloading the table similar to friend requests
protocol FriendCellDelegate {
    func loadFriendData()
}
