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
    let FRAME_INTERVAL_FLUKAN = 2 // decimal
    let FRAME_ECU = 3 // double
    var frames: [Frame] = []

    static var getInstance = Frames()

    mutating func load(ecu: Ecu) {
        if ecu.fromId != 0x801 { // for all but the Free Frame ECU, just load it's diagnostic frame. Sub-frames will be created automatically for each field
            frames = []
            let frame = Frame(fromId: ecu.fromId, responseId: nil, sendingEcu: ecu, fields: [], queriedFields: [], interval: 99999, lastRequest: 0, containingFrame: nil)
            // add the field to the list of available fields
            frames.append(frame)
        } else { // for the FCC, load all Free Frames
            load(assetName: "FFC_FramesPh1.csv")
        }
    }

    mutating func load(assetName: String) {
        if assetName == "" {
            fillFromAsset(assetName: getDefaultAssetName())
        } else {
            fillFromAsset(assetName: "_assets/\(Utils.getAssetPrefix())\(assetName)")
        }
    }

    func getDefaultAssetName() -> String {
        var p = "_assets/" + Utils.getAssetPrefix()
        if Utils.isZOE(), Globals.shared.useIsoTpFields {
            p += "_FramesAlt.csv"
        } else {
            p += "_Frames.csv"
        }
        return p
    }

    mutating func fillFromAsset(assetName: String) {
        let p = assetName
        if let path = Bundle.main.path(forResource: p, ofType: nil) {
            do {
                let completo = try String(contentsOfFile: path, encoding: .utf8)
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
            let ecu = Ecus.getInstance.getByMnemonic(tokens[FRAME_ECU].trim())
            if ecu == nil {
                print("(ecu does not exist: '\(tokens[FRAME_ECU].trim())')")
            } else {
                let frameId = Int(tokens[FRAME_ID].trim(), radix: 16)
                var interval = Int(tokens[FRAME_INTERVAL_FLUKAN].trim())!
                if Globals.shared.car == AppSettings.CAR_ZOE_Q210 || Globals.shared.car == AppSettings.CAR_ZOE_R240 {
                    interval = Int(tokens[FRAME_INTERVAL_ZOE].trim())!
                }
                var frame = getById(id: frameId!)
                if frame == nil {
                    frame = Frame(fromId: frameId!, responseId: nil, sendingEcu: ecu!, fields: [], queriedFields: [], interval: interval, lastRequest: 0, containingFrame: nil)
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
            if frame.fromId == id, frame.responseId == nil {
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
            if frame.fromId == id, frame.responseId != nil {
                if frame.responseId == responseId.lowercased() {
                    return frame
                }
            }
            i += 1
        }
        return nil
    }

    func getAllFrames() -> [Frame] {
        return frames
    }
}
