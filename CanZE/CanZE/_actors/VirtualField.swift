//
//  VirtualField.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import Foundation

class VirtualField: Field {
    /*    var sid: String!
     var frame: Frame!
     var from: Int! // Short
     var to: Int! // Short
     var offset: Int64! // long
     var decimals: Int!
     var resolution: Double!
     var unit: String!
     var responseId: String!
     var options: Int! // short // see the options definitions in MainActivity
     var name: String!
     var list: String!

     var value: Double!
     var strVal = ""
     // var int skipsCount = 0;

     var lastRequest: Int64! // Long
     var interval = Int.max

     var virtual = true
     */
    // var virtualFieldAction = "" // TODO:
    var dependantFields: [String: Field] = [:]

    init(responseId: String, dependantFields: [String: Field], decimals: Int, unit: String) {
        // , VirtualFieldAction virtualFieldAction)

        super.init(sid: "", frame: Frames.getInstance.getById(id: 0x800), from: 24, to: 31, resolution: 1, offset: 0, decimals: 0, unit: unit, responseId: responseId, options: 0, name: nil, list: nil)

        self.unit = unit
        self.decimals = decimals
        self.dependantFields = dependantFields
//        self.virtualFieldAction = virtualFieldAction

        virtual = true
    }

    func getFields() -> [Field] {
        var a: [Field] = []
        for f in dependantFields {
            a.append(f.value)
        }
        return a
    }
}
