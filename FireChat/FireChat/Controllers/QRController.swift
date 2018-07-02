//
//  QRController.swift
//  FireChat
//
//  Created by Khoa Huu Tran on 22/06/2018.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit
import Firebase

class QRController: UIViewController {

    @IBOutlet weak var qrImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        var id = Auth.auth().currentUser?.uid
        self.qrImageView.image = self.generateQR(from: id!)
        self.tabBarController?.tabBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func generateQR(from string: String) -> UIImage? {
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage");
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }
    
    @IBAction func shareAction(_ sender: Any) {
        let qr = self.qrImageView.image
        let imageToShare = [ qr! ]
        
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.mail, UIActivityType.message, UIActivityType.postToTwitter, UIActivityType.postToFacebook]
        self.present(activityViewController, animated: true, completion: nil)
    }
    
}
