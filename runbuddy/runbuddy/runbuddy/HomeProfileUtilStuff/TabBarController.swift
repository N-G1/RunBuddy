//
//  TabBarController.swift
//  runbuddy
//
//  Created by Gill, Nathan on 29/02/2024.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let vc1 = SocialViewController()
        vc1.title = "Social"
        let vc2 = HomeViewController()
        vc2.title = "Home"
        let vc3 = ProfileViewController()
        vc3.title = "Profile"
        let vc4 = MapViewController()
        vc4.title = "Map"
        
        self.viewControllers = [vc1,vc2,vc3,vc4]
    }
}
