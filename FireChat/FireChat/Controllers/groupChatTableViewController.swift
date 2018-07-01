//
//  groupChatTableViewController.swift
//  FireChat
//
//  Created by XuanNam on 6/29/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class groupChatTableViewController: UITableViewController {
    
    var Groups: [Group] = []
    private lazy var groupRef = Database.database().reference().child("Group")

    override func viewDidLoad() {
        super.viewDidLoad()
        
        customNavigationBar()
        fetchData()
    }
    
    //Init
    func fetchData() {
        groupRef.observe(DataEventType.childAdded, with: { (snapshot) in
            let group = snapshot.value as! Dictionary<String, AnyObject>
            
            guard let id = group["id"] as! String?, let name = group["name"] as! String?, let imageUrl = group["imageUrl"] as! String?, let imageId = group["imageId"] as! String?, let members = group["members"] as! [String]? else {
                return
            }
            
            var groups = Group()
            groups.id = id
            groups.name = name
            groups.imageId = imageId
            groups.imageUrl = imageUrl
            groups.members = members
            
            for member in members {
                if member == Auth.auth().currentUser?.uid {
                    self.Groups.append(groups)
                    self.tableView.reloadData()
                }
            }
        }) { (err) in
            print(err as Any)
        }
    }
    
    func customNavigationBar() {
        navigationItem.title = NSLocalizedString("Group chat", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "addGroup").withRenderingMode(.alwaysOriginal), style: .plain, target: self, action: #selector(handleAddGroup))
    }
    
    @objc func handleAddGroup() {
        performSegue(withIdentifier: "segueToAddGroupChat", sender: self)
    }
    
    // Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Groups.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupChatTableViewCell", for: indexPath) as! CustomGroupChatTableViewCell
        
        cell.lbl_GroupName.text = Groups[indexPath.row].name
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        DispatchQueue.global(qos: .default).async {
            if let imageUrl = self.Groups[indexPath.row].imageUrl {
                let url = URL(string: imageUrl)
                URLSession.shared.dataTask(with: url!, completionHandler: { (data: Data?, res: URLResponse?, err) in
                    if err != nil {
                        print(err as Any)
                        dispatchGroup.leave()
                    }
                    print("successfully")
                    
                    DispatchQueue.main.async {
                        if let image = UIImage(data: data!) {
                            cell.imageGroup.image = image
                            dispatchGroup.leave()
                        }
                    }
                }).resume()
            } else {
                print("Can not load avatar")
                dispatchGroup.leave()
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "segueToChatGroupVC", sender: self)
    }

    
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
