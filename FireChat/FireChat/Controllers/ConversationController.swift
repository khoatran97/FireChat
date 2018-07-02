//
//  ConversationController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 6/6/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class ConversationController: UIViewController {
    
    @IBOutlet weak var conversationTableView: UITableView!
    @IBOutlet weak var img_Profile: UIImageView!
    @IBOutlet weak var lbl_Profile: UILabel!
    
    private lazy var conversationReference: DatabaseReference =
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/conversations")
    private var coversationReferenceHandle: DatabaseHandle? = nil
    
    private var Conversations: [Conversation] = []
    
    var conversationDelegate: ConversationDelegate?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Current user: \((Auth.auth().currentUser?.uid)!)")
        img_Profile.layer.cornerRadius = img_Profile.frame.height / 2
        img_Profile.isUserInteractionEnabled = true
        img_Profile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleProfile)))
        initNavBar()
        
        self.observeConversations()
    }
    
    //init NavigationBar
    func initNavBar() {
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Logout", comment: ""), style: .plain, target: self, action: #selector(handleLogout))
        
        let uid = Auth.auth().currentUser?.uid
        Database.database().reference().child("Users").child(uid!).observe(DataEventType.value) { (snapshot) in
            if let values = snapshot.value as? [String : AnyObject] {
                
                if let imageProfileUrl = values["profileImageUrl"] as? String {
                    
                    let url = URL(string: imageProfileUrl)
                    URLSession.shared.dataTask(with: url!, completionHandler: { (data: Data?, res: URLResponse?, err) in
                        if err != nil {
                            print(err as Any)
                            return
                        }
                        print("successfully")
                        
                        DispatchQueue.main.async {
                            if let imageProfile = UIImage(data: data!) {
                                self.img_Profile.image = imageProfile
                            }
                        }
                    }).resume()
                }
            }
            
        }
    }
    
    @objc func handleProfile() {
        //self.performSegue(withIdentifier: "toProfileVC", sender: self)
        if let tabBarController = self.tabBarController {
            self.tabBarController?.selectedIndex = 4
        }
    }
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
            
            let alert = UIAlertController(title: NSLocalizedString("Logout", comment: ""), message: NSLocalizedString("You logged out successfully", comment: ""), preferredStyle: .alert)
            self.present(alert, animated: true, completion: nil)
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when, execute: {
                alert.dismiss(animated: true, completion: nil)
            })
            self.performSegue(withIdentifier: "segueToLoginVC", sender: self)
            
        } catch {
            print("Logout failed")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueConversationToChat" {
            let chatView = segue.destination as! ChatController
            self.conversationDelegate = chatView
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func observeConversations() {
        coversationReferenceHandle = conversationReference.observe(.childAdded, with: { (snapshot) -> Void in
            let conversationData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let receiverId = conversationData["receiverId"] as! String?, receiverId.characters.count > 0 {
                let receiverName = conversationData["receiverName"] as! String?
                self.Conversations.append(Conversation(id: id, receiverId: receiverId, receiverName:receiverName))
                self.conversationTableView.reloadData()
            } else {
                print("Error! Could not decode conversation data")
            }
        })
    }
}

extension ConversationController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell", for: indexPath) as! ConversationCell
        cell.name.text = self.Conversations[indexPath.row].receiverName
        cell.message.text = ""
        
        let dispatchGroup = DispatchGroup()
        
        // Check in friendlist
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\((self.Conversations[indexPath.row].receiverId)!)/friends").observeSingleEvent(of: .value, with: {snapshot in
                if !(snapshot.hasChild("\((Auth.auth().currentUser?.uid)!)")) {
                    cell.isUserInteractionEnabled = false
                    cell.name.isEnabled = false
            }
            dispatchGroup.leave()
        })
        
        // Check in blacklist
        dispatchGroup.enter()
        Constants.refs.databaseUsers.child("/\((self.Conversations[indexPath.row].receiverId)!)/blacklist").observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.hasChild("\((Auth.auth().currentUser?.uid)!)") {
                cell.isUserInteractionEnabled = false
                cell.name.isEnabled = false
            }
            dispatchGroup.leave()
        })
        
        dispatchGroup.enter()
        DispatchQueue.global(qos: .default).async {
            Constants.refs.databaseUsers.child("/\((self.Conversations[indexPath.row].receiverId)!)/profileImageUrl").observe(.value, with: {snap in
                
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
        self.performSegue(withIdentifier: "segueConversationToChat", sender: self)
        self.conversationDelegate?.SetChatView(conversation: Conversations[indexPath.row])
    }
}
