//
//  HomeViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 23/02/2024.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CoreMotion

//global so can be accessed by all view controllers, will move eventually
let db = Firestore.firestore();
var userDictionary: [String: Any] = [:]
var stepsCompleted: Int = 0

//TODO: set default view controller to this if user login details are cached
class HomeViewController: UIViewController {
    @IBOutlet weak var lblSteps: UILabel!
    @IBOutlet weak var lblOverallSteps: UILabel!
    @IBOutlet weak var lblRunsCompleted: UILabel!
    @IBOutlet weak var lblTodaysCalories: UILabel!
    
    var submitNum: Int = 0;
    
    let userRef = db.collection("users").document(uid)
    var userUID: String!; //users id used to access their db information
    let stepTracker = CrossUsedMethods().stepTracker
    var tSteps: Int = 0
    var todaysSteps = 0
    
    ///empty all values that store user information when the user signs out, auth is handled via api
    @IBAction func btnSignOut(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            stepTracker.stopUpdates()
            userDictionary = [:]
            uid = "nil"
            performSegue(withIdentifier: "unwindToLogin", sender: self)
        } catch{
            print ("Error : \(error.localizedDescription)")
        }
    }
    
    func checkStepTracking(){
        let currState = CMPedometer.authorizationStatus()
        
        switch currState {
        case .authorized, .notDetermined:
            trackSteps()
        default:
            lblSteps.text = "Please enable step tracking"
        }
    }
    
    func trackSteps(){
        todaysSteps = userDictionary["dailySteps"] as! Int
        //closure to check for error or change the displayed number of steps if none
        stepTracker.startUpdates(from: Date()) { (data, error) in
            if let error = error {
                print("ERROR: \(error.localizedDescription)")
            } else if let data = data {
                DispatchQueue.main.async {
                    self.lblSteps.text = "\(Int(truncating: data.numberOfSteps) + self.todaysSteps)"
                    self.lblTodaysCalories.text = "\((Double(truncating: Int(truncating: data.numberOfSteps) + self.todaysSteps as NSNumber) * 0.04).rounded())"
                    stepsCompleted = Int(truncating: data.numberOfSteps)
                    
                    //in a production app saving every 50 steps would probably be inefficient but for
                    //the purpose of demonstration its set to 50
                    if stepsCompleted - self.submitNum >= 50 {
                        self.userRef.updateData(["dailySteps": stepsCompleted + self.todaysSteps])
                        Task {
                            await self.loadData()
                        }
                        self.submitNum = stepsCompleted
                    }
                }
            }
        }
    }
    
    public func saveData(){
        let sessionSteps = UserDefaults.standard.integer(forKey: "sessionSteps")
        userRef.updateData(["dailySteps": stepsCompleted + sessionSteps])
    }
    
    func displayInfo(){
        let steps = userDictionary["dailySteps"] as! Double
        lblOverallSteps.text = "\(userDictionary["totalOverallSteps"] ?? 0)"
        lblSteps.text = "\(userDictionary["dailySteps"] ?? 0)"
        lblTodaysCalories.text = "\(Int(steps * 0.04))"
    }
    
     /*
      Function that checks if the day has changed, if it has, reset the steps
      */
    func checkStepReset(){
        let reset = UserDefaults.standard.double(forKey: "resetLast")
        let storedDate = Date(timeIntervalSinceReferenceDate: reset)
        if (Date().timeIntervalSince(storedDate) / 3600) > 24 {
            resetSteps()
        }
    }
    
    /*
     Reset the steps and save the extra ones to the db
     */
    func resetSteps(){
        let steps = userDictionary["totalOverallSteps"] as! Double
        tSteps = userDictionary["dailySteps"] as! Int
        userRef.updateData(["totalOverallSteps": steps + Double(tSteps)])
        userRef.updateData(["dailySteps": 0])
        Task {
            await loadData() //load before to save right amount of steps
            UserDefaults.standard.set(0, forKey: "sessionSteps")
            stepTracker.stopUpdates()
            todaysSteps = 0
            tSteps = 0
            trackSteps()
            await loadData() //load after with new updated steps
            displayInfo()
            lblOverallSteps.text = "\(userDictionary["totalOverallSteps"] ?? 0)"
        }
        //record the last time the steps were reset
        UserDefaults.standard.set(Date().timeIntervalSinceReferenceDate, forKey: "resetLast")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Task {
            await loadData()
            displayInfo()
            checkStepTracking()
            UserDefaults.standard.set(userDictionary["dailySteps"] as! Int, forKey: "sessionSteps")
            tSteps = userDictionary["dailySteps"] as! Int
        }
        
        guard UserDefaults.standard.double(forKey: "resetLast") != 0 else {
            UserDefaults.standard.set(Date().timeIntervalSinceReferenceDate, forKey: "resetLast")
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        Task {
            await loadData()
            let runs = userDictionary["completedRuns"] as! [[String: Any]]
            checkStepReset()
            lblRunsCompleted.text = "\(runs.count)"
            
            let trophies = userDictionary["trophies"] as! [String:Bool]
            MapViewController.checkStepTrophies(trophies)
        }
    }
    
    public func loadData() async {
        do {
            userDictionary = try await userRef.getDocument().data()!
        }catch {
            print("error: \(error)")
        }
        
    }
}
