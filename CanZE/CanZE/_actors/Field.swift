//
//  Field.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import Foundation

class Field {
    let FIELD_TYPE_MASK = 0x700
    // let  FIELD_TYPE_UNSIGNED = 0x000
    let FIELD_TYPE_SIGNED = 0x100
    let FIELD_TYPE_STRING = 0x200
    let FIELD_TYPE_HEXSTRING = 0x400
    let FIELD_SELFPROPELLED = 0x800

    var sid: String!
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

    var lastRequest: Double!
    var interval = Int.max

    var virtual = false

    init(sid: String?, frame: Frame?, from: Int?, to: Int?, resolution: Double?, offset: Int64?, decimals: Int?, unit: String?, responseId: String?, options: Int?, name: String?, list: String?) {
        if sid == nil || sid == "" {
            if responseId != nil, responseId != "" {
                let s = String(format: "%02x", frame!.fromId) + ".\(responseId ?? "").\(from ?? -1)"
                self.sid = s.lowercased()
            } else {
                let s = String(format: "%02x", frame!.fromId) + ".\(from ?? -1)"
                self.sid = s.lowercased()
            }
        } else {
            self.sid = sid?.lowercased()
        }
        self.frame = frame
        self.from = from
        self.to = to
        self.offset = offset
        self.decimals = decimals
        self.resolution = resolution
        self.unit = unit
        self.responseId = responseId?.lowercased()
        self.options = options
        self.name = name
        self.list = list

        lastRequest = Date().timeIntervalSince1970
    }

    /*
        Please note that the offset is applied BEFORE scaling
        The request and response Ids should be stated as HEX strings without leading 0x
        The name is optional and can be used for diagnostice printouts
        The list is optional and can contain a string, semicolon-separated containing a description
          of the value, 0 based
     */

    func isIsoTp() -> Bool {
        if responseId.trim().count > 0 {
            return true
        } else {
            return false
        }
    }

    func getValue() -> Double {
        // double val =  ((value-offset)/(double) divider *multiplier)/(decimals==0?1:decimals);
        if value != nil {
            var val = (value - Double(offset)) * resolution
            // This is a tricky one. If we are in miles mode, in a virtual field the sources for that
            // field have already been corrected, so this should not be done twice. I.O.W. virtual
            // field values are, by definition already properly corrected.
            if Globals.shared.milesMode { // & !virtual {
                if unit.lowercased().hasPrefix("km") {
                    val = round(val / 1.609344 * 10.0) / 10.0
                } else if unit.lowercased().hasSuffix("km") {
                    val = round(val * 1.609344 * 10.0) / 10.0
                    // setUnit(getUnit().replace("km", "mi"));
                }
            }
            return val
        }
        return Double.nan
    }

    func calculatedValue(value: Double) {
        var value2 = value
        // inverted conversion.
        if Globals.shared.milesMode { // } & !virtual) {
            if unit.lowercased().hasPrefix("km") {
                value2 = value * 1.609344
            } else if unit.lowercased().hasSuffix("km") {
                value2 = value / 1.609344
            }
        }
        // inverted calculation
        self.value = (value2 / resolution + Double(offset))
    }

    func getId() -> Int {
        return frame.fromId
    }

//    func getHexId() -> String {
//        return frame.getFromIdHex
//    }

//    public void setId(int id) {
//        this.id = id;
//    }

    func getUnit() -> String {
        if Globals.shared.milesMode {
            return (unit + "").replacingOccurrences(of: "km", with: "mi")
        } else {
            return unit
        }
    }

    func getRequestId() -> String? {
        if responseId == "" {
            return ""
        }
//        var tmpChars = responseId.toCharArray()
//        tmpChars[0] -= 0x20
//        return String.valueOf(tmpChars)
        return nil
    }

    func getCar() -> Int {
        return (options & 0x0f)
    }

    func isCar(car: Int) -> Bool {
        return (options & car) == car
    }

    func setCar(car: Int) {
        options = (options & 0xfe0) + (car & 0x1f)
    }

    func getFrequency() -> Int {
        return frame.interval
    }

    func isSigned() -> Bool { // ff
        return (options & FIELD_TYPE_MASK) == FIELD_TYPE_SIGNED
    }

    func isString() -> Bool { // 2ff
        return (options & FIELD_TYPE_MASK) == FIELD_TYPE_STRING
    }

    func isHexString() -> Bool { // 4ff
        return (options & FIELD_TYPE_MASK) == FIELD_TYPE_HEXSTRING
    }

    func isSelfPropelled() -> Bool {
        return (options & FIELD_SELFPROPELLED) == FIELD_SELFPROPELLED
    }

    func isList() -> Bool {
        return (list != nil) && (list != "")
    }
}
