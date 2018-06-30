//
//  AddGroupChatViewController.swift
//  FireChat
//
//  Created by XuanNam on 6/29/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class AddGroupChatViewController: UIViewController {
    // Outlet
    
    @IBOutlet weak var img_AddPhoto: UIImageView!
    @IBOutlet weak var textField_GroupName: UITextField!
    @IBOutlet weak var textField_ListFriend: UITextField!
    @IBOutlet weak var listFriendTableView: UITableView!
    
    var Friends: [Friend] = []
    var Members: [String] = []
    private var friendReferenceHandle: DatabaseHandle? = nil
    private lazy var friendReference: DatabaseReference =
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/friends")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        initView()
        self.observeFriends()
    }
    
    //init
    
    func observeFriends() {
        friendReferenceHandle = friendReference.observe(.childAdded, with: { (snapshot) -> Void in
            let friendData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let friendName = friendData["friendName"] as! String?, friendName.characters.count > 0 {
                self.Friends.append(Friend(id: id, friendName: friendName))
                self.listFriendTableView.reloadData()
            } else {
                print("Error! Could not decode friend data")
            }
        })
    }
    
    func initView() {
        //tableView
        
        listFriendTableView.delegate = self
        listFriendTableView.dataSource = self
        
        img_AddPhoto.layer.cornerRadius = img_AddPhoto.frame.height / 2
        img_AddPhoto.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleAddPhoto)))
        img_AddPhoto.isUserInteractionEnabled = true
        
        //navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create Group", style: .plain, target: self, action: #selector(handleCreategroup))
        
        Members.append((Auth.auth().currentUser?.uid)!)
    }
    
    @objc func handleCreategroup() {
        guard let name = textField_GroupName.text else {
            return
        }
        
        let id = NSUUID().uuidString
        let imageID = NSUUID().uuidString
        
        let databaseRef = Database.database().reference().child("Group").child(id)
        let storeRef = Storage.storage().reference().child("\(imageID).png")
        
        if let uploadData = UIImagePNGRepresentation(img_AddPhoto.image!) {
            storeRef.putData(uploadData, metadata: nil) { (metaData, err) in
                if err != nil {
                    print(err as Any)
                    return
                }
                print("Save image successfully")
                storeRef.downloadURL(completion: { (url, err) in
                    if err != nil {
                        print(err as Any)
                        return
                    }
                    
                    let imageUrl = url?.absoluteString
                    let values = ["id": id, "name": name, "imageUrl": imageUrl, "imageId": imageID, "members": self.Members] as [String: AnyObject]
                    databaseRef.updateChildValues(values, withCompletionBlock: { (err, ref) in
                        if err != nil {
                            print(err as Any)
                            return
                        }
                        print("Success")
                    })
                })
            }
        }
    }
    
    @objc func handleAddPhoto() {
        
    }

}


//extension
extension AddGroupChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Friends.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = listFriendTableView.dequeueReusableCell(withIdentifier: "listFriendCell", for: indexPath) as! customListFriendCell
        
        if cell.isSelected
        {
            cell.isSelected = false
            if cell.accessoryType == UITableViewCellAccessoryType.none
            {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            }
            else
            {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
        }
        
        cell.lbl_Name.text = self.Friends[indexPath.row].friendName
        
        // To wait for the result of Observe Function
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        DispatchQueue.global(qos: .default).async {
            Constants.refs.databaseUsers.child("/\((self.Friends[indexPath.row].id)!)/profileImageUrl").observe(.value, with: {snap in
                
                // get url of user avatar
                let imageUrl = snap.value
                if let imageUrl = imageUrl{
                    let storage = Storage.storage()
                    let ref = storage.reference(forURL: imageUrl as! String)
                    
                    // Download the avatar from firebase storage
                    ref.getData(maxSize: 5*1024*1024, completion: { (data, error) in
                        if (error != nil) {
                            print("Can not load avatar. Error: \(error!)")
                            dispatchGroup.leave()
                        }
                        else {
                            cell.img_friend.image = UIImage(data: data!)
                            cell.img_friend.layer.cornerRadius = cell.img_friend.bounds.width / 2
                            cell.img_friend.layer.masksToBounds = true
                            dispatchGroup.leave()
                        }
                    })
                }
                else {
                    print("Can not load avatar")
                    dispatchGroup.leave()
                }
            })}
        
        // Wait until the observe finishes
        dispatchGroup.wait(timeout: .init(uptimeNanoseconds: 2000000000))
     
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        if cell!.isSelected
        {
            cell!.isSelected = false
            if cell!.accessoryType == UITableViewCellAccessoryType.none
            {
                Members.append(Friends[indexPath.row].id!)
                cell!.accessoryType = UITableViewCellAccessoryType.checkmark
            }
            else
            {
                let index = Members.index(where: { (item) -> Bool in
                    item == Friends[indexPath.row].id
                })
                Members.remove(at: index!)
                cell!.accessoryType = UITableViewCellAccessoryType.none
            }
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    
}






