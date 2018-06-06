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

struct Conversation {
    var id: String? = nil
    var name: String? = nil
    var user: String? = nil
    var conversationId: String? = nil
}

class ConversationController: UIViewController {

    @IBOutlet weak var conversationTableView: UITableView!
    
    private lazy var conversationReference: DatabaseReference =
        Constants.refs.databaseUsers.child("/\(Auth.auth().currentUser?.uid)/conversations")
    private var coversationReferenceHandle: DatabaseHandle? = nil
    
    private var Conversations: [Conversation] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.observeConversations()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func observeConversations() {
        coversationReferenceHandle = conversationReference.observe(.childAdded, with: { (snapshot) -> Void in
            let conversationData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let name = conversationData["name"] as! String!, name.characters.count > 0 {
                let conversationId = conversationData["conversationId"] as! String!
                let user = conversationData["user"] as! String!
                self.Conversations.append(Conversation(id: id, name: name, user: user, conversationId: conversationId))
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
        let cell = self.conversationTableView.dequeueReusableCell(withIdentifier: "conversationCell", for: indexPath)
        cell.textLabel?.text = self.Conversations[indexPath.row].name
        return cell
    }
}
