//
//  RequestController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 30/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class BlacklistController: UITableViewController {

    var Users: [UserInfo] = []
    private var userReferenceHandle: DatabaseHandle? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeUsers()
    }
    
    private func observeUsers() {
        userReferenceHandle = Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/blacklist").observe(.childAdded, with: { (snapshot) -> Void in
            let userData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if id != Auth.auth().currentUser?.uid {
                if let name = userData["name"] as! String!, name.characters.count > 0 {
                    self.Users.append(UserInfo(id: id, name: name, email: nil, profileImageUrl: nil, imageId: nil))
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
        return self.Users.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blacklistCell", for: indexPath) as! BlacklistCell

        cell.nameLabel.text = Users[indexPath.row].name!
        cell.deleteButton.addTarget(self, action: #selector(Delete(sender:)), for: .touchUpInside)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\(Users[indexPath.row].id!)/profileImageUrl").observeSingleEvent(of: .value) { (snapshot) in
            if snapshot.exists() {
                print(snapshot.value as! String)
                if let imageUrl = snapshot.value {
                    let storage = Storage.storage()
                    let ref = storage.reference(forURL: imageUrl as! String)
                    
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
            }
        }
        
        // Wait until the observe finishes
        dispatchGroup.wait(timeout: .init(uptimeNanoseconds: 2000000000))
        
        return cell
    }
    
    @objc func Delete(sender: UIButton) {
        let row = sender.tag
        let user = Users[row]
        
        // Delete blocked user
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/blacklist/\(user.id!)").removeValue()
        
        self.Users.remove(at: row)
        self.tableView.reloadData()
    }

}
