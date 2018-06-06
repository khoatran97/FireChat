//
//  handleChooseImage.swift
//  FireChat
//
//  Created by XuanNam on 6/6/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc func handleChooseImage() {
        print("handle choose image")
        //init image picker controller
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        //declare alert controller
        let alert = UIAlertController()
        alert.addAction(UIAlertAction(title: "Photo", style: UIAlertActionStyle.default, handler: { (action) in
            print("Choose image from libary")
            picker.sourceType = .photoLibrary
            self.present(picker, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (action) in
            print("take photo to choose image")
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
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
