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
import AVKit

class ChatGroupViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var Messages = [JSQMessage]()
    let picker = UIImagePickerController()
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
        
        picker.delegate = self
        self.observeChatMedia()
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
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = Messages[indexPath.row]
        let messageUsername = message.senderDisplayName
        print(messageUsername)
        
        return NSAttributedString(string: messageUsername!)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 15
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
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let alert = UIAlertController(title: "Message Media", message: "Please select message media", preferredStyle: .actionSheet);
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let photos = UIAlertAction(title: "Photos",style: .default, handler: {(alert:UIAlertAction) in
            self.chooseMedia(type: kUTTypeImage)})
        let videos = UIAlertAction(title: "Videos",style: .default, handler: {(alert:UIAlertAction) in
            self.chooseMedia(type: kUTTypeMovie)})
        alert.addAction(photos)
        alert.addAction(videos)
        alert.addAction(cancel)
        present(alert,animated:true,completion:nil)
    }
    
    func chooseMedia(type: CFString){
        picker.mediaTypes = [type as String]
        present(picker,animated:true,completion:nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pic = info[UIImagePickerControllerOriginalImage] as? UIImage{
            let img = JSQPhotoMediaItem(image: pic)
            //self.Messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: img))
            sendMedia(image: pic, video: nil, senderID: self.senderId, senderName: senderDisplayName)
            self.collectionView.reloadData()
        }else if let vid = info[UIImagePickerControllerMediaURL] as? URL{
            let video =  JSQVideoMediaItem(fileURL: vid, isReadyToPlay: true)
            sendMedia(image: nil, video: vid, senderID: self.senderId, senderName: self.senderDisplayName)
            //self.Messages.append(JSQMessage(senderId: self.senderId, displayName: self.senderDisplayName, media: video))
            self.collectionView.reloadData()
        }
        self.dismiss(animated: true, completion: nil)
        collectionView.reloadData()
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let mgs = Messages[indexPath.item]
        if mgs.isMediaMessage{
            if let vid = mgs.media as? JSQVideoMediaItem{
                let player = AVPlayer(url: vid.fileURL)
                let playerController = AVPlayerViewController()
                playerController.player = player
                self.present(playerController, animated: true, completion: nil)
            }else if let pic = mgs.media as? JSQPhotoMediaItem{
                let uiImageView = UIImageView(image: pic.image)
                performZoomPicture(uiImageView)
            }
        }
    }
    var startFrame: CGRect?
    var blackbackground: UIView?
    func performZoomPicture(_ imageView:UIImageView){
        print("Handle zoom picture");
        print(imageView)
        startFrame = imageView.frame
        print(startFrame)
        let zoomingImageView = UIImageView(frame: startFrame!)
        zoomingImageView.image = imageView.image!
        zoomingImageView.isUserInteractionEnabled = true
        print(zoomingImageView)
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(performZoomIn)))
        if let keyWindow = UIApplication.shared.keyWindow{
            
            blackbackground = UIView(frame:keyWindow.frame)
            blackbackground?.backgroundColor = UIColor.black
            blackbackground?.alpha = 0
            keyWindow.addSubview(blackbackground!)
            keyWindow.addSubview(zoomingImageView)
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                self.blackbackground?.alpha = 1
                self.inputToolbar.alpha = 0
                let height = (self.startFrame?.height)!/(self.startFrame?.width)!*keyWindow.frame.width
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
            }, completion: nil)
        }
    }
    
    @objc func performZoomIn(tapGesture: UIGestureRecognizer){
        print("perform zoom in")
        print(tapGesture.view)
        if let zoomOutView = tapGesture.view{
            print("got the view")
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                zoomOutView.frame = self.startFrame!
                self.blackbackground?.alpha = 0
                self.inputToolbar.alpha = 1
            }, completion: {(completed) in
                zoomOutView.removeFromSuperview();
                self.collectionView.reloadData();
            })
        }
    }
    
    func getImageStorageRef()->StorageReference{
        return Storage.storage().reference().child("message_images")
    }
    func getVideoStorageRef()->StorageReference{
        return Storage.storage().reference().child("message_videos")
    }
    
    func sendMedia(image: UIImage?, video: URL?, senderID: String, senderName:String){
        if image != nil{
            let imageName = UUID().uuidString
            let ref = getImageStorageRef().child(imageName)
            if let uploadData = UIImageJPEGRepresentation(image!, 0.2){
                ref.putData(uploadData, metadata: nil, completion: { (metadata, err) in
                    if err != nil {
                        print(err as Any)
                        return
                    }
                    
                    print("upload image message successfully")
                    ref.downloadURL(completion: { (url, err) in
                        if err != nil {
                            print(err as Any)
                            return
                        }
                        print(url?.absoluteString)
                        let newMessage = self.chatReference?.childByAutoId()
                        guard let message = ["senderId": self.senderId, "senderName": self.senderDisplayName, "imgURL": url?.absoluteString] as? [String : AnyObject] else {
                            return
                        }
                        newMessage?.setValue(message)
                    })
                })
            }
        }
        if video != nil{
            let videoName = UUID().uuidString
            let ref = getVideoStorageRef().child(videoName)
            ref.putFile(from: video!, metadata: nil, completion: { (metadata, err) in
                if err != nil {
                    print(err as Any)
                    return
                }
                
                print("upload video message successfully")
                ref.downloadURL(completion: { (url, err) in
                    if err != nil {
                        print(err as Any)
                        return
                    }
                    print(url?.absoluteString)
                    let newMessage = self.chatReference?.childByAutoId()
                    guard let message = ["senderId": self.senderId, "senderName": self.senderDisplayName, "videoURL": url?.absoluteString] as? [String : AnyObject] else {
                        return
                    }
                    newMessage?.setValue(message)
                })
            })
        }
    }
    
    private func observeChatMedia() {
        _ = self.chatReference?.queryLimited(toLast: 25)
        _ = chatReference?.observe(.childAdded, with: { (snapshot) -> Void in
            let chatData = snapshot.value as! Dictionary<String, String>
            let id = snapshot.key
            if let senderId = chatData["senderId"] as String!, senderId.characters.count > 0 {
                let senderName = chatData["senderName"] as String!
                let message = chatData["message"] as String!
                let imgURL = chatData["imgURL"] as String!
                let videoURL = chatData["videoURL"] as String!
                if imgURL != nil{
                    let url = URL(string: imgURL!)
                    let temp = JSQPhotoMediaItem(image: #imageLiteral(resourceName: "temp_img"))
                    var newMessage = JSQMessage(senderId: senderId, displayName: senderName, media: temp)
                    let index = self.Messages.count
                    self.Messages.append(newMessage!)
                    URLSession.shared.dataTask(with: url!, completionHandler: { (data: Data?, res: URLResponse?, err) in
                        if err != nil {
                            print(err as Any)
                            return
                        }
                        
                        print("get message media successfully")
                        
                        DispatchQueue.main.async {
                            let dowloadImage = UIImage(data: data!)
                            let img = JSQPhotoMediaItem(image: dowloadImage)
                            if senderId==self.senderId{
                                img?.appliesMediaViewMaskAsOutgoing = true
                            }else{
                                img?.appliesMediaViewMaskAsOutgoing = false
                            }
                            if let newMessage2 = JSQMessage(senderId: senderId, displayName: senderName, media: img) {
                                self.Messages[index] = newMessage2
                                //JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                //self.finishReceivingMessage()
                                self.collectionView.reloadData()
                            }
                        }
                    }).resume()
                }else if videoURL != nil{
                    let url = URL(string: videoURL!)
                    print("Getting video message")
                    let video = JSQVideoMediaItem(fileURL: url, isReadyToPlay: true)
                    if senderId==self.senderId{
                        video?.appliesMediaViewMaskAsOutgoing = true
                    }else{
                        video?.appliesMediaViewMaskAsOutgoing = false
                    }
                    if let newMessage = JSQMessage(senderId: senderId, displayName: senderName, media: video) {
                        self.Messages.append(newMessage)
                        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                        self.finishReceivingMessage()
                        self.collectionView.reloadData()
                    }
                }
            }
        })
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







