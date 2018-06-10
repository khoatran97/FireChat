//
//  ProfileController.swift
//  FireChat
//
//  Created by XuanNam on 6/8/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class ProfileController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var img_profile: UIImageView!
    @IBOutlet weak var lbl_EmailProfile: UILabel!
    @IBOutlet weak var tableViewProfile: UITableView!
    var user = User()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewProfile.delegate = self
        tableViewProfile.dataSource = self
        
        //load data
        initView()
    }
    
    //load Data
    func initView() {
        //custome image
        img_profile.layer.cornerRadius = img_profile.frame.height / 2
        img_profile.isUserInteractionEnabled = true
        img_profile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleUpdateImage)))
        
        //load data to view
        let uid = Auth.auth().currentUser?.uid
        
        Database.database().reference().child("Users").child(uid!).observe(DataEventType.value) { (snapshot) in
            
            if let values = snapshot.value as? [String : AnyObject] {
                guard let imageProfileUrl = values["profileImageUrl"] as? String, let email = values["email"] as? String, let name = values["name"] as? String else {
                    return
                }
                self.user.email = email
                self.user.profileImageUrl = imageProfileUrl
                self.user.name = name
                
                let url = URL(string: imageProfileUrl)
                URLSession.shared.dataTask(with: url!, completionHandler: { (data: Data?, res: URLResponse?, err) in
                    if err != nil {
                        print(err as Any)
                        return
                    }
                    
                    print("successfully")
                    
                    DispatchQueue.main.async {
                        let dowloadImage = UIImage(data: data!)
                        self.img_profile.image = dowloadImage
                        self.lbl_EmailProfile.text = email
                        //table reload data
                        self.tableViewProfile.reloadData()
                    }
                }).resume()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0: //edit name
            print("Edit name")
            let alert = UIAlertController(title: "Edit Name", message: "You can input new name at here", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addTextField(configurationHandler: { (textfield) in
                textfield.placeholder = "New Name"
            })
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                let textField = alert.textFields![0] as UITextField
                self.user.name = textField.text!
                
                //update to database
                let uid = Auth.auth().currentUser?.uid
                Database.database().reference().child("Users").child(uid!).updateChildValues(["name" : textField.text!])
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            
            
            break
        case 1:
            print(1)
            break
        case 2:
            print(2)
            break
        case 3: //change password
            print("Change password")
            let alert = UIAlertController(title: "Password", message: "Do you want to change password", preferredStyle: UIAlertControllerStyle.alert)
            alert.addTextField { (textfield) in
                textfield.placeholder = "Old password"
                textfield.isSecureTextEntry = true
            }
            alert.addTextField { (textfield) in
                textfield.placeholder = "New password"
                textfield.isSecureTextEntry = true
            }
            alert.addTextField { (textfield) in
                textfield.placeholder = "Confirm new password"
                textfield.isSecureTextEntry = true
            }
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                //code in here
                guard let oldPassword = alert.textFields![0].text, let newPassword = alert.textFields![1].text, let confirmNewPassword = alert.textFields![2].text else {
                    return
                }
                
                let alertNoti = UIAlertController(title: "Change Password", message: "", preferredStyle: UIAlertControllerStyle.alert)
                
                if newPassword != confirmNewPassword {
                    alertNoti.message = "confirm password is wrong!"
                    alertNoti.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                    self.present(alertNoti, animated: true, completion: nil)
                    print("confirm password is wrong!")
                } else {
                    //get current user
                    let user = Auth.auth().currentUser
                    let currentEmail = user?.email
                    let currentPassword = oldPassword
                    let credential = EmailAuthProvider.credential(withEmail: currentEmail!, password: currentPassword)
                    user?.reauthenticateAndRetrieveData(with: credential, completion: { (authData: AuthDataResult?, err) in
                        if err != nil {
                            print(err as Any)
                            alertNoti.message = "Old password is wrong. Please check again!"
                            alertNoti.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alertNoti, animated: true, completion: nil)
                            return
                        }
                        print("check old password successfully")
                        user?.updatePassword(to: newPassword, completion: { (err) in
                            if err != nil {
                                print(err as Any)
                                alertNoti.message = "New password is invalid. Minimun password is 6 characters"
                                alertNoti.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alertNoti, animated: true, completion: nil)
                                return
                            }
                            
                            alertNoti.message = "Successfully, please log in again with new password"
                            alertNoti.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) in
                                self.performSegue(withIdentifier: "segueToLoginVC", sender: self)
                            }))
                            self.present(alertNoti, animated: true, completion: nil)
                        })
                    })
                }
                
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            break
        case 4: //logout
            //success
            let alert = UIAlertController(title: "Logout", message: "Do you want to log out?", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                print("Logout")
                do {
                    try Auth.auth().signOut()
                } catch {
                    print("sign out failed")
                }
                print("sign out successfully")
                self.performSegue(withIdentifier: "segueToLoginVC", sender: self)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            
            self.present(alert, animated: true, completion: nil)
            
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableViewProfile.dequeueReusableCell(withIdentifier: "profileCell") as! CustomProfileCell
        
        switch indexPath.row {
        case 0:
            cell.imageCell.image = #imageLiteral(resourceName: "userAvatar").withRenderingMode(.alwaysOriginal)
            cell.labelCell.text = self.user.name
            break
        case 1:
            cell.imageCell.image = #imageLiteral(resourceName: "img_help").withRenderingMode(.alwaysOriginal)
            cell.labelCell.text = "Help"
            break
        case 2:
            cell.imageCell.image = #imageLiteral(resourceName: "img_info").withRenderingMode(.alwaysOriginal)
            cell.labelCell.text = "Privacy"
            break
        case 4:
            cell.imageCell.image = #imageLiteral(resourceName: "img_logout").withRenderingMode(.alwaysOriginal)
            cell.labelCell.text = "Logout"
            break
        case 3:
            cell.imageCell.image = #imageLiteral(resourceName: "key").withRenderingMode(.alwaysOriginal)
            cell.labelCell.text = "Change password"
        default:
            break
        }
        
        return cell
    }

}
