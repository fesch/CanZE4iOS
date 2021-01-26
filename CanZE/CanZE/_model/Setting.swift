//
//  Setting.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 24/12/20.
//

import Foundation

enum SettingType: String {
    case NONE
    case TEXTFIELD
    case TEXTFIELD_READONLY
    case PICKER
    case SWITCH
}

var Type: SettingType = .NONE

struct Setting {
    var tag: String
    var type: SettingType!
    var title: String?
    var subTitle: String?
    var boolValue: Bool = false
    var listTitles: [String]? = []
    var listValues: [Any]? = []
    var intValue: Int? = -1
    var stringValue: String?
    var placeholder: String?

    mutating func switchBool() {
        boolValue = !boolValue
    }
    
}
