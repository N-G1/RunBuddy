//
//  FriendProfileViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 11/03/2024.
//

import UIKit
import FirebaseFirestore
import MapKit

class FriendProfileViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var lblLevel: UILabel!
    @IBOutlet weak var lblUsername: UILabel!
    @IBOutlet weak var lblNoRecentRuns: UILabel!
    @IBOutlet weak var lblTrophyDesc: UILabel!
    @IBOutlet weak var lblTrophies: UILabel!
    @IBOutlet weak var lblRecentRuns: UILabel!
    
    //can only make these an array in code for some reason
    @IBOutlet weak var trophyImage0: UIImageView!
    @IBOutlet weak var trophyImage1: UIImageView!
    @IBOutlet weak var trophyImage2: UIImageView!
    @IBOutlet weak var trophyImage3: UIImageView!
    @IBOutlet weak var trophyImage4: UIImageView!
    @IBOutlet weak var trophyImage5: UIImageView!
    @IBOutlet weak var trophyImage6: UIImageView!
    @IBOutlet weak var trophyImage7: UIImageView!
    
    //document reference is required to update data
    var passedUserDocRef: DocumentReference!
    //snapshot is required to recieve it
    var passedUserData: QuerySnapshot!
    var usersRuns: [[String: Any]]!
    
    public static func initLabels(_ username: UILabel, _ level: UILabel, _ passedUserInfo: [String : Any]){
        username.text = passedUserInfo["username"] as? String
        //TODO: Change this capital to lowercase
        level.text = ("Level \(passedUserInfo["level"] as? Int ?? 0)")
    }
    
    /*
     Initialises a users trophies for display on their account
     */
    func initTrophies(){
        let userTrophies = passedUserData.documents[0].data()["trophies"] as? [String: Bool]
        let collectedImg = UIImage(named: "TrophyPlaceholder")
        let notCollectedImg = UIImage(named: "PlaceholderCross")
        let trophyNames = ["addFirstFriend", "completeFirstRun", "complete5runs", "complete10runs", "complete50runs", "walk1000steps", "walk5000steps", "walk10000steps"]
        
        for i in 0..<8{
            let trophyImg = self.value(forKey: "trophyImage\(i)") as! UIImageView
            trophyImg.isHidden = false
            trophyImg.isUserInteractionEnabled = true;
            trophyImg.image = userTrophies![trophyNames[i]] == true ? collectedImg : notCollectedImg
            trophyImg.tag = i
            trophyImg.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(trophyTapped)))
        }
    }
    
    /*
     Handles what to change the label to when a specific image is pressed
     */
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
    
    /*
     Handles getting the run information from the database and displaying it to the
     user, accessed by both regular profile and friend profiles
     */
    public static func initRuns(_ lblNoRecentRuns: UILabel, _ scView: UIScrollView, _ runs: [[String: Any]]){
        //display all runs if < 5 and latest 5 if greater
        let latestRuns = runs.count < 5 ? runs.count : 5
        var space = 0
        guard latestRuns != 0 else {
            lblNoRecentRuns.isEnabled = true
            return
        }
        scView.isHidden = false
        lblNoRecentRuns.isEnabled = false
        let startingIndex = runs.count - latestRuns
        //.reversed so start from last element, if there is a ..> or equivalent operator i cant find it
        for i in (startingIndex..<runs.count).reversed() {
            //allows a gap of 75 pixels between each map to display information, with the labels being displayed between them
            let mapSpacing = CGFloat(space) * 425
            
            //creates a square map where the y position changes depending on the index, allowing them to be displayed vertically
            let runMap = MKMapView(frame: CGRect(x: 0, y: mapSpacing, width: 350, height: 350))
            runMap.isScrollEnabled = false;
            runMap.isZoomEnabled = false;
            scView.addSubview(runMap)
            
            
            //the start and end locations are stored as geopoints allowing them to be easily displayed on a map in swift
            let startPoint = runs[i]["StartPoint"] as? GeoPoint
            let endPoint = runs[i]["EndPoint"] as? GeoPoint
            
            //creates a visible point on the map for the start location
            let startAnnotation = MKPointAnnotation()
            startAnnotation.title = "Start"
            startAnnotation.coordinate = CLLocationCoordinate2D(latitude: startPoint!.latitude, longitude: startPoint!.longitude)
            runMap.addAnnotation(startAnnotation)
            
            //creates a visible point on the map for the end location
            let endAnnotation = MKPointAnnotation()
            endAnnotation.title = "End"
            endAnnotation.coordinate = CLLocationCoordinate2D(latitude: endPoint!.latitude, longitude: endPoint!.longitude)
            runMap.addAnnotation(endAnnotation)
            
            let lblSteps = UILabel(frame: CGRect(x: 0, y: mapSpacing + 350, width: scView.frame.size.width, height: 20))
            lblSteps.text = ("Steps travelled: \(runs[i]["Steps"] ?? "{error}")")
            scView.addSubview(lblSteps)
            
            let lblCalories = UILabel(frame: CGRect(x: 0, y: mapSpacing + 370, width: scView.frame.size.width, height: 20))
            lblCalories.text = ("Calories burned: \(runs[i]["Calories"] ?? "{error}")")
            scView.addSubview(lblCalories)
            
            let lblTime = UILabel(frame: CGRect(x: 0, y: mapSpacing + 390, width: scView.frame.size.width, height: 20))
            let time = round((runs[i]["Time"] as! Double) / 60)
            lblTime.text = ("Time taken: \(time) mins")
            scView.addSubview(lblTime)
            
            //creates a region of an appropriate size to view the start and end points, the centre is between both of these points
            //set the span such that the edges of the map are where the start and end points are, * 1.2 to ensure they are not on the exact edge
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (startPoint!.latitude + endPoint!.latitude) / 2, longitude: (startPoint!.longitude + endPoint!.longitude) / 2), span: MKCoordinateSpan(latitudeDelta: abs(startPoint!.latitude - endPoint!.latitude) * 1.2, longitudeDelta: abs(startPoint!.longitude - endPoint!.longitude) * 1.2))
            runMap.setRegion(region, animated: true)
            space += 1
        }
        //sets the full size of the scrollView to ensure everything fits while not containiing any uneccessary space
        scView.contentSize = CGSize(width: scView.frame.size.width, height: CGFloat(latestRuns) * 425)
    }
    
    /*
     Hides the relevant UI elements in the event the users privacy settings are different to standard
     */
    func checkPrivacy(){
        let trophyPrivacy = passedUserData.documents[0].data()["trophiesDisplayed"] as! Bool
        let levelPrivacy = passedUserData.documents[0].data()["levelDisplayed"] as! Bool
        
        
        if !levelPrivacy {
            lblLevel.text = "Level hidden"
        }
        
        if !trophyPrivacy {
            for i in 0..<8{
                let trophyImg = self.value(forKey: "trophyImage\(i)") as! UIImageView
                trophyImg.isHidden = true
                trophyImg.isUserInteractionEnabled = false;
            }
            lblTrophies.text = "Trophies hidden"
        }
        else {
            lblTrophies.text = "Trophies"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        lblTrophyDesc.text = ""
        Task{
            await HomeViewController().loadData()
        }
    }        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usersRuns = passedUserData.documents[0].data()["completedRuns"] as? [[String: Any]]
        let runPrivacy = passedUserData.documents[0].data()["runsDisplayed"] as! Bool
        if !runPrivacy {
            scrollView.isHidden = true
            lblRecentRuns.text = "Recent runs hidden"
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                FriendProfileViewController.initRuns(self.lblNoRecentRuns, self.scrollView, self.usersRuns)
            }
            scrollView.isHidden = false
            lblRecentRuns.text = "Recent runs"
        }
        FriendProfileViewController.initLabels(lblUsername, lblLevel, passedUserData.documents[0].data())
        initTrophies()
        checkPrivacy()
    }
}
