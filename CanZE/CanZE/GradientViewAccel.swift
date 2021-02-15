//
//  GradientViewAccel.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 15/02/21.
//

import UIKit

@IBDesignable
class GradientViewAccel: UIView {
    private var gradientLayer = CAGradientLayer()
    private var vertical: Bool = false

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        // Drawing code

        // fill view with gradient layer
        gradientLayer.frame = bounds

        let c1 = UIColor(rgb: 0x009900).cgColor
        let c2 = UIColor(rgb: 0x1E90FF).cgColor
        let c3 = UIColor(rgb: 0x9400D3).cgColor
        
        // style and insert layer if not already inserted
        if gradientLayer.superlayer == nil {
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = vertical ? CGPoint(x: 0, y: 1) : CGPoint(x: 1, y: 0)
            gradientLayer.colors = [c1, c2, c3]
            

            gradientLayer.locations = [0.0, 0.5, 1.0]
            layer.insertSublayer(gradientLayer, at: 0)
        }
    }
}
