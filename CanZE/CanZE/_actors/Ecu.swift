//
//  Ecu.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import Foundation

struct Ecu {
    var name: String!
    var renaultId: Int!
    var networks: String! // single letter network names, semicolon separated, V, M, O, E
    var fromId: Int! = 0
    var toId: Int! = 0
    var mnemonic: String!
    var aliases: String! // semicolon separated
    var getDtcs: String! // semicolon separated
    var startDiag: String!
    var sessionRequired: Bool!

    var fields: Fields!
}
