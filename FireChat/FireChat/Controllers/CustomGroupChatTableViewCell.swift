//
//  CustomGroupChatTableViewCell.swift
//  FireChat
//
//  Created by XuanNam on 6/29/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit

class CustomGroupChatTableViewCell: UITableViewCell {

    @IBOutlet weak var imageGroup: UIImageView!
    @IBOutlet weak var lbl_GroupName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
