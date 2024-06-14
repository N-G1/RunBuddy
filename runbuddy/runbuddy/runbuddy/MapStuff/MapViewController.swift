//
//  MapViewController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 29/02/2024.
//

import UIKit
import MapKit
import FirebaseFirestore
import HealthKit

class MapViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var lblTimer: UILabel!
    @IBOutlet weak var lblSteps: UILabel!
    @IBOutlet weak var btnStart: UIButton!
    @IBOutlet weak var btnStop: UIButton!
    @IBOutlet weak var map: MKMapView!
    
    let locationManager = CLLocationManager()
    
    //users runs is stored as an array of dictionaries like follows A[0] - ["Calories": val, "EndPoint": val, "StartPoint": val, "Steps": val, "Time": val] | A[1] - .... | so each array val stores
    //all info on that particular run where EndPoint and StartPoint are geopoints (see FriendProfileViewController) and calories+ time + steps are integers (time in seconds)
    var usersRuns = userDictionary["completedRuns"] as? [[String: Any]]
    var currLocation: CLLocation!
    
    var firstTime: Bool = true
    
    //these two bools are used to save the start and end positions of the user when the buttons are pressed
    var startPressed: Bool = false
    var endPressed: Bool = false
    
    var startTracking: Bool = false
    
    var startAnnotation = MKPointAnnotation()
    var endAnnotation = MKPointAnnotation()
    
    var timer: Timer?
    var stepCounter: Timer?
    
    var timeTaken: Int = 0
    var steps: Double = 0 //set after run, steps - currSteps = steps completed during that run
    var prevRunSteps: Double = 0 //prevRunSteps set before run
    var startPoint: GeoPoint?
    var endPoint: GeoPoint?
    
    let stepTrackerAuth = HKHealthStore()
    
    @IBAction func btnStart(_ sender: Any) {
        resetVars()
        prevRunSteps = Double(stepsCompleted)
        //when the start button is pressed, save the location and place a marker on the map
        startAnnotation.title = "Start"
        startAnnotation.coordinate = CLLocationCoordinate2D(latitude: currLocation.coordinate.latitude, longitude: currLocation.coordinate.longitude)
        map.addAnnotation(startAnnotation)
        startPoint = GeoPoint(latitude: currLocation.coordinate.latitude, longitude: currLocation.coordinate.longitude)
        
        //when start is pressed, disable it, start timer, place annotation for start point
        btnStart.isEnabled = false
        btnStop.isEnabled = true
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        stepCounter = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSteps), userInfo: nil, repeats: true)
    }
    
    @objc func updateTime(){
        timeTaken += 1
        lblTimer.text = String(format: "%02d:%02d", (timeTaken / 60), (timeTaken % 60))
    }
    
    @objc func updateSteps(){
        if stepsCompleted - Int(prevRunSteps) < 0 {
            prevRunSteps = 0
        }
        lblSteps.text = "Steps: \(stepsCompleted - Int(prevRunSteps))"
    }
    
    @IBAction func btnStop(_ sender: Any) {
        steps = Double(stepsCompleted)
        //do the same as above for when end is pressed
        endAnnotation.title = "End"
        endAnnotation.coordinate = CLLocationCoordinate2D(latitude: currLocation.coordinate.latitude, longitude: currLocation.coordinate.longitude)
        map.addAnnotation(endAnnotation)
        endPoint = GeoPoint(latitude: currLocation.coordinate.latitude, longitude: currLocation.coordinate.longitude)
        
        btnStart.isEnabled = true
        btnStop.isEnabled = false
        saveRun()
        timer?.invalidate()
        stepCounter?.invalidate()
    }
    
    /*
     Saves all information about the run that has just been completed by the user into the database including XP and run info
     */
    func saveRun(){
        let docRef = db.collection("users").document(uid)
        let stepsAfterRun = steps - prevRunSteps
        //average calories burned per step is 0.04
        let calories = Double(stepsAfterRun) * 0.04
        usersRuns?.append(["Calories": calories, "EndPoint": endPoint!, "StartPoint": startPoint!, "Steps": stepsAfterRun, "Time": timeTaken])
        docRef.updateData(["completedRuns": usersRuns!])
        //update the xp at a rate of 1 xp per 100 steps
        let xp = userDictionary["XP"] as! Int
        docRef.updateData(["XP": xp + Int(ceil(steps / 100))])
    
        
        checkLevelUp(xp ,docRef)
        
        let trophies = userDictionary["trophies"] as! [String:Bool]
        checkRunTrophies(trophies)
        
        MapViewController.checkStepTrophies(trophies)
        
        //reload data once new stats have been recorded
        Task{
            await HomeViewController().loadData()
        }
    }
    
    /*
     Checks if the user has passed the threshold to level up and does so in the event that they have
     */
    func checkLevelUp(_ xp: Int, _ docRef: DocumentReference){
        //For level, 100 xp to level up, 1 xp per 100 steps so 10k steps a level just incremement level when xp goes over 100 and carry over the extra xp 
        let level = userDictionary["level"] as! Int
        while xp >= 100 {
            docRef.updateData(["level": level + 1])
            docRef.updateData(["XP": xp - 100])
        }
    }
    
    func checkRunTrophies(_ trophies: [String:Bool]){
        
        //If the user has completed 50 runs then they already have all achievements
        guard usersRuns!.count < 50 else {
            return
        }
        
        
        
        if trophies["complete50runs"] != true && usersRuns!.count == 50 {
            Task {
                await CrossUsedMethods.checkTrophy("complete50runs")
            }
        }
        else if trophies["complete10runs"] != true && usersRuns!.count >= 10 {
            Task {
                await CrossUsedMethods.checkTrophy("complete10runs")
            }
        }
        else if trophies["complete5runs"] != true && usersRuns!.count >= 5 {
            Task {
                await CrossUsedMethods.checkTrophy("complete5runs")
            }
        }
        else if trophies["completeFirstRun"] != true && usersRuns!.count == 1 {
            Task {
                await CrossUsedMethods.checkTrophy("completeFirstRun")
            }
        }
    }
    
    /*
     Checks if the user has achieved any step trophies after the run
     */
    public static func checkStepTrophies(_ trophies: [String:Bool]){
        let steps = userDictionary["totalOverallSteps"] as! Double
        let todaySteps = userDictionary["dailySteps"] as! Double
        
        if (trophies["walk10000Steps"] != true && steps >= 10000) || (trophies["walk10000Steps"] != true && todaySteps >= 10000){
            Task {
                await CrossUsedMethods.checkTrophy("walk10000steps")
            }
        }
        else if (trophies["walk5000Steps"] != true && steps >= 5000) || (trophies["walk5000Steps"] != true && todaySteps >= 10000) {
            Task {
                await CrossUsedMethods.checkTrophy("walk5000steps")
            }
        }
        else if (trophies["walk1000Steps"] != true && steps >= 1000) || (trophies["walk1000Steps"] != true && todaySteps >= 10000) {
            Task {
                await CrossUsedMethods.checkTrophy("walk1000steps")
            }
        }
    }
    
    /*
     resets all tracking and visible information such as steps, time, and remove the start and end pin, reset vars is called in the start button not the end as the run information will still be
     displayed until the next run is started so the user can view their stats for as long as they would wish to
     */
    func resetVars(){
        timeTaken = 0
        //reload as new run has been saved
        Task {
            await HomeViewController().loadData()
            usersRuns = userDictionary["completedRuns"] as? [[String: Any]]
        }
        //remove and void the start and endn annnotation points
        map.removeAnnotation(startAnnotation)
        map.removeAnnotation(endAnnotation)
        startAnnotation = MKPointAnnotation()
        endAnnotation = MKPointAnnotation()
    }
    
    ///function that tracks the users location and displays it on the map
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]){
        currLocation = locations[0]
        let location = CLLocationCoordinate2D(latitude: currLocation.coordinate.latitude, longitude: currLocation.coordinate.longitude)
        
        if firstTime {
            firstTime = false
            let span = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
            let region = MKCoordinateRegion(center: location, span: span)
            map.setRegion(region, animated: true)
            _ = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(track), userInfo: nil, repeats: false)
        }
        
        //probably dont need this and the function below, remove maybe 
        if startTracking {
            map.setCenter(location, animated: true)
        }
    }
    
    @objc func track(){
        startTracking = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self as CLLocationManagerDelegate
        //use best for navigation so the user can actively see where they are in a reasonable amount of detail
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //request user auth
        locationManager.requestWhenInUseAuthorization()
        //update once auth has been recieved
        locationManager.startUpdatingLocation()
        map.showsUserLocation = true
        
        
        btnStop.isEnabled = false;
    }
}
