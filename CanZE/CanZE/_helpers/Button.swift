//
//  Button.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import UIKit

class Button: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setTitleColor(UIColor(white: 0.15, alpha: 1), for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.numberOfLines = 0
        titleLabel?.textAlignment = .center

        backgroundColor = UIColor(white: 0.75, alpha: 1)
        layer.cornerRadius = 5
    }
}
