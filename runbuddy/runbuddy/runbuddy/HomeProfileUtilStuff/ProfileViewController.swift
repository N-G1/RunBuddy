//
//  ProfileViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 29/02/2024.
//

import UIKit

class ProfileViewController: UIViewController {
    @IBOutlet weak var lblNoRecentRuns: UILabel!
    @IBOutlet weak var lblLevel: UILabel!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblTrophyDesc: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var trophyImage0: UIImageView!
    @IBOutlet weak var trophyImage1: UIImageView!
    @IBOutlet weak var trophyImage2: UIImageView!
    @IBOutlet weak var trophyImage3: UIImageView!
    @IBOutlet weak var trophyImage4: UIImageView!
    @IBOutlet weak var trophyImage5: UIImageView!
    @IBOutlet weak var trophyImage6: UIImageView!
    @IBOutlet weak var trophyImage7: UIImageView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func loadProfileData(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
            FriendProfileViewController.initRuns(self.lblNoRecentRuns, self.scrollView, userDictionary["completedRuns"] as! [[String : Any]])
        }
        FriendProfileViewController.initLabels(lblUsername, lblLevel, userDictionary)
    }
    
    func clearMaps(){
        for s in scrollView.subviews {
           //dont remove the no recent runs label
            if s != lblNoRecentRuns {
                s.removeFromSuperview()
            }
        }
    }
    
    func displayTrophies(){
        let userTrophies = userDictionary["trophies"] as? [String: Bool]
        let collectedImg = UIImage(named: "TrophyPlaceholder")
        let notCollectedImg = UIImage(named: "PlaceholderCross")
        let trophyNames = ["addFirstFriend", "completeFirstRun", "complete5runs", "complete10runs", "complete50runs", "walk1000steps", "walk5000steps", "walk10000steps"]
        
        for i in 0..<8{
            let trophyImg = self.value(forKey: "trophyImage\(i)") as! UIImageView
            trophyImg.image = nil
            trophyImg.isHidden = false
            trophyImg.isUserInteractionEnabled = true;
            trophyImg.image = userTrophies![trophyNames[i]] == true ? collectedImg : notCollectedImg
            trophyImg.tag = i
            trophyImg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(trophyTapped)))
        }
    }
    @objc func trophyTapped(_ imagePressed: UITapGestureRecognizer){
        let tappedImage = imagePressed.view as? UIImageView
        
        //each image is tagged with a different value corresponding to a different trophy and
        //displays different text depending on that tag
        switch tappedImage!.tag {
        case 0:
            lblTrophyDesc.text = "Add one friend"
            break
        case 1:
            lblTrophyDesc.text = "Complete 1 run"
            break
        case 2:
            lblTrophyDesc.text = "Complete 5 runs"
            break
        case 3:
            lblTrophyDesc.text = "Complete 10 runs"
            break
        case 4:
            lblTrophyDesc.text = "Complete 50 runs"
            break
        case 5:
            lblTrophyDesc.text = "Walk/Run 1k steps"
            break
        case 6:
            lblTrophyDesc.text = "Walk/Run 5k steps"
            break
        case 7:
            lblTrophyDesc.text = "Walk/Run 10k steps"
            break
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Task{
            await HomeViewController().loadData()
        }

        clearMaps()
        loadProfileData()
        displayTrophies()
    }
    
}
