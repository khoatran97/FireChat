//
//  CustomProfileCell.swift
//  FireChat
//
//  Created by XuanNam on 6/8/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit

class CustomProfileCell: UITableViewCell {

    @IBOutlet weak var imageCell: UIImageView!
    @IBOutlet weak var labelCell: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageCell.layer.cornerRadius = imageCell.frame.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
