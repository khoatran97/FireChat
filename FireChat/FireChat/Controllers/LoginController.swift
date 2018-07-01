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
    @IBOutlet weak var btn_ForgotPassword: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init view
        initView()
        
        //check login
        checkLogin()
        
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
        btn_ForgotPassword.isHidden = false
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
        
        //textfield
        textfield_PasswordLogin.isSecureTextEntry = true
        textfield_Password.isSecureTextEntry = true
    }
    
    //check login
    func checkLogin() {
        if Auth.auth().currentUser?.uid == nil {
            print("Chua login")
        } else {
            print("Da login")
            performSegue(withIdentifier: "segueToMain", sender: self)
        }
    }
    
    @IBAction func btnAction_Register(_ sender: Any) {
        print("Register")
        
        guard let name = textfield_Name.text, let email = textfield_Email.text, let password = textfield_Password.text else {
            return
        }
        
        let alert = UIAlertController(title: NSLocalizedString("Register failed", comment: ""), message: NSLocalizedString("Email existed or password minimum 6 characters", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
        
        Auth.auth().createUser(withEmail: email, password: password) { (user: AuthDataResult?, err) in
            
            if err != nil {
                print(err as Any)
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            print("Save to Authencation successfully")
            
            let uid = user?.user.uid
            
            let imageName = NSUUID().uuidString;
            let storeRef = Storage.storage().reference().child("\(imageName).jpeg")
            
            if let uploadData = UIImageJPEGRepresentation(self.img_User.image!, 0) {
                storeRef.putData(uploadData, metadata: nil, completion: { (metadata, err) in
                    
                    if err != nil {
                        print(err as Any)
                        self.present(alert, animated: true, completion: nil)
                        return
                    }
                    print("Save user avatar to storage successfully")
                    storeRef.downloadURL(completion: { (url, err) in
                        let profileImageUrl = url?.absoluteString
                        let values = ["name": name, "email": email, "profileImageUrl": profileImageUrl, "imageID": imageName] as [String: AnyObject]
                        
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
                        self.performSegue(withIdentifier: "segueToMain", sender: self)
                    })
                })
            }
            
        }
    }
    
    func registerIntoDatabaseWithUid(uid: String, values: [String: AnyObject]) {
        let ref = Database.database().reference()
        let userRef = ref.child("Users").child(uid)
        
         let alert = UIAlertController(title: NSLocalizedString("Register", comment: ""), message: NSLocalizedString("Register successfully", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        userRef.updateChildValues(values) { (err, ref) in
            if err != nil {
                print(err as Any)
                alert.title = NSLocalizedString("Register failed", comment: "")
                alert.message = NSLocalizedString("Email existed or password minimum 6 characters", comment: "")
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            print("save database successfully")
            //init Alert
            
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.destructive, handler: nil))
            
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
                
                let alert = UIAlertController(title: NSLocalizedString("Login failed", comment: ""), message: NSLocalizedString("Email or password is invalid", comment: ""), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            print("Sign in successfully")
            self.textfiel_EmailLogin.text = ""
            self.textfield_PasswordLogin.text = ""
            self.performSegue(withIdentifier: "segueToMain", sender: self)
        }
        
    }
    
    @IBAction func btnAction_ResetPassword(_ sender: Any) {
        let alert = UIAlertController(title: NSLocalizedString("Forgot password", comment: ""), message: NSLocalizedString("Reset password using email", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addTextField { (textfield) in
            textfield.placeholder = NSLocalizedString("Input email to reset password", comment: "")
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Send", comment: ""), style: UIAlertActionStyle.default, handler: { (action) in
            guard let email = alert.textFields?.first?.text else {
                return
            }
            
            Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                DispatchQueue.main.async {
                    if let error = error {
                        let resetFailedAlert = UIAlertController(title: NSLocalizedString("Reset failed", comment: ""), message: error.localizedDescription, preferredStyle: .alert)
                        resetFailedAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(resetFailedAlert, animated: true, completion: nil)
                    } else {
                        let resetEmailSentAlert = UIAlertController(title: NSLocalizedString("Reset email is sent successfully", comment: ""), message: NSLocalizedString("Check your email", comment: ""), preferredStyle: .alert)
                        resetEmailSentAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(resetEmailSentAlert, animated: true, completion: nil)
                    }
                }
            })
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: UIAlertActionStyle.cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func switchView(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            viewLogin.isHidden = false
            viewRegister.isHidden = true
            btn_Login.isHidden = false
            btn_ForgotPassword.isHidden = false
            btn_Register.isHidden = true
            img_User.isUserInteractionEnabled = false
            break
            
        case 1:
            viewLogin.isHidden = true
            viewRegister.isHidden = false
            btn_Register.isHidden = false
            btn_ForgotPassword.isHidden = true
            btn_Login.isHidden = true
            img_User.isUserInteractionEnabled = true
            break
        default:
            print("default")
        }
    }
    
    @IBAction func viButton_TouchUpInside(_ sender: Any) {
        UserDefaults.standard.set(["vi"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        let announ = UIAlertController(title: NSLocalizedString("Change language", comment: ""), message: NSLocalizedString("Please close and reopen app to apply the change!", comment: ""), preferredStyle: .alert)
        self.present(announ, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when, execute: {
            announ.dismiss(animated: true, completion: nil)
        })
    }
    @IBAction func enButton_TouchUpInside(_ sender: Any) {
        UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        let announ = UIAlertController(title: NSLocalizedString("Change language", comment: ""), message: NSLocalizedString("Please close and reopen app to apply the change!", comment: ""), preferredStyle: .alert)
        self.present(announ, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when, execute: {
            announ.dismiss(animated: true, completion: nil)
        })
    }
    @IBAction func frButton_TouchUpInside(_ sender: Any) {
        UserDefaults.standard.set(["fr"], forKey: "AppleLanguages")
        UserDefaults.standard.synchronize()
        let announ = UIAlertController(title: NSLocalizedString("Change language", comment: ""), message: NSLocalizedString("Please close and reopen app to apply the change!", comment: ""), preferredStyle: .alert)
        self.present(announ, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when, execute: {
            announ.dismiss(animated: true, completion: nil)
        })
    }
    
}

extension LoginController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

