//
//  AllUsersController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 30/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class AllUsersController: UITableViewController {

    var filteredUsers = [UserInfo]()
    let searchController = UISearchController(searchResultsController: nil)
    
    var Users: [UserInfo] = []
    private var userReferenceHandle: DatabaseHandle? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setSearchController()
        observeUsers()
    }
    
    private func setSearchController () {
        self.searchController.searchResultsUpdater = self as! UISearchResultsUpdating
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.placeholder = "Search user"
        self.navigationItem.searchController = self.searchController
        definesPresentationContext = true
    }
    
    private func observeUsers() {
        userReferenceHandle = Constants.refs.databaseUsers.observe(.childAdded, with: { (snapshot) -> Void in
            let userData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if id != Auth.auth().currentUser?.uid {
                if let name = userData["name"] as! String!, name.characters.count > 0 {
                    let imageId = userData["imageID"] as! String!
                    let email = userData["email"] as! String!
                    let profileImageUrl = userData["profileImageUrl"] as! String!
                    self.Users.append(UserInfo(id: id, name: name, email: email, profileImageUrl: profileImageUrl, imageId: imageId))
                    self.tableView.reloadData()
                } else {
                    print("Error! Could not decode user data")
                }
            }
            else {
                print("Opps! It's me")
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.isFiltering() {
            return self.filteredUsers.count
        }
        else {
            return self.Users.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "allUsersCell", for: indexPath) as! AllUsersCell
        
        var users: [UserInfo] = []
        if self.isFiltering() {
            users = self.filteredUsers
        }
        else {
            users = self.Users
        }

        cell.nameLabel.text = users[indexPath.row].name
        cell.emailLabel.text = users[indexPath.row].email
        cell.idLabel.text = users[indexPath.row].id
        
        cell.addButton.tag = indexPath.row
        cell.addButton.addTarget(self, action: #selector(AddFriend(sender:)), for: .touchUpInside)

        var dispatchGroup = DispatchGroup()
        
        // Check in friendlist
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\((users[indexPath.row].id)!)/friends").observeSingleEvent(of: .value, with: {snapshot in
            debugPrint("\((users[indexPath.row].id)!)/\((Auth.auth().currentUser?.uid)!)")
            if snapshot.hasChild("\((Auth.auth().currentUser?.uid)!)") {
                cell.addButton.isHidden = true
            }
            dispatchGroup.leave()
        })
        
        // Check in request list
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\((users[indexPath.row].id)!)/requests").observeSingleEvent(of: .value, with: {snapshot in
            debugPrint("\((users[indexPath.row].id)!)/\((Auth.auth().currentUser?.uid)!)")
            if snapshot.hasChild("\((Auth.auth().currentUser?.uid)!)") {
                cell.addButton.isHidden = true
            }
            dispatchGroup.leave()
        })
        
        // Check in blacklist
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\((users[indexPath.row].id)!)/blacklist").observeSingleEvent(of: .value, with: {snapshot in
            debugPrint("\((users[indexPath.row].id)!)/\((Auth.auth().currentUser?.uid)!)")
            if snapshot.hasChild("\((Auth.auth().currentUser?.uid)!)") {
                cell.addButton.isHidden = true
            }
            dispatchGroup.leave()
        })
        
        // get url of user avatar
        dispatchGroup.enter()
        let imageUrl = users[indexPath.row].profileImageUrl
        if let imageUrl = imageUrl {
            let storage = Storage.storage()
            let ref = storage.reference(forURL: imageUrl as String)
            
            // Download the avatar from firebase storage
            ref.getData(maxSize: 5*1024*1024, completion: { (data, error) in
                if (error != nil) {
                    print("Can not load avatar. Error: \(error!)")
                    dispatchGroup.leave()
                }
                else {
                    cell.avatarImage.image = UIImage(data: data!)
                    cell.avatarImage.layer.cornerRadius = cell.avatarImage.bounds.width / 2
                    cell.avatarImage.layer.masksToBounds = true
                    dispatchGroup.leave()
                }
            })
        }
        else {
            print("Can not load avatar")
            dispatchGroup.leave()
        }
            
        
        // Wait until the observe finishes
        dispatchGroup.wait(timeout: .init(uptimeNanoseconds: 2000000000))
        
        return cell
    }

    @objc func AddFriend(sender: UIButton) {
        let row = sender.tag
        var user: UserInfo? = nil
        if self.isFiltering() {
            user = filteredUsers[row]
        }
        else {
            user = Users[row]
        }
        
        let confirmAlert = UIAlertController(title: "Add friend", message: "Do you want to add this user to your friend list", preferredStyle: .alert)
        let addAction = UIAlertAction(title: "Add", style: .default) { (UIAlertAction) in
            // Send a request
            Constants.refs.databaseUsers.child("/\((user?.id!)!)/requests/\((Auth.auth().currentUser?.uid)!)").updateChildValues(["name": (Auth.auth().currentUser?.displayName)!])
            sender.isHidden = true
            let announ = UIAlertController(title: "Add friend", message: "You sent add friend request successfully", preferredStyle: .alert)
            self.present(announ, animated: true, completion: nil)
            let when = DispatchTime.now() + 2
            DispatchQueue.main.asyncAfter(deadline: when, execute: {
                announ.dismiss(animated: true, completion: nil)
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        confirmAlert.addAction(addAction)
        confirmAlert.addAction(cancelAction)
        self.present(confirmAlert, animated: true, completion: nil)
        
    }
}

extension AllUsersController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        self.filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredUsers = Users.filter({( userInfo : UserInfo) -> Bool in
            return (userInfo.name?.lowercased().contains(searchText.lowercased()))! || (userInfo.email?.lowercased().contains(searchText.lowercased()))!
        })
        
        self.tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}
