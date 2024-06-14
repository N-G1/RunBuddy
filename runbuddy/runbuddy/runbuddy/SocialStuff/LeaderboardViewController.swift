//
//  LeaderboardViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 02/04/2024.
//

import UIKit

class LeaderboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var friends = userDictionary["acceptedFriendRequests"] as! [String]
    var friendsAndSteps: [(String, Double)] = [] //tuples with username and steps
    var sortedSteps: [(String, Double)] = []
    
    @IBOutlet weak var table: UITableView!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = table.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        
        guard sortedSteps.count != 0 else {
            return cell
        }
        
        var content = UIListContentConfiguration.cell()
        let steps = Int(sortedSteps[indexPath.row].1)
        content.text = "\(sortedSteps[indexPath.row].0): \(steps)"
        cell.contentConfiguration = content
        return cell
    }
    
    func getSteps() async {
        do {
            for i in 0..<friends.count{
                //get the username and the steps of each friend
                let currName = try await (db.collection("users").document(friends[i]).getDocument().data()!["username"] as! String)
                let steps = try await (db.collection("users").document(friends[i]).getDocument().data()!["totalOverallSteps"] as! Double)
                let todaysSteps = try await (db.collection("users").document(friends[i]).getDocument().data()!["dailySteps"] as! Double)
                friendsAndSteps.append((currName, steps + todaysSteps))
            }
        } catch{
          print("error: \(error)")
        }
        //append the logged in user
        let steps = userDictionary["totalOverallSteps"] as! Double
        let dailySteps = userDictionary["dailySteps"] as! Double
        friendsAndSteps.append((userDictionary["username"] as! String, steps + dailySteps))
        sortSteps()
    }
    
    func sortSteps(){
        //standard sorting closure but sort by the int in the tuples instead of the whole tuple
        sortedSteps = friendsAndSteps.sorted(by: { $0.1 > $1.1})
        table.reloadData()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Task {
            await HomeViewController().loadData()
            sortedSteps = []
            await getSteps()
        }
    }
}
