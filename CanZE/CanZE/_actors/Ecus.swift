//
//  Ecus.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import Foundation

struct Ecus {
    var ecus: [Ecu] = []

    static var getInstance = Ecus()

    mutating func load(assetName: String) {
        if assetName == "" {
            fillFromAsset(assetName: getDefaultAssetName())
        } else {
            fillFromAsset(assetName: assetName)
        }
    }

    func getDefaultAssetName() -> String {
        return "_assets/" + Utils.getAssetPrefix() + "_Ecus.csv"
    }

    mutating func fillFromAsset(assetName: String) {
        let p = assetName
        let path = Bundle.main.path(forResource: p, ofType: nil)
        if path != nil {
            do {
                let completo = try String(contentsOfFile: path!, encoding: .utf8)
                let righe = completo.components(separatedBy: "\n")
                // print(righe.count)
                ecus = []
                for riga in righe {
//                    let campi = riga.components(separatedBy: ",")
//                    print(campi.count)
                    fillOneLine(line_: riga)
                }
              //  print("loaded ecus: \(ecus.count)")
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
        if tokens.count == 10 {
            // Create a new field object and fill his  data
            let ecu = Ecu(
                name: trim(s: tokens[0]), // name
                renaultId: Int(trim(s: tokens[1])), // Renault ID
                networks: trim(s: tokens[2]), // Network
                fromId: Int(trim(s: tokens[3]), radix: 16), // From ID
                toId: Int(trim(s: tokens[4]), radix: 16), // To ID
                mnemonic: trim(s: tokens[5]), // Mnemonic
                aliases: trim(s: tokens[6]), // Aliasses, semicolon separated
                getDtcs: trim(s: tokens[7]), // GetDtc responseIDs, semicolon separated
                startDiag: trim(s: tokens[8]), // startDiag
                sessionRequired: trim(s: tokens[9]) == "1", // Session required
                fields: nil
            )
            // add the field to the list of available fields
            ecus.append(ecu)
            //   print("ecu: \(trim(s: tokens[5]))")
        }
    }

    func getByMnemonic(mnemonic: String) -> Ecu? {
        for ecu in ecus {
            if ecu.mnemonic == mnemonic || ecu.aliases.contains(mnemonic) {
                return ecu
            }
        }
        return nil
    }

    func getByFromId(fromId: Int) -> Ecu {
        for ecu in ecus {
            if ecu.fromId == fromId {
                return ecu
            }
        }
        return Ecu()
    }

    func trim(s: String) -> String {
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
