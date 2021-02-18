//
//  SettingsTableViewCell.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 24/12/20.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    var direction = "up"
    var transparency: CGFloat = 0.0
    var timerWarning = Timer()

    func warning() {
        timerWarning = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            if self.direction == "up" {
                self.transparency += 0.1
            } else {
                self.transparency -= 0.1
            }
            if self.transparency > 0.66 {
                self.direction = "down"
                self.transparency = 0.66
            } else if self.transparency < 0 {
                self.direction = "up"
                self.transparency = 0
            }
            self.contentView.backgroundColor = UIColor.red.withAlphaComponent(self.transparency)
        }
        timerWarning.fire()
    }
}
