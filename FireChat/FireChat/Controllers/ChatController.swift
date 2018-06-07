//
//  ChatController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 07/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import FirebaseAuth
import Firebase

class ChatController: JSQMessagesViewController {

    var Messages = [JSQMessage]()
    var conversation: Conversation? = nil
    
    private lazy var chatReference: DatabaseReference =
        Constants.refs.databaseConversations.child("/\((self.conversation?.id)!)")
    
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }()
    
    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.isHidden = true
        title = self.conversation?.receiverName

        self.senderId = (Auth.auth().currentUser?.uid)!
        self.senderDisplayName = (Auth.auth().currentUser?.displayName)!
        
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        self.observeChats()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return Messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return Messages[indexPath.row].senderId == self.senderId ? self.outgoingBubble : self.incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return Messages[indexPath.row].senderId == self.senderId ? nil : NSAttributedString(string: Messages[indexPath.row].senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return Messages[indexPath.row].senderId == self.senderId ? 0 : 15
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let newMessage = self.chatReference.childByAutoId()
        let message = ["senderId": self.senderId, "senderName": self.senderDisplayName, "message": text]
        newMessage.setValue(message)
        self.finishSendingMessage()
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        if (Messages[indexPath.row].senderId == self.senderId) {
            cell.textView.textColor = UIColor.white
        }
        else {
            cell.textView.textColor = UIColor.black
        }
        return cell
    }
    
    private func observeChats() {
        _ = self.chatReference.queryLimited(toLast: 25)
        _ = chatReference.observe(.childAdded, with: { (snapshot) -> Void in
            let chatData = snapshot.value as! Dictionary<String, String>
            let id = snapshot.key
            if let senderId = chatData["senderId"] as String!, senderId.characters.count > 0 {
                let senderName = chatData["senderName"] as String!
                let message = chatData["message"] as String!
                
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

extension ChatController: ConversationDelegate {
    func SetChatView(conversation: Conversation) {
        self.conversation = conversation
    }
    
}
