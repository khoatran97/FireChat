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
    
    private lazy var conversationReference: DatabaseReference =
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/conversations")
    private var coversationReferenceHandle: DatabaseHandle? = nil
    
    private var Conversations: [Conversation] = []
    
    var conversationDelegate: ConversationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("Current user: \((Auth.auth().currentUser?.uid)!)")
        
        self.observeConversations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var chatView = segue.destination as! ChatController
        self.conversationDelegate = chatView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }
    
    private func observeConversations() {
        coversationReferenceHandle = conversationReference.observe(.childAdded, with: { (snapshot) -> Void in
            let conversationData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let receiverId = conversationData["receiverId"] as! String!, receiverId.characters.count > 0 {
                let receiverName = conversationData["receiverName"] as! String!
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
        
        var dispatchGroup = DispatchGroup()
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
