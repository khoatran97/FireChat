//
//  ListFriendController.swift
//  FireChat
//
//  Created by XuanNam on 6/6/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit

class ListFriendController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //init navigation bar
        initNavigationBar()
    }
    
    func initNavigationBar() {
        let screenSize = UIScreen.main.bounds
        let height = screenSize.height * 0.09
        let width = screenSize.width
        
        let navBar: UINavigationBar = UINavigationBar(frame: CGRect(x: 0, y: 0, width: Int(width), height: Int(height)))
        view.addSubview(navBar)
        let navItem = UINavigationItem(title: "List Friend")
        navItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navBar.setItems([navItem], animated: true)
        
    }
    
    @objc func handleLogout() {
        print("Logout")
    }

}
