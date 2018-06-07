//
//  FriendController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 07/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit

class FriendController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }

}
