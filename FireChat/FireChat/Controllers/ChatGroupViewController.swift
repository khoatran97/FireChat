//
//  ChatGroupViewController.swift
//  FireChat
//
//  Created by XuanNam on 6/30/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import Firebase
import MobileCoreServices

class ChatGroupViewController: JSQMessagesViewController {
    
    var Messages = [JSQMessage]()
    private lazy var chatReference: DatabaseReference? = nil
    private lazy var userRef = Database.database().reference().child("Users")
    var group: Group? = nil
    
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }()
    
    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        fetchData()
        
    }
    
    func initView() {
        tabBarController?.tabBar.isHidden = true
        //get member
        if let members = group?.members {
            for member in members {
                if member == Auth.auth().currentUser?.uid {
                    senderId = member
                    senderDisplayName = ""
                    userRef.child(member).observe(DataEventType.value) { (snapshot) in
                        let value = snapshot.value as! Dictionary<String, AnyObject>
                        
                        let name = value["name"] as! String?
                        self.senderDisplayName = name!
                    }
                }
            }
        }

        title = group?.name
        chatReference = Database.database().reference().child("GroupConversation").child((group?.conversationId!)!)
    }
    
    
    
    // START COLLECTION
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return Messages[indexPath.row].senderId == self.senderId ? self.outgoingBubble : self.incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "userAvatar"), diameter: 30)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return Messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let mgs = Messages[indexPath.row]
        if(mgs.isMediaMessage==false){
            if (Messages[indexPath.row].senderId == self.senderId) {
                cell.textView.textColor = UIColor.white
            }
            else {
                cell.textView.textColor = UIColor.black
            }
        }
        
        return cell
    }
    
    //End Collection

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let newMessage = self.chatReference?.childByAutoId()
        let message = ["senderId": self.senderId, "senderName": self.senderDisplayName, "message": text]
        newMessage?.setValue(message)
        //Messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, text: text))
        collectionView.reloadData()
        self.finishSendingMessage()
    }
    
    //fetch data chat
    func fetchData() {
        chatReference?.queryLimited(toLast: 25)
        chatReference?.observe(.childAdded, with: { (snapshot) in
            let chatData = snapshot.value as! Dictionary <String, String>
            
            if let senderId = chatData["senderId"] as String!, senderId.characters.count > 0 {
                let senderName = chatData["senderName"] as String?
                let message = chatData["message"] as String?
                if message == nil
                {
                    return
                }
                if let newMessage = JSQMessage(senderId: senderId, displayName: senderName, text: message) {
                    self.Messages.append(newMessage)
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    self.finishReceivingMessage()
                }
                else {
                    print("Can not receive new message")
                }
            }
        })
    }
}

extension ChatGroupViewController: GroupDelegate {
    func setChatGroup(group: Group) {
        self.group = group
    }
}







