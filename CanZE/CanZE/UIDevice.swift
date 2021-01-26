//
//  UIDevice.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import UIKit

extension UIDevice {
    class var isPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }

    class var isPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    class var isTV: Bool {
        return UIDevice.current.userInterfaceIdiom == .tv
    }

    class var isCarPlay: Bool {
        return UIDevice.current.userInterfaceIdiom == .carPlay
    }
}
