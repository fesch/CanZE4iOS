//
//  Battery.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import Foundation

struct Battery {
    var temperature = 10.0
    var stateOfCharge = 11.0 // watch it: in kWh!!!
    var chargerPower = 11.0 // in kW
    var capacity = 22.0 // in kWh
    var maxDcPower = 0.0 // in kW. This excludes the max imposed by the external charger
    var dcPower = 0.0 // in kW This includes the max imposed by the external charger
    var secondsRunning = 0 // seconds in iteration, reset by setStateOfChargePerc
    var dcPowerUpperLimit = 40.0 // for R240/R90 use 20
    var dcPowerLowerLimit = 2.0 // for R240/R90 use 1
    var rawCapacity = 22.0 // R90/Q90 use 41
    var batteryType = 22 //
    var cons: Double!
    var tempx: Double!
    var socy: Double!
    var tempxsocy: Double!
    var soh = 100.0
}
