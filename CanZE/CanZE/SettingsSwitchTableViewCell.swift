//
//  SettingsSwitchTableViewCell.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 24/12/20.
//

import UIKit

class SettingsSwitchTableViewCell: UITableViewCell {
    @IBOutlet var sw: UISwitch!
    @IBOutlet var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        sw.isUserInteractionEnabled = false
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
