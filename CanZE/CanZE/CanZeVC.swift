//
//  CanZeVC.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/02/21.
//

import UIKit

class CanZeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("CanZeViewController")

        Globals.shared.peripheralsDic = [:]

        loadSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if Globals.shared.deviceIsConnected {
            deviceConnected()
        } else {
            deviceDisconnected()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(deviceConnected), name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDisconnected), name: Notification.Name("deviceDisconnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFromWifiDongle(notification:)), name: Notification.Name("didReceiveFromWifiDongle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(received(notification:)), name: Notification.Name("received"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(received2(notification:)), name: Notification.Name("received2"), object: nil)

        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Globals.shared.queue2 = []
        Globals.shared.lastId = 0

        if Globals.shared.timeoutTimer != nil {
            if Globals.shared.timeoutTimer.isValid {
                Globals.shared.timeoutTimer.invalidate()
            }
            Globals.shared.timeoutTimer = nil
            //            disconnect(showToast: true)
        }
        if Globals.shared.timeoutTimerBle != nil {
            if Globals.shared.timeoutTimerBle.isValid {
                Globals.shared.timeoutTimerBle.invalidate()
            }
            Globals.shared.timeoutTimerBle = nil
            //            disconnect(showToast: true)
        }
        if Globals.shared.timeoutTimerWifi != nil {
            if Globals.shared.timeoutTimerWifi.isValid {
                Globals.shared.timeoutTimerWifi.invalidate()
            }
            Globals.shared.timeoutTimerWifi = nil
            //            disconnect(showToast: true)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceDisconnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("didReceiveFromWifiDongle"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
    }

    func loadSettings() {
        Globals.shared.car = AppSettings.CAR_NONE
        Globals.shared.car = Globals.shared.ud.integer(forKey: AppSettings.SETTINGS_CAR)
        switch Globals.shared.car {
        case AppSettings.CAR_TWINGO:
            print("CAR_TWINGO")
        case AppSettings.CAR_TWIZY:
            print("CAR_TWIZY")
        case AppSettings.CAR_X10PH2:
            print("CAR_X10PH2")
        case AppSettings.CAR_ZOE_Q90:
            print("CAR_ZOE_Q90")
        case AppSettings.CAR_ZOE_R90:
            print("CAR_ZOE_R90")
        case AppSettings.CAR_ZOE_Q210:
            print("CAR_ZOE_Q210")
        case AppSettings.CAR_ZOE_R240:
            print("CAR_ZOE_R240")
        default:
            print("unknown")
        }

        Globals.shared.deviceConnection = AppSettings.DEVICE_CONNECTION(rawValue: Globals.shared.ud.value(forKey: AppSettings.SETTINGS_DEVICE_CONNECTION) as? Int ?? 0) ?? .NONE

        Globals.shared.deviceWifiAddress = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS) ?? "192.168.0.10"
        Globals.shared.deviceWifiPort = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT) ?? "35000"
        Globals.shared.ud.setValue(Globals.shared.deviceWifiAddress, forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
        Globals.shared.ud.setValue(Globals.shared.deviceWifiPort, forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT)
        Globals.shared.ud.synchronize()

        Globals.shared.deviceBleName = AppSettings.DEVICE_BLE_NAME(rawValue: Globals.shared.ud.value(forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME) as? Int ?? 0) ?? .NONE
        Globals.shared.deviceBlePeripheralName = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_NAME) ?? ""
        Globals.shared.deviceBlePeripheralUuid = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID) ?? ""
        Globals.shared.deviceBleServiceUuid = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID) ?? ""
        Globals.shared.deviceBleReadCharacteristicUuid = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID) ?? ""
        Globals.shared.deviceBleWriteCharacteristicUuid = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID) ?? ""

        Globals.shared.deviceHttpAddress = Globals.shared.ud.string(forKey: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS) ?? ""

        switch Globals.shared.deviceConnection {
        case .WIFI:
            print("DEVICE_CONNECTION_WIFI")
            print(Globals.shared.deviceWifiAddress)
            print(Globals.shared.deviceWifiPort)
        case .BLE:
            print("DEVICE_CONNECTION_BLE")

            switch Globals.shared.deviceBleName {
            case .VGATE:
                print("VGATE")
            case .LELINK:
                print("LELINK")
            default:
                print("unknown")
            }
            print(Globals.shared.deviceBlePeripheralName)
            print(Globals.shared.deviceBlePeripheralUuid)
            print(Globals.shared.deviceBleServiceUuid)
            print(Globals.shared.deviceBleReadCharacteristicUuid)
            print(Globals.shared.deviceBleWriteCharacteristicUuid)
        case .HTTP:
            print("DEVICE_CONNECTION_HTTP")
            print(Globals.shared.deviceHttpAddress)
        default:
            print("unknown")
        }

        Globals.shared.deviceType = AppSettings.DEVICE_TYPE(rawValue: Globals.shared.ud.value(forKey: AppSettings.SETTINGS_DEVICE_TYPE) as? Int ?? 0) ?? .NONE
        switch Globals.shared.deviceType {
        case .ELM327:
            print("DEVICE_TYPE_ELM327")
        case .CANSEE:
            print("DEVICE_TYPE_CANSEE")
        case .HTTP_GW:
            print("DEVICE_TYPE_HTTP_GW")
        default:
            print("unknown")
        }

        /*
         Globals.shareds.safeDrivingMode = true
         if Globals.shared.ud.exists(key: AppSettings.SETTING_SECURITY_SAFE_MODE) {
         Globals.shared.safeDrivingMode = Globals.shared.ud.bool(forKey: AppSettings.SETTING_SECURITY_SAFE_MODE)
         }
         */

        Globals.shared.milesMode = false
        if Globals.shared.ud.exists(key: AppSettings.SETTINGS_CAR_USE_MILES) {
            Globals.shared.milesMode = Globals.shared.ud.bool(forKey: AppSettings.SETTINGS_CAR_USE_MILES)
        }
        print("SETTINGS_CAR_USE_MILES \(Globals.shared.milesMode)")

        Globals.shared.useIsoTpFields = true
        if Globals.shared.ud.exists(key: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS) {
            Globals.shared.useIsoTpFields = Globals.shared.ud.bool(forKey: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS)
        }
        if Globals.shared.car == AppSettings.CAR_X10PH2 { // Ph2 car has no IsoTp Fields
            Globals.shared.useIsoTpFields = false
        }
        print("SETTINGS_DEVICE_USE_ISOTP_FIELDS \(Globals.shared.useIsoTpFields)")

        Globals.shared.useSdCard = false
        if Globals.shared.ud.exists(key: AppSettings.SETTING_LOGGING_USE_SD_CARD) {
            Globals.shared.useSdCard = Globals.shared.ud.bool(forKey: AppSettings.SETTING_LOGGING_USE_SD_CARD)
        }

        Globals.shared.writeForEmulator = false
        if Globals.shared.ud.exists(key: AppSettings.SETTING_LOGGING_WRITE_FOR_EMULATOR) {
            Globals.shared.writeForEmulator = Globals.shared.ud.bool(forKey: AppSettings.SETTING_LOGGING_WRITE_FOR_EMULATOR)
        }

        /*
         Globals.shared.debugLogMode = false
         if Globals.shared.ud.exists(key: SETTING_LOGGING_DEBUG_LOG) {
         Globals.shared.debugLogMode = Globals.shared.ud.bool(forKey: SETTING_LOGGING_DEBUG_LOG)
         }

         Globals.shared.fieldLogMode = false
         if Globals.shared.ud.exists(key: SETTING_LOGGING_FIELDS_LOG) {
         Globals.shared.fieldLogMode = Globals.shared.ud.bool(forKey: SETTING_LOGGING_FIELDS_LOG)
         }

         Globals.shared.toastLevel = TOAST_ELM
         if Globals.shared.ud.exists(key: SETTING_DISPLAY_TOAST_LEVEL) {
         Globals.shared.toastLevel = Globals.shared.ud.integer(forKey: SETTING_DISPLAY_TOAST_LEVEL)
         }
         */

        Ecus.getInstance.load(assetName: "")
        Frames.getInstance.load(assetName: "")
        Fields.getInstance.load(assetName: "")
    }

    func debug(_ s: String) {
        print(s)
        if Globals.shared.useSdCard {
            Globals.shared.logger.add(s)
        }
    }

    func NSLocalizedString_(_ key: String, comment: String) -> String {
        var v = NSLocalizedString(key, comment: "")
        v = v.replacingOccurrences(of: "u0020", with: " ")
        while v.contains("\\'") {
            v = v.replacingOccurrences(of: "\\'", with: "'")
        }
        return v
    }

    func localizableFromPlist(_ key: String) -> [String] {
        let dic = NSDictionary(contentsOf: Bundle.main.url(forResource: "Localizable", withExtension: "plist")!)
        let values = dic![key] as! [String]
        var newValues: [String] = []
        for value in values {
            var v = value
            if v.contains("u0020") {
                v = v.replacingOccurrences(of: "u0020", with: " ")
            }
            while v.contains("\\'") {
                v = v.replacingOccurrences(of: "\\'", with: "'")
            }
            newValues.append(v)
        }
        return newValues
    }
}
