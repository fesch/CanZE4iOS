//
//  Sequence.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 20/01/21.
//

import Foundation

class Sequence: NSObject {
    var error: String!
    var cmd: [String]
    var field: Field!
    var result: String!
    var sidVirtual: String!
    var frame: Frame!

    override init() {
        self.error = nil
        self.cmd = []
        self.field = nil
        self.result = nil
        self.sidVirtual = nil
        self.frame = nil
    }
}
