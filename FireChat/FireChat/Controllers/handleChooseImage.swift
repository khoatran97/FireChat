//
//  handleChooseImage.swift
//  FireChat
//
//  Created by XuanNam on 6/6/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

extension LoginController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleChooseImage() {
        print("handle choose image")
        //init image picker controller
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        //declare alert controller
        let alert = UIAlertController()
        alert.addAction(UIAlertAction(title: NSLocalizedString("Photo", comment: ""), style: UIAlertActionStyle.default, handler: { (action) in
            print("Choose image from libary")
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { (action) in
            print("take photo to choose image")
            
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (action) in
            print("Cancel")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectImageFromPicker: UIImage?
        if let editImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectImageFromPicker = editImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectImageFromPicker = originalImage
        }
        
        if let selectImage = selectImageFromPicker {
            img_User.image = selectImage
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}

extension ProfileController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @objc func handleUpdateImage() {
        //init picker image controller
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        //init alert controller
        let alert = UIAlertController()
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Photo", comment: ""), style: .default, handler: { (action) in
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
            
            print("choose image successfully")
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Camera", comment: ""), style: .default, handler: { (action) in
            print("camera")
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        var selectImageFromPicker: UIImage?
        if let editImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            selectImageFromPicker = editImage
        } else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            selectImageFromPicker = originalImage
        }
        
        if let selectImage = selectImageFromPicker {
            //get imageID
            let uid = Auth.auth().currentUser?.uid
            let newImageID = NSUUID().uuidString
            let storeRef = Storage.storage().reference()
            let storeRefChild = storeRef.child("\(newImageID).png")
            let databaseRef = Database.database().reference().child("Users").child(uid!)
            // find image and delete in storage
            databaseRef.observe(DataEventType.value) { (snapshot) in
                if let values = snapshot.value as? [String : AnyObject] {
                    let imageDeleteID = (values["imageID"] as! String)
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
                        let profileImageUrl = url?.absoluteString
                        guard let values = ["profileImageUrl" : profileImageUrl, "imageID" : newImageID] as? [String : AnyObject] else {
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
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
}



