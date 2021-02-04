//
//  AppSettings.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 30/12/20.
//

import Foundation

class AppSettings: NSObject {
    // car
    static let SETTINGS_CAR: String = "SETTINGS_CAR"
    static let CAR_NONE: Int = 0x000
    static let CAR_TWINGO: Int = 0x001
    static let CAR_ZOE_Q210: Int = 0x002
    static let CAR_TWIZY: Int = 0x008
    static let CAR_X10PH2: Int = 0x010 // ZE50
    static let CAR_ZOE_R240: Int = 0x020
    static let CAR_ZOE_Q90: Int = 0x040
    static let CAR_ZOE_R90: Int = 0x080

    static let SETTINGS_CAR_USE_MILES = "SETTINGS_CAR_USE_MILES"

    // DEVICE_CONNECTION
    enum DEVICE_CONNECTION: Int {
        case NONE
        case BLE
        case WIFI
        case HTTP
    }

    static let SETTINGS_DEVICE_CONNECTION = "SETTINGS_DEVICE_CONNECTION"

    // DEVICE_TYPE
    enum DEVICE_TYPE: Int {
        case NONE
        case ELM327
        case CANSEE
        case HTTP
    }

    static let SETTINGS_DEVICE_TYPE = "SETTINGS_DEVICE_TYPE"

    // DEVICE_BLE_NAME
    enum DEVICE_BLE_NAME: Int {
        case NONE
        case VGATE
        case LELINK
    }

    static let SETTINGS_DEVICE_BLE_NAME = "SETTINGS_DEVICE_BLE_NAME"
    static let SETTINGS_DEVICE_BLE_PERIPHERAL_NAME = "SETTINGS_DEVICE_BLE_PERIPHERAL_NAME"
    static let SETTINGS_DEVICE_BLE_PERIPHERAL_UUID = "SETTINGS_DEVICE_BLE_PERIPHERAL_UUID"
    static let SETTINGS_DEVICE_BLE_SERVICE_UUID = "SETTINGS_DEVICE_BLE_SERVICE_UUID"
    static let SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID = "SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID"
    static let SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID = "SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID"

    static let SETTINGS_DEVICE_WIFI_ADDRESS = "SETTINGS_DEVICE_WIFI_ADDRESS"
//    static let DEVICE_WIFI_ADDRESS = "DEVICE_WIFI_ADDRESS"
    static let SETTINGS_DEVICE_WIFI_PORT = "SETTINGS_DEVICE_WIFI_PORT"
//    static let DEVICE_WIFI_PORT = "DEVICE_WIFI_PORT"

    static let SETTINGS_DEVICE_HTTP_ADDRESS = "SETTINGS_DEVICE_HTTP_ADDRESS"
//    static let DEVICE_HTTP_ADDRESS = "DEVICE_HTTP_ADDRESS"

    static let SETTINGS_DEVICE_USE_ISOTP_FIELDS = "SETTINGS_DEVICE_USE_ISOTP_FIELDS"

    static var shared = AppSettings()
}
