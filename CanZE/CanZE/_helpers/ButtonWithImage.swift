//
//  ButtonWithImage.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import UIKit

class ButtonWithImage: UIButton {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setTitleColor(UIColor(white: 0.15, alpha: 1), for: .normal)
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
        titleLabel?.lineBreakMode = .byWordWrapping
        titleLabel?.numberOfLines = 0
        backgroundColor = UIColor(white: 0.75, alpha: 1)
        contentHorizontalAlignment = .left
        layer.cornerRadius = 5
        imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
    }
}
