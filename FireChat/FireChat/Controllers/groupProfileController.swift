//
//  groupProfileController.swift
//  FireChat
//
//  Created by XuanNam on 7/1/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class groupProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // Outlet
    @IBOutlet weak var img_Group: UIImageView!
    @IBOutlet weak var btn_GroupName: UIButton!
    @IBOutlet weak var btn_QuitGroup: UIButton!
    @IBOutlet weak var btn_AddMember: UIButton!
    @IBOutlet weak var listFriendsTableView: UITableView!
    
    //
    var group: Group? = nil
    var Friends: [Friend] = []
    private var friendReferenceHandle: DatabaseHandle? = nil
    private lazy var friendReference: DatabaseReference =
        Constants.refs.databaseUsers.child("/\((Auth.auth().currentUser?.uid)!)/friends")
    var Members: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()
        observeFriends()
    }
    
    func initView() {
        //init image
        img_Group.layer.cornerRadius = img_Group.frame.height / 2
        img_Group.isUserInteractionEnabled = true
        img_Group.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChooseImage)))
        
        //tableView
        listFriendsTableView.delegate = self
        listFriendsTableView.dataSource = self
        
        //get image and name of group
        
        Database.database().reference().child("Group").child((group?.id)!).observe(.value) { (snapshot) in
            if let values = snapshot.value as? [String : AnyObject] {
                guard let imageUrl = values["imageUrl"] as? String, let imageId = values["imageId"] as? String, let members = values["members"] as? [String], let name = values["name"] as? String else {
                    return
                }
                
                self.group?.imageId = imageId
                self.group?.imageUrl = imageUrl
                self.group?.name = name
                self.group?.members = members
                
                let url = URL(string: (self.group?.imageUrl)!)
                URLSession.shared.dataTask(with: url!, completionHandler: { (data: Data?, res: URLResponse?, err) in
                    if err != nil {
                        print(err as Any)
                        return
                    }
                    
                    print("successfully")
                    
                    DispatchQueue.main.async {
                        let dowloadImage = UIImage(data: data!)
                        self.img_Group.image = dowloadImage
                        self.btn_GroupName.setTitle(self.group?.name, for: UIControlState.normal)
                        self.listFriendsTableView.reloadData()
                    }
                }).resume()
            }
        }
    }
    
    func observeFriends() {
        friendReferenceHandle = friendReference.observe(.childAdded, with: { (snapshot) -> Void in
            let friendData = snapshot.value as! Dictionary<String, AnyObject>
            let id = snapshot.key
            if let friendName = friendData["friendName"] as! String?, friendName.characters.count > 0 {
                self.Friends.append(Friend(id: id, friendName: friendName))
                self.listFriendsTableView.reloadData()
            } else {
                print("Error! Could not decode friend data")
            }
        })
    }
    
    @objc func handleChooseImage() {
        
        //image picker
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        //alert controller
        let alert = UIAlertController()
        
        alert.addAction(UIAlertAction(title: "Photo", style: .default, handler: { (action) in
            print("photo")
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        
        alert.addAction((UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            print("Camera")
        })))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // Action Button
    @IBAction func btn_ChangeGroupName(_ sender: Any) {
        print("Edit name")
        let alert = UIAlertController(title: "Edit Name", message: "You can input new name at here", preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField(configurationHandler: { (textfield) in
            textfield.placeholder = "New Name"
        })
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            let textField = alert.textFields![0] as UITextField
            self.group?.name = textField.text!
            
            //update to database
            Database.database().reference().child("Group").child((self.group?.id)!).updateChildValues(["name" : textField.text!])
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func btnAction_QuitGroup(_ sender: Any) {
        let id = Auth.auth().currentUser?.uid
        var count: Int? = 0
        
        var members = group?.members
        for member in members! {
            if member == id {
                members?.remove(at: count!)
                Database.database().reference().child("Group").child((group?.id)!).updateChildValues(["members": members as Any])
            }
            count = count! + 1
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnAction_AddMember(_ sender: Any) {
        for member in Members {
            self.group?.members.append(member)
        }
        
        Database.database().reference().child("Group").child((self.group?.id)!).updateChildValues(["members": self.group?.members as Any])
        
        self.listFriendsTableView.reloadData()
    }
    
    
}

extension groupProfileController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Friends.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = listFriendsTableView.dequeueReusableCell(withIdentifier: "listFriendCell", for: indexPath) as! customListFriendCell
        
        let members = group?.members
        var count: Int = 0
        
        for member in members! {
            if Friends[indexPath.row].id == member {
                count = count + 1
                break
            }
        }
        
        if count == 0 {
            cell.selectionStyle = .none
            
            cell.lbl_Name.text = self.Friends[indexPath.row].friendName
            
            // To wait for the result of Observe Function
            let dispatchGroup = DispatchGroup()
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
                                cell.img_friend.image = UIImage(data: data!)
                                cell.img_friend.layer.cornerRadius = cell.img_friend.bounds.width / 2
                                cell.img_friend.layer.masksToBounds = true
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
        } else {
            cell.selectionStyle = .none
            cell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            cell.lbl_Name.text = self.Friends[indexPath.row].friendName
            
            // To wait for the result of Observe Function
            let dispatchGroup = DispatchGroup()
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
                                cell.img_friend.image = UIImage(data: data!)
                                cell.img_friend.layer.cornerRadius = cell.img_friend.bounds.width / 2
                                cell.img_friend.layer.masksToBounds = true
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
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        
        let members = group?.members
        var count: Int = 0
        
        for member in members! {
            if Friends[indexPath.row].id == member {
                count = count + 1
                break
            }
        }
        
        if count == 0 {
            if cell!.isSelected
            {
                cell!.isSelected = false
                if cell!.accessoryType == UITableViewCellAccessoryType.none
                {
                    Members.append(Friends[indexPath.row].id!)
                    cell!.accessoryType = UITableViewCellAccessoryType.checkmark
                }
                else
                {
                    let index = Members.index(where: { (item) -> Bool in
                        item == Friends[indexPath.row].id
                    })
                    Members.remove(at: index!)
                    cell!.accessoryType = UITableViewCellAccessoryType.none
                }
            }
        } else {
            cell?.selectionStyle = .none
            cell!.accessoryType = UITableViewCellAccessoryType.checkmark
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension groupProfileController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectImageFromPicker: UIImage?
        if let editImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectImageFromPicker = editImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectImageFromPicker = originalImage
        }
        
        if let selectImage = selectImageFromPicker {
            //get imageID
            let newImageID = NSUUID().uuidString
            let storeRef = Storage.storage().reference()
            let storeRefChild = storeRef.child("\(newImageID).png")
            let databaseRef = Database.database().reference().child("Group").child((group?.id)!)
            // find image and delete in storage
            databaseRef.observe(DataEventType.value) { (snapshot) in
                if let values = snapshot.value as? [String : AnyObject] {
                    let imageDeleteID = (values["imageId"] as! String)
                    if imageDeleteID != newImageID {
                        let imageDelete = storeRef.child("\(imageDeleteID).png")
                        imageDelete.delete(completion: { (err) in
                            if err != nil {
                                print(err as Any)
                                return
                            }
                            
                            print("Delete successfully")
                        })
                    }
                }
            }
            //upload new image to storage and update data to database
            if let imageUpload = UIImagePNGRepresentation(selectImage) {
                storeRefChild.putData(imageUpload, metadata: nil, completion: { (metadata, err) in
                    if err != nil {
                        print(err as Any)
                        return
                    }
                    
                    print("uplaod image successfully")
                    storeRefChild.downloadURL(completion: { (url, err) in
                        if err != nil {
                            print(err as Any)
                            return
                        }
                        let imageUrl = url?.absoluteString
                        guard let values = ["imageUrl" : imageUrl, "imageId" : newImageID] as? [String : AnyObject] else {
                            return
                        }
                        databaseRef.updateChildValues(values)
                    })
                })
            }
            
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}










