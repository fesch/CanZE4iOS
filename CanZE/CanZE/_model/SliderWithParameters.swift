//
//  SliderWithParameters.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 30/03/22.
//

import Foundation
import UIKit

class SliderWithParameters: UISlider {
    var params: Dictionary<String, Any>
    override init(frame: CGRect) {
        params = [:]
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        params = [:]
        super.init(coder: aDecoder)
    }
}
