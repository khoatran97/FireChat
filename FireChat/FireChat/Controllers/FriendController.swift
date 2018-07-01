//
//  FriendController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 07/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class FriendController: UIViewController {

    @IBOutlet weak var friendTableView: UITableView!
    @IBOutlet weak var qrButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    var conversationDelegate: ConversationDelegate? = nil
    
    private lazy var friendReference: DatabaseReference =
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/friends")
    private var friendReferenceHandle: DatabaseHandle? = nil
    
    var Friends: [Friend] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.qrButton.layer.cornerRadius = self.qrButton.bounds.width / 2
        self.addButton.layer.cornerRadius = self.addButton.bounds.width / 2
        self.observeFriends()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == nil) {
            return;
        }
        if (segue.identifier! == "segueFriendToChat") {
            var chatView = segue.destination as! ChatController
            self.conversationDelegate = chatView
        }
    }

    private func observeFriends() {
        friendReferenceHandle = friendReference.observe(.childAdded, with: { (snapshot) -> Void in
            let friendData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let friendName = friendData["friendName"] as! String!, friendName.characters.count > 0 {
                self.Friends.append(Friend(id: id, friendName: friendName))
                self.friendTableView.reloadData()
            } else {
                print("Error! Could not decode friend data")
            }
        })
    }
    
    @IBAction func addButton_TouchUpInside(_ sender: Any) {
        let addAlert = UIAlertController(title: "Add Friend", message: "How do you want to add your friend?", preferredStyle: .actionSheet)
        let scanQR = UIAlertAction(title: "Scan QR code", style: .default) {(UIAlertAction) -> Void in
            // Open scan view
        }
        let search = UIAlertAction(title: "Search", style: .default) { (UIALertAction) in
            self.performSegue(withIdentifier: "segueToAllUsers", sender: self)
        }
        addAlert.addAction(scanQR)
        addAlert.addAction(search)
        self.present(addAlert, animated: true, completion: nil)
    }
    
    @IBAction func editButton_TouchUpInside(_ sender: UIBarButtonItem) {
        if self.friendTableView.isEditing {
            self.friendTableView.setEditing(false, animated: true)
            sender.title = "Edit"
            //sender.image = UIImage(named: "edit")
        }
        else {
            self.friendTableView.setEditing(true, animated: true)
            sender.title = "Done"
            //sender.image = UIImage(named: "done")
        }
    }
    
}

extension FriendController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserCell
        cell.name.text = self.Friends[indexPath.row].friendName
        
        // To wait for the result of Observe Function
        var dispatchGroup = DispatchGroup()
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
                            cell.avatar.image = UIImage(data: data!)
                            cell.avatar.layer.cornerRadius = cell.avatar.bounds.width / 2
                            cell.avatar.layer.masksToBounds = true
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
        
        // Check if the conversation with the user clicked is exist
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/conversations").queryOrdered(byChild: "receiverId").queryEqual(toValue: (Friends[indexPath.row].id)!).observe(.value, with: { (snapshot) in
            
            // If exist
            if snapshot.exists() {
                
                // Get the conversation information
                let conversationData = snapshot.value! as! [String: [String: AnyObject]]
                let id = (conversationData.first?.key)!
                let receiverId = (conversationData.first?.value as [String: AnyObject]!)["receiverId"]!
                let receiverName = (conversationData.first?.value as [String: AnyObject]!)["receiverName"]!
                
                // Show the chat view with the information as parameter
                self.performSegue(withIdentifier: "segueFriendToChat", sender: self)
                self.conversationDelegate?.SetChatView(conversation: Conversation(id: id, receiverId: receiverId as? String, receiverName: receiverName as? String))
            }
            else {
                // Create new conversation
                let key = Constants.refs.databaseConversations.childByAutoId().key
                
                // Reference to the new conversation in conversations node of current user
                Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/conversations/\(key)").updateChildValues(["receiverId": (self.Friends[indexPath.row].id)!, "receiverName": (self.Friends[indexPath.row].friendName)!])
                
                // Reference to the new conversation in conversations node of the second user
                Constants.refs.databaseUsers.child("/\((self.Friends[indexPath.row].id)!)/conversations/\(key)").updateChildValues(["receiverId": (Auth.auth().currentUser?.uid)!, "receiverName": (Auth.auth().currentUser?.displayName)!])
                
                // Get the information of the new conversation
                let receiverId = (self.Friends[indexPath.row].id)!
                let receiverName = (self.Friends[indexPath.row].friendName)!
                
            }
        })
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            let confirmAlert = UIAlertController(title: "Delete friend", message: "Do you want to unfriend?", preferredStyle: .alert)
            let yesAction = UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
                Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/friends/\(self.Friends[indexPath.row].id!)").removeValue()
                Constants.refs.databaseUsers.child("/\(self.Friends[indexPath.row].id!)/friends/\((Auth.auth().currentUser?.uid)!)").removeValue()
                
                self.Friends.remove(at: indexPath.row)
                tableView.reloadData()
            })
            let noAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            confirmAlert.addAction(yesAction)
            confirmAlert.addAction(noAction)
            
            self.present(confirmAlert, animated: true, completion: nil)
        }
    }
}
