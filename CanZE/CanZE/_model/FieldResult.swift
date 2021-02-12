//
//  FieldResult.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 11/02/21.
//

import Foundation

class FieldResult {
    var lastTimestamp: TimeInterval!
    var doubleValue: Double!
    var stringValue: String!

    init(doubleValue: Double?, stringValue: String?) {
        if doubleValue != nil {
            self.doubleValue = doubleValue!
        }
        if stringValue != nil {
            self.stringValue = stringValue!
        }
        self.lastTimestamp = Date().timeIntervalSince1970
    }
}
