//
//  Frame.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import Foundation

class Frame {
    var fromId: Int!
    var responseId: String!
    var sendingEcu: Ecu!
    var fields: [Field] = []
    var queriedFields: [Field] = []
    var containingFrame: Frame!

    var interval: Int! // in ms
    var lastRequest = 0 // long

    init(fromId: Int, responseId: String?, sendingEcu: Ecu, fields: [Field], queriedFields: [Field], interval: Int, lastRequest: Int, containingFrame: Frame?) {
        self.fromId = fromId
        self.responseId = responseId
        self.sendingEcu = sendingEcu
        self.fields = fields
        self.queriedFields = queriedFields
        self.interval = interval
        self.lastRequest = lastRequest
        self.containingFrame = containingFrame
    }

    func getToIdHexLSB() -> String {
        if isExtended() {
            return String(format: "%06x", getToId() & 0xffffff)
        } else {
            return String(format: "%03x", getToId() & 0xffffff)
        }
    }

    func getToIdHexMSB() -> String {
        return String(format: "%02x", (getToId() & 0x1f000000) >> 24)
    }

    func isExtended() -> Bool {
        // 0-6ff = free frame
        // 700-7ff = 11 bits ISOTP
        // 800 = VFC
        // 801 = FFC
        // 802-FFF = reserved
        // 1000-1FFFFFFF = 29 bits ISOTP
        // We are ignoring the possibility for sub 1000 29 bits for now
        return (fromId >= 0x1000)
    }

    func getToId() -> Int {
        let ecu = Ecus.getInstance.getByFromId(fromId: fromId)
        return ecu.toId
    }

    func getRequestId() -> String {
        if responseId == "" || responseId == nil {
            return ("")
        }
        var tmpChars = responseId.compactMap { $0.asciiValue }
        tmpChars[0] -= 0x04
        let s = tmpChars.map { Character(UnicodeScalar($0)) }
        var ss = ""
        for c in s {
            ss.append(c)
        }
        return ss
    }

    func getAllFields() -> [Field] {
        return fields
    }

    func isIsoTp() -> Bool {
        // if (this.responseId == null) return false;
        // return !responseId.trim().isEmpty();
        return (fromId >= 0x700 && fromId != 0x801) // All 29 bits and the VFC is considered ISOTP too
    }

    func getFromIdHex() -> String {
        return String(format: isExtended() ? "%08x" : "%03x", fromId)
    }
}
