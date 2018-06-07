//
//  ViewController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 6/2/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class LoginController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var textfield_Name: UITextField!
    @IBOutlet weak var textfield_Email: UITextField!
    @IBOutlet weak var textfield_Password: UITextField!
    @IBOutlet weak var btn_Register: UIButton!
    @IBOutlet weak var btn_Login: UIButton!
    @IBOutlet weak var viewRegister: UIView!
    @IBOutlet weak var viewLogin: UIView!
    @IBOutlet weak var textfiel_EmailLogin: UITextField!
    @IBOutlet weak var textfield_PasswordLogin: UITextField!
    @IBOutlet weak var img_User: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init view
        initView()
        
    }
    
    func initView() {
        //navigation bar
        navigationController?.navigationBar.isHidden = true
        
        //button
        btn_Register.layer.cornerRadius = 8
        btn_Login.layer.cornerRadius = 8
        
        //Khoi tao la man hinh login nen se an btn_Register vaf viewRegister
        btn_Register.isHidden = true
        btn_Login.isHidden = false
        viewRegister.isHidden = true
        viewLogin.isHidden = false
        
        //segmented Controller
        segmentedControl.selectedSegmentIndex = 0
        
        //Image
        img_User.layer.cornerRadius = img_User.frame.height / 2
        img_User.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleChooseImage)))
        img_User.isUserInteractionEnabled = false
        
        //view
        viewRegister.layer.cornerRadius = 8
        viewLogin.layer.cornerRadius = 8
    }
    
    @IBAction func btnAction_Register(_ sender: Any) {
        print("Register")
        
        guard let name = textfield_Name.text, let email = textfield_Email.text, let password = textfield_Password.text else {
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { (user: AuthDataResult?, err) in
            
            if err != nil {
                print(err as Any)
                return
            }
            
            print("Save to Authencation successfully")
            
            let uid = user?.user.uid
            
            let imageName = NSUUID().uuidString;
            let storeRef = Storage.storage().reference().child("\(imageName).png")
            
            if let uploadData = UIImagePNGRepresentation(self.img_User.image!) {
                storeRef.putData(uploadData, metadata: nil, completion: { (metadata, err) in
                    
                    if err != nil {
                        print(err as Any)
                        return
                    }
                    print("Save user avatar to storage successfully")
                    storeRef.downloadURL(completion: { (url, err) in
                        let profileImageUrl = url?.absoluteString
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl] as [String: AnyObject]
                        
                        if let user = user?.user {
                            let changeRequest = user.createProfileChangeRequest()
                            changeRequest.displayName = name
                            changeRequest.photoURL = NSURL(string: profileImageUrl!)! as URL
                            
                            changeRequest.commitChanges(completion: {error in
                                if error == nil {
                                    print("User information is changed")
                                }
                                else {
                                    print("Can not change user information")
                                }
                            })
                        }
                        
                        //save into database with uid
                        print("Save data into database with uid")
                        self.registerIntoDatabaseWithUid(uid: uid!, values: values)
                    })
                    
                })
            }
            
        }
    }
    
    func registerIntoDatabaseWithUid(uid: String, values: [String: AnyObject]) {
        let ref = Database.database().reference()
        let userRef = ref.child("Users").child(uid)
        
        userRef.updateChildValues(values) { (err, ref) in
            if err != nil {
                print(err as Any)
                return
            }
            
            print("save database successfully")
            //init Alert
            let alert = UIAlertController(title: "Notification", message: "Register Successfully", preferredStyle: UIAlertControllerStyle.alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.destructive, handler: nil))
            
            self.textfield_Password.text = ""
            self.textfield_Name.text = ""
            self.textfield_Email.text = ""
            
            self.present(alert, animated: true, completion: nil)
            
            
        }
    }
    
    @IBAction func btnAction_Login(_ sender: Any) {
        
        guard let email = textfiel_EmailLogin.text, let password = textfield_PasswordLogin.text else {
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { (user: AuthDataResult?, err) in
            
            if err != nil {
                print(err as Any)
                return
            }
            
            print("Sign in successfully")
            self.textfiel_EmailLogin.text = ""
            self.textfield_PasswordLogin.text = ""
            self.performSegue(withIdentifier: "segueToMain", sender: self)
        }
        
    }
    
    
    @IBAction func switchView(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            viewLogin.isHidden = false
            viewRegister.isHidden = true
            btn_Login.isHidden = false
            btn_Register.isHidden = true
            img_User.isUserInteractionEnabled = false
            break
            
        case 1:
            viewLogin.isHidden = true
            viewRegister.isHidden = false
            btn_Register.isHidden = false
            btn_Login.isHidden = true
            img_User.isUserInteractionEnabled = true
            break
        default:
            print("default")
        }
    }
}

extension LoginController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

