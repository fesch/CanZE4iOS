//
//  Globals.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import CoreBluetooth
import Foundation
import UIKit

class Globals: NSObject {
    static var shared = Globals()

    // APP CONFIG
    var car = AppSettings.CAR_NONE
    var milesMode = false
    var deviceConnection: AppSettings.DEVICE_CONNECTION = .NONE
    var deviceType: AppSettings.DEVICE_TYPE = .NONE
    var useIsoTpFields = false

    // WIFI
    var deviceWifiAddress = ""
    var deviceWifiPort = ""
    var inputStream: InputStream!
    var outputStream: OutputStream!

    // BLE
    var peripheralsDic: [String: BlePeripheral]!
    var servicesArray: [CBService]!
    var characteristicArray: [CBCharacteristic]!
    var selectedPeripheral: BlePeripheral!
    var selectedService: CBService!
    var selectedWriteCharacteristic: CBCharacteristic!
    var selectedReadCharacteristic: CBCharacteristic!
    var deviceBleName: AppSettings.DEVICE_BLE_NAME = .NONE
    var deviceBlePeripheralName = ""
    var deviceBlePeripheralUuid = ""
    var deviceBleServiceUuid = ""
    var deviceBleReadCharacteristicUuid = ""
    var deviceBleWriteCharacteristicUuid = ""

    // HTTP
    var deviceHttpAddress = ""

    // DEVICE STATUS
    var deviceIsConnected = false
    var deviceIsInitialized = false

    // LOGGER
    var logger = Logger()
    var loggerEmulator = LoggerEmulator()
    var writeForEmulator = false
    var useSdCard = false
    var sidFatti: [String] = []

    // RESULTS
    var fieldResultsDouble: [String: Double] = [:]
    var fieldResultsString: [String: String] = [:]
    var resultsBySid: [String: FieldResult] = [:]

    static let reduction = 9.32 // update suggested by Loc Dao
    var lastTime: [String: Double] = [:]

    static let K_TAG_vBG = 99999
}
