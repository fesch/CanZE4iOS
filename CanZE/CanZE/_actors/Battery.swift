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

    mutating func predictMaxDcPower() {
        // if the state of charge (in kW) exceeds the capacity of the battery
        if stateOfCharge >= capacity {
            // stop charging
            maxDcPower = 0.0

            // if there is capacity left to charge
        } else {
            // calculate the SOC in percantage
            let stateOfChargePercentage = stateOfCharge * 100.0 / capacity

            // get a rounded temperature
            let intTemperature = Int(temperature)

            // now use a model to calculate the DC power, based on SOC and temperature
//            maxDcPower = cons + (tempx * intTemperature) + (tempxsocy * stateOfChargePercentage * intTemperature) + (socy * stateOfChargePercentage)
            let x = tempx * Double(intTemperature)
            let y = tempxsocy * stateOfChargePercentage * Double(intTemperature)
            let z = socy * stateOfChargePercentage

            maxDcPower = cons + x + y + z

            if maxDcPower > dcPowerUpperLimit {
                maxDcPower = dcPowerUpperLimit
            } else if maxDcPower < dcPowerLowerLimit {
                maxDcPower = dcPowerLowerLimit
            }
        }
    }

    mutating func predictDcPower() {
        // calculate what the battery can take
        predictMaxDcPower()

        // predict the efficiency of the charger (assuming it will run at the cpacity the battery can take)
        var efficiency = 0.80 + maxDcPower * 0.00375

        // predict what is needed on the AC side to give thabattery what it can take
        let requestedAcPower = maxDcPower / efficiency

        // if this is more than what the charger can deliver
        if requestedAcPower > chargerPower {
            // recalculate the efficiency based on the maximum the charger can deliver
            efficiency = 0.80 + chargerPower * 0.00375

            // DC is maximum AC corrected for efficiency
            dcPower = chargerPower * efficiency

            // if this is less than the charger can delever
        } else {
            // DC is what the battery can take
            dcPower = maxDcPower
        }
    }

    /*
     * iteration is in effect numerical integration of the power function to the SOC, respecting temperature and energy efficiency effects
     */
    mutating func iterateCharging(_ seconds: Int) {
        secondsRunning += seconds
        predictDcPower()
        setTemperature(temperature + (Double(seconds) * dcPower / 7200)) // assume one degree per 40 kW per 3 minutes (180 seconds)
        setStateOfChargeKw(stateOfCharge + (dcPower * Double(seconds) * 0.95) / 3600) // 1kW adds 95% of 1kWh in 60 minutes
    }

    mutating func adjustRawCapacity() {
        // adjust for capacity loss due to temperature differences (system wide)
        if temperature > 15.0 { // above 15C: 100%
            capacity = rawCapacity
        } else if temperature > 0 { // above 0C: 10% gradual decline over the 15C
            capacity = rawCapacity * (0.9 + temperature * 0.1 / 15.0)
        } else { // under 0C: 20% gradual decline per 15C
            capacity = rawCapacity * (0.9 + temperature * 0.2 / 15.0)
        }
        capacity = capacity * soh / 100.0
        // ensure the SOC is refreshed. This is only relevant for a very full battery
        setStateOfChargeKw(stateOfCharge)
    }

    mutating func setBatteryType(_ batteryType: Int) {
        switch batteryType {
            case 22:
                setRawCapacity(22)
                // setCoefficients (19.00,  3.600, -0.026, -0.34000);
                setCoefficients(cons: 19.00, tempx: 3.600, socy: -0.340, tempxsocy: -0.02600)
            case 41:
                setCoefficients(cons: 14.93, tempx: 1.101, socy: -0.145, tempxsocy: -0.00824)
                setRawCapacity(41.0)
            default:
                print("unknown battery type")
        }
    }

    /*
     * Getters and setters
     */

    mutating func setCoefficients(cons: Double, tempx: Double, socy: Double, tempxsocy: Double) {
        self.cons = cons
        self.tempx = tempx
        self.socy = socy
        self.tempxsocy = tempxsocy
    }

    mutating func setTemperature(_ temperature: Double) {
        self.temperature = temperature
        adjustRawCapacity()
    }

    mutating func setStateOfChargeKw(_ stateOfCharge: Double) {
        self.stateOfCharge = stateOfCharge
        if self.stateOfCharge > capacity {
            self.stateOfCharge = capacity
        }
    }

    func getStateOfChargePerc() -> Double {
        return stateOfCharge * 100 / capacity
    }

    mutating func setStateOfChargePerc(_ stateOfCharge: Double) {
        setStateOfChargeKw(stateOfCharge * capacity / 100)
    }

    mutating func setChargerPower(_ chargerPower: Double) {
        self.chargerPower = chargerPower
        if self.chargerPower > 43.0 {
            self.chargerPower = 43.0
        } else if self.chargerPower < 1.84 {
            self.chargerPower = 1.84
        }
    }

    mutating func getDcPower() -> Double {
        predictDcPower()
        return dcPower
    }

    mutating func setRawCapacity(_ rawCapacity: Double) {
        self.rawCapacity = rawCapacity
        adjustRawCapacity()
    }

    mutating func setStateOfHealth(_ soh: Double) {
        self.soh = soh
        adjustRawCapacity()
    }
}
