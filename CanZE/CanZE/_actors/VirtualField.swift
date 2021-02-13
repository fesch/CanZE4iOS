//
//  VirtualField.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import Foundation

class VirtualField: Field {
    var dependantFields: [String: Field] = [:]

    init(responseId: String, dependantFields: [String: Field], decimals: Int, unit: String) {
        super.init(sid: "", frame: Frames.getInstance.getById(id: 0x800), from: 24, to: 31, resolution: 1, offset: 0, decimals: 0, unit: unit, responseId: responseId, options: 0, name: nil, list: nil)

        self.unit = unit
        self.decimals = decimals
        self.dependantFields = dependantFields

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
