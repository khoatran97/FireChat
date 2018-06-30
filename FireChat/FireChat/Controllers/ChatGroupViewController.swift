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
    private lazy var chatReference: DatabaseReference =
        Database.database().reference().child("ConversationGroup")

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        senderId = "211654d654as6d4ad"
        senderDisplayName = "Nam"
        tabBarController?.tabBar.isHidden = true
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return Messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Messages.count
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

}
