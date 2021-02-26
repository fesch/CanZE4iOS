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

    let ud = UserDefaults.standard

    // init elm327
    let autoInitElm327: [String] = ["ate0", "ats0", "ath0", "atl0", "atal", "atcaf0", "atfcsh77b", "atfcsd300000", "atfcsm1", "atsp6"]

    var timeoutTimer: Timer!

    // queue
    // var queue: [String] = []
    var queueInit: [String] = []
    var queue2: [Sequence] = []
    var indiceCmd = 0
    var lastRxString = ""
    var lastId = -1
    var lastDebugMessage = ""
    var lastReply = ""

    var pickerTitles: [String]? = []
    var pickerValues: [Any]? = []
    enum PickerPhase: String {
        case PERIPHERAL
        case SERVICES
        case WRITE_CHARACTERISTIC
        case READ_CHARACTERISTIC
    }

    var pickerPhase: PickerPhase = .PERIPHERAL

    // WIFI
    var timeoutTimerWifi: Timer!
    let maxReadLength = 4096
    var inputStream: InputStream!
    var outputStream: OutputStream!
    var incompleteReply = ""
    var repliesAddedCounter = 0

    // BLE
    var centralManager: CBCentralManager!
    var timeoutTimerBle: Timer!
    enum BlePhase: String {
        case DISCOVER
        case DISCOVERED
    }

    var blePhase: BlePhase = .DISCOVERED
}
