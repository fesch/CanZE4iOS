//
//  Frames.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import Foundation

struct Frames {
    let FRAME_ID = 0 // to be stated in HEX, no leading 0x
    let FRAME_INTERVAL_ZOE = 1 // decimal
    let FRAME_INTTERVAL_FLUKAN = 2 // decimal
    let FRAME_ECU = 3 // double
    var frames: [Frame] = []

    static var getInstance = Frames()

    mutating func load(assetName: String) {
        if assetName == "" {
            fillFromAsset(assetName: getDefaultAssetName())
        } else {
            fillFromAsset(assetName: assetName)
        }
    }

    func getDefaultAssetName() -> String {
        var p = "_assets/" + Utils.getAssetPrefix()
        if Utils.isZOE() && AppSettings.shared.useIsoTpFields {
            p += "_FramesAlt.csv"
        } else {
            p += "_Frames.csv"
        }
        return p
    }

    mutating func fillFromAsset(assetName: String) {
        let p = assetName
        let path = Bundle.main.path(forResource: p, ofType: nil)
        if path != nil {
            do {
                let completo = try String(contentsOfFile: path!, encoding: .utf8)
                let righe = completo.components(separatedBy: "\n")
                //   print(righe.count)
                frames = []
                for riga in righe {
                    fillOneLine(line_: riga)
                }
              //  print("loaded frames: \(frames.count)")
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("\(p) not found")
        }
    }

    mutating func fillOneLine(line_: String) {
        var line = line_
        if line.contains("#") {
            line = String(line[..<line.firstIndex(of: "#")!])
        }
        // Get all tokens available in line
        let tokens = line.components(separatedBy: ",")
        if tokens.count == 4 {
            // Create a new field object and fill his  data
            let ecu = Ecus.getInstance.getByMnemonic(mnemonic: trim(s: tokens[FRAME_ECU]))
            if ecu == nil {
                print("(ecu does not exist: '\(trim(s: tokens[FRAME_ECU]))')")
            } else {

                // 18daf1db,100,100,LBC

                let frameId = Int(trim(s: tokens[FRAME_ID]), radix: 16)
                var interval = Int(trim(s: tokens[FRAME_INTTERVAL_FLUKAN]))!
                if AppSettings.shared.car == AppSettings.CAR_ZOE_Q210 || AppSettings.shared.car == AppSettings.CAR_ZOE_R240 {
                    interval = Int(trim(s: tokens[FRAME_INTERVAL_ZOE]))!
                }
                var frame = getById(id: frameId!)
                if frame == nil {
                    frame = Frame(fromId: frameId, responseId: nil, sendingEcu: ecu, fields: [], queriedFields: [], interval: interval, lastRequest: 0)
                } else {
                    frame?.interval = interval
                }
                // add the field to the list of available fields
                frames.append(frame!)
                //   print("frame: \(frameId ?? 0)")
            }
        }
    }

    func getById(id: Int) -> Frame? {
        var i = 0
        while i < frames.count {
            let frame = frames[i]
            if frame.fromId == id && frame.responseId == nil {
                return frame
            }
            i += 1
        }
        return nil
    }

    func getById(id: Int, responseId: String) -> Frame? {
        var i = 0
        while i < frames.count {
            let frame = frames[i]
            if frame.fromId == id && frame.responseId != nil {
                if frame.responseId == responseId.lowercased() {
                    return frame
                }
            }
            i += 1
        }
        return nil
    }

    func trim(s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
