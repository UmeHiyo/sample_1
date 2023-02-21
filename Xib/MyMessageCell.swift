//
//  ChatTableViewCell.swift
//  acote
//
//  Created by Yuiko Umekawa on 2020/12/03.
//  Copyright © 2020 Yuiko Umekawa. All rights reserved.
//

import UIKit

class MyMessageCell: UITableViewCell {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setMessage(message: Message) {
        self.label.text = message.content
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        self.dateLabel.text = dateFormatter.string(from: message.date)
    }
    
}
