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
        let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell", for: indexPath)
        cell.textLabel?.text = self.Conversations[indexPath.row].receiverName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.conversationDelegate?.SetConversationId(Conversations[indexPath.row])
        self.performSegue(withIdentifier: "segueToChat", sender: self)
    }
}
