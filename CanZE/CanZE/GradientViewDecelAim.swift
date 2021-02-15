//
//  GradientViewDecelAim.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 15/02/21.
//

import UIKit

@IBDesignable
class GradientViewDecelAim: UIView {
    private var gradientLayer = CAGradientLayer()
    private var vertical: Bool = false

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Drawing code

        // fill view with gradient layer
        gradientLayer.frame = bounds

        let c1 = UIColor(rgb: 0x1E90FF).cgColor
        let c2 = UIColor(rgb: 0x1E90FF).cgColor
        
        // style and insert layer if not already inserted
        if gradientLayer.superlayer == nil {
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = vertical ? CGPoint(x: 0, y: 1) : CGPoint(x: 1, y: 0)
            gradientLayer.colors = [c1, c2]
            

            gradientLayer.locations = [0.0, 1.0]
            layer.insertSublayer(gradientLayer, at: 0)
        }
    }
}
