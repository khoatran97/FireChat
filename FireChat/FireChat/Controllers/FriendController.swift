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
    
    var conversationDelegate: ConversationDelegate? = nil
    
    private lazy var friendReference: DatabaseReference =
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/friends")
    private var friendReferenceHandle: DatabaseHandle? = nil
    
    var Friends: [Friend] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        var dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        DispatchQueue.global(qos: .default).async {
            Constants.refs.databaseUsers.child("/\((self.Friends[indexPath.row].id)!)/profileImageUrl").observe(.value, with: {snap in
                
                let imageUrl = snap.value
                if let imageUrl = imageUrl{
                    let storage = Storage.storage()
                    let ref = storage.reference(forURL: imageUrl as! String)
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
        dispatchGroup.wait(timeout: .init(uptimeNanoseconds: 2000000000))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/conversations").queryOrdered(byChild: "receiverId").queryEqual(toValue: (Friends[indexPath.row].id)!).observe(.value, with: { (snapshot) in
            if snapshot.exists() {
                /*print(snapshot)
                let conversationData = snapshot.children as! Dictionary<String, AnyObject>
                let id = snapshot.key
                if let receiverId = conversationData["receiverId"] as! String!, receiverId.characters.count > 0 {
                    let receiverName = conversationData["receiverName"] as! String!
                    self.performSegue(withIdentifier: "segueFriendToChat", sender: self)
                    self.conversationDelegate?.SetChatView(conversation: Conversation(id: id, receiverId: receiverId, receiverName: receiverName))
                }*/
            }
            else {
                let newConversation = Constants.refs.databaseConversations.childByAutoId()
                
                //
                Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/conversations/\(newConversation.key)").updateChildValues(["receiverId": (self.Friends[indexPath.row].id)!, "receiverName": (self.Friends[indexPath.row].friendName)!])
                
                //
                Constants.refs.databaseUsers.child("/\((self.Friends[indexPath.row].id)!)/conversations/\(newConversation.key)").updateChildValues(["receiverId": (Auth.auth().currentUser?.uid)!, "receiverName": (Auth.auth().currentUser?.displayName)!])
            }
        })
    }

}
