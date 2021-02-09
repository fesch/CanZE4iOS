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
            fillFromAsset(assetName: "_assets/\(Utils.getAssetPrefix())\(assetName)")
        }
    }

    func getDefaultAssetName() -> String {
        return "_assets/" + Utils.getAssetPrefix() + "_Ecus.csv"
    }

    mutating func fillFromAsset(assetName: String) {
        let p = assetName
        if let path = Bundle.main.path(forResource: p, ofType: nil) {
            do {
                let completo = try String(contentsOfFile: path, encoding: .utf8)
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
                name: tokens[0].trim(), // name
                renaultId: Int(tokens[1].trim()), // Renault ID
                networks: tokens[2].trim(), // Network
                fromId: Int(tokens[3].trim(), radix: 16), // From ID
                toId: Int(tokens[4].trim(), radix: 16), // To ID
                mnemonic: tokens[5].trim(), // Mnemonic
                aliases: tokens[6].trim(), // Aliases, semicolon separated
                getDtcs: tokens[7].trim(), // GetDtc responseIDs, semicolon separated
                startDiag: tokens[8].trim(), // start Diagnostic sessioncommand
                sessionRequired: tokens[9].trim() == "1", // Session required
                fields: nil
            )
            // add the field to the list of available fields
            ecus.append(ecu)
            //   print("ecu: \( tokens[5]))")
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

    func getAllEcus() -> [Ecu] {
        return ecus
    }
}
