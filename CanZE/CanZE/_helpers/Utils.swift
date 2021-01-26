//
//  Utils.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import Foundation
import UIKit

struct Utils {
    /*    static func getAssetSuffix() -> String {
         if isPh2() {
             return "Ph2"
         } else {
             return "Ph1"
         }
     }
     */
    static func getAssetPrefix() -> String {
        if isPh2() {
            return "ZOE_Ph2/"
        } else if isTwingo() {
            return "Twingo_3_Ph2/"
        } else if isTwizy() {
            return "Twizy/"
        } else {
            return "ZOE/"
        }
    }

    static func isPh2() -> Bool {
        return AppSettings.shared.car == AppSettings.CAR_X10PH2
    }
    static func isTwingo() -> Bool {
        return AppSettings.shared.car == AppSettings.CAR_TWINGO
    }
    static func isTwizy() -> Bool {
        return AppSettings.shared.car == AppSettings.CAR_TWIZY
    }

    static func isZOE() -> Bool {
        return AppSettings.shared.car == AppSettings.CAR_ZOE_Q90
            || AppSettings.shared.car == AppSettings.CAR_ZOE_Q210
            || AppSettings.shared.car == AppSettings.CAR_ZOE_R90
            || AppSettings.shared.car == AppSettings.CAR_ZOE_R240
    }
}
