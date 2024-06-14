//
//  CrossUsedMethods.swift
//  runbuddy
//
//  Created by Gill, Nathan on 05/03/2024.
//

import UIKit
import CoreMotion

class CrossUsedMethods {
    public let stepTracker = CMPedometer()
    public var runInProgress = false;
    
    public static func displayAlert(_ msg: String, _ vc: UIViewController){
        let alert = UIAlertController(title: msg, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        vc.present(alert, animated: true)
    }
    
    /*
     Takes a trophy that needs to be set to true (as in a user has achieved it)
     
     - Parameter: trophyName trophy to be set to true
     */
    public static func checkTrophy(_ trophyName: String) async {
        let docRef = db.collection("users").document(uid)
        do {
            var trophies = try await db.collection("users").document(uid).getDocument().data()!["trophies"] as! [String: Bool]
            trophies[trophyName] = true
            try await docRef.updateData(["trophies": trophies])
            //reload data
            await HomeViewController().loadData()
        } catch{
          print("error: \(error)")
        }
    }
}
