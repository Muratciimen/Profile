//
//  NewsTableViewCell.swift
//  Profile
//
//  Created by Murat Çimen on 8.10.2023.
//

import UIKit

class NewsTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var fromDate: UILabel!
    
    @IBOutlet weak var toDate: UILabel!
    
    
    @IBOutlet weak var memberType: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
