//
//  RequestController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 30/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class RequestController: UITableViewController {

    var Request: [UserInfo] = []
    private var requestReferenceHandle: DatabaseHandle? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeRequests()
    }
    
    private func observeRequests() {
        requestReferenceHandle = Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/requests").observe(.childAdded, with: { (snapshot) -> Void in
            let userData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if id != Auth.auth().currentUser?.uid {
                if let name = userData["name"] as! String!, name.characters.count > 0 {
                    self.Request.append(UserInfo(id: id, name: name, email: nil, profileImageUrl: nil, imageId: nil))
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
        return self.Request.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "requestCell", for: indexPath) as! RequestCell

        cell.nameLabel.text = Request[indexPath.row].name!
        cell.idLabel.text = Request[indexPath.row].id!
        cell.acceptButton.tag = indexPath.row
        cell.acceptButton.addTarget(self, action: #selector(Accept(sender:)), for: .touchUpInside)
        cell.rejectButton.addTarget(self, action: #selector(Reject(sender:)), for: .touchUpInside)
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\(Request[indexPath.row].id!)/profileImageUrl").observeSingleEvent(of: .value) { (snapshot) in
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
    
    @objc func Accept(sender: UIButton) {
        let row = sender.tag
        let user = Request[row]
        
        // Add to friend list
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/friends/\(user.id!)").updateChildValues(["friendName": user.name!])
        Constants.refs.databaseUsers.child("/\(user.id!)/friends/\((Auth.auth().currentUser?.uid)!)").updateChildValues(["friendName": (Auth.auth().currentUser?.displayName)!])
        
        // Delete request
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/requests/\(user.id!)").removeValue()
        
        self.Request.remove(at: row)
        self.tableView.reloadData()
    }
    
    @objc func Reject(sender: UIButton) {
        let row = sender.tag
        let user = Request[row]
        
        let confirmAlert = UIAlertController(title: "Reject request", message: "", preferredStyle: .actionSheet)
        let rejectAction = UIAlertAction(title: "Reject", style: .default) { (UIAlertAction) in
            Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/requests/\(user.id!)").removeValue()
            self.Request.remove(at: row)
            self.tableView.reloadData()
        }
        let blockAction = UIAlertAction(title: "Prevent this user from sending you request", style: .destructive) { (UIAlertAction) in
            Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/requests/\(user.id!)").removeValue()
            Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/blacklist/\(user.id!)").updateChildValues(["name": user.name!])
            self.Request.remove(at: row)
            self.tableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        confirmAlert.addAction(rejectAction)
        confirmAlert.addAction(blockAction)
        confirmAlert.addAction(cancelAction)
        
        self.present(confirmAlert, animated: true, completion: nil)
    }

}
