//
//  customListFriendCell.swift
//  FireChat
//
//  Created by XuanNam on 6/29/18.
//  Copyright © 2018 HKN Team. All rights reserved.
//

import UIKit

class customListFriendCell: UITableViewCell {

    @IBOutlet weak var img_friend: UIImageView!
    @IBOutlet weak var lbl_Name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
