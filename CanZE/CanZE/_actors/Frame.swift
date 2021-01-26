//
//  Frame.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import Foundation

struct Frame {
    var fromId: Int!
    var responseId: String! = nil
    var sendingEcu: Ecu!
    var fields: [Field] = []
    var queriedFields: [Field] = []
//    var containingFrame: Frame!

    var interval: Int! // in ms
    var lastRequest = 0 // long

    func getToIdHexLSB() -> String {
        if isExtended() {
            return String(format: "%06x", getToId() & 0xFFFFFF)
        } else {
            return String(format: "%03x", getToId() & 0xFFFFFF)
        }
    }

    func getToIdHexMSB() -> String {
        return String(format: "%02x", (getToId() & 0x1F000000) >> 24)
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
}
