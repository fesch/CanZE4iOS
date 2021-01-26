//
//  Sid.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import Foundation

class Sid: NSObject {
    static let DriverBrakeWheel_Torque_Request = "130.44" // UBP braking wheel torque the driver wants
    static let MeanEffectiveTorque = "186.16"
    static let Pedal = "186.40" // EVC
    static let Coasting_Torque = "18a.27"
    static let TotalPotentialResistiveWheelsTorque = "1f8.16" // UBP 10ms
    static let ElecBrakeWheelsTorqueApplied = "1f8.28" // 10ms
    static let Aux12A = "1fd.0"
    static let VehicleState = "35c.5"
    static let SoC = "42e.0" // EVC
    static let EngineFanSpeed = "42e.20"
    static let ACPilotAmps = "42e.38"
    static let ChargingPower = "42e.56"
    static let HvCoolingState = "430.38"
    static let HvEvaporationTemp = "430.40"
    static let BatteryConditioningMode = "432.36"
    static let ClimaLoopMode = "42a.48"
    static let UserSoC = "42e.0"
    static let AvailableChargingPower = "427.40"
    static let AvailableEnergy = "427.49"
    static let HvTemp = "42e.44"
    static let RealSpeed = "5d7.0" // ESC-ABS
    static let AuxStatus = "638.37"
    static let WorstAverageConsumption = "62d.0"
    static let BestAverageConsumption = "62d.10"
    static let PlugConnected = "654.2"
    static let RangeEstimate = "654.42"
    static let AverageConsumption = "654.52"
    static let ChargingStatusDisplay = "65b.41"
    static let TireSpdPresMisadaption = "673.0"
    static let TireRRState = "673.2"
    static let TireRLState = "673.5"
    static let TireFRState = "673.8"
    static let TireFLState = "673.11"
    static let TireRRPressure = "673.16"
    static let TireRLPressure = "673.24"
    static let TireFRPressure = "673.32"
    static let TireFLPressure = "673.40"
    static let HeaterSetpoint = "699.8"

    static let ThermalComfortPower = "764.6143.88"
    static let Pressure = "764.6143.134"
    static let OH_ClimTempDisplay = "764.6145.29"

    static let TpmsState = "765.6171.16"

    static let BcbTesterInit = "793.50c0.0"
    static let BcbTesterAwake = "793.7e01.0"
    static let BcbVersion = "793.6180.144"
    static let Phase1currentRMS = "793.622001.24"
    static let MainsCurrentType = "793.625017.29"
    static let ACPilotDutyCycle = "793.625026.24"
    static let PhaseVoltage1 = "793.62502c.24" // Raw
    static let PhaseVoltage2 = "793.62502d.24"
    static let PhaseVoltage3 = "793.62502e.24"
    static let Phase2CurrentRMS = "793.62503a.24" // Raw <= this seems to be instant DC coupled value
    static let Phase3CurrentRMS = "793.62503b.24"
    static let InterPhaseVoltage12 = "793.62503f.24" // Measured
    static let InterPhaseVoltage23 = "793.625041.24"
    static let InterPhaseVoltage31 = "793.625042.24"
    static let MainsActivePower = "793.62504a.24"
    static let GroundResistance = "793.625062.24"
    static let SupervisorState = "793.625063.24"
    static let CompletionStatus = "793.625064.24"

    static let MaxCharge = "7bb.6101.336"
    static let RealSoC = "7bb.6103.192"
    static let AverageBatteryTemperature = "7bb.6104.600" // (LBC)
    static let Preamble_CompartmentTemperatures = "7bb.6104." // (LBC)
    static let Preamble_BalancingBytes = "7bb.6107."
    static let Preamble_CellVoltages1 = "7bb.6141." // (LBC)
    static let Preamble_CellVoltages2 = "7bb.6142." // (LBC)
    static let HvKilometers = "7bb.6161.96"
    static let Total_kWh = "7bb.6161.120"
    static let BatterySerial = "7bb.6162.16" // EVC
    static let Counter_Full = "7bb.6166.48"
    static let Counter_Partial = "7bb.6166.64"

    static let HydraulicTorqueRequest = "7bc.624b7d.28" // Total Hydraulic brake wheels torque request

    static let CCSEVRequestState = "7c8.620326.28"
    static let CCSEVReady = "7c8.620329.31"
    static let CCSEVSEState = "7c8.62032c.28"
    static let CCSEVSECurrentLimitReached = "7c8.62032d.31"
    static let CCSEVSEPowerLimitReached = "7c8.620334.31"
    static let CCSEVSEPresentCurrent = "7c8.620335.24"
    static let CCSEVSEPresentVoltage = "7c8.620336.24"
    static let CCSEVSEVoltageLimitReaced = "7c8.620337.31"
    static let CCSFailureStatus = "7c8.62033b.24"
    static let CCSCPLCComStatus = "7c8.62033a.28"
    static let CCSEVSEStatus = "7c8.62033c.24"

    static let EVC = "7ec.5003.0" // EVC open Note we use 7ec as the EVC has custom SID codes for older model compatilbility
    static let Aux12V = "7ec.622005.24"
    static let EVC_Odometer = "7ec.622006.24"
    static let TorqueRequest = "7ec.622243.24"
    static let DcLoad = "7ec.623028.24"
    static let TractionBatteryVoltage = "7ec.623203.24"
    static let TractionBatteryCurrent = "7ec.623204.24"
    static let SOH = "7ec.623206.24"
    static let Preamble_KM = "7ec.6233d4." // 240 - 24
    static let Preamble_END = "7ec.6233d5." //  96 -  8
    static let Preamble_TYP = "7ec.6233d6." //  96 -  8
    static let Preamble_SOC = "7ec.6233d7." // 168 - 16
    static let Preamble_TMP = "7ec.6233d8." //  96 -  8
    static let Preamble_DUR = "7ec.6233d9." // 168 - 16
    static let TripMeterB = "7ec.6233de.24"
    static let TripEnergyB = "7ec.6233dd.24"
    static let CurrentUnderLoad = "7ec.623484.24" // Current measurement given by BCS Battery Current Sensor
    static let VoltageUnderLoad = "7ec.623485.24" // Voltage measurement given by BCS Battery Current Sensor
    static let PtcRelay1 = "7ec.623498.31"
    static let PtcRelay2 = "7ec.62349a.31"
    static let PtcRelay3 = "7ec.62349c.31"

    static let PEBTorque = "77e.623025.24"

    static let Instant_Consumption = "800.6100.24"
    static let FrictionTorque = "800.6101.24"
    static let DcPowerIn = "800.6103.24" // Virtual field
    static let DcPowerOut = "800.6109.24"
    static let ElecBrakeTorque = "800.610a.24"
    static let TotalPositiveTorque = "800.610b.24"
    static let TotalNegativeTorque = "800.610c.24"
    static let ACPilot = "800.610d.24"

    static let CCSEVSEMaxPower = "18daf1da.623006.24"
    static let CCSEVSEMaxVoltage = "18daf1da.623008.24"
    static let CCSEVSEMaxCurrent = "18daf1da.62300a.24"

    static let Total_Regen_kWh = "18daf1db.629247.24" // Ph2 only (for now)
}
