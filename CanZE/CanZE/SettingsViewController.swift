//
//  SettingsViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import FirebaseAnalytics
import Toast_Swift
import UIKit

class SettingsViewController: CanZeViewController {
    @IBOutlet var settingsTableView: UITableView!

    @IBOutlet var pickerView: UIView!
    @IBOutlet var picker: UIPickerView!
    @IBOutlet var btnPickerCancel: UIButton!
    @IBOutlet var btnPickerDone: UIButton!

    @IBOutlet var textFieldView: UIView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var btnTextFieldCancel: UIButton!
    @IBOutlet var btnTextFieldDone: UIButton!

    var settingsDic: [String: [Setting]] = [:]
    let titleSeparator = "$$$"
    var lastSelectedIndexPath: IndexPath!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_settings", comment: "")

        let b = navigationItem.rightBarButtonItems?.first
        b?.title = NSLocalizedString_("Test dongle", comment: "")

        settingsTableView.delegate = self
        settingsTableView.dataSource = self

        setupPickers()

        organizeSettings()

        settingsTableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        NotificationCenter.default.addObserver(self, selector: #selector(reloadPicker(notification:)), name: Notification.Name("reloadPicker"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
//        NotificationCenter.default.removeObserver(self, name: Notification.Name("reloadPicker"), object: nil)

        var car = ""

        switch Globals.shared.car {
        case AppSettings.CAR_TWINGO:
            car = "CAR_TWINGO"
        case AppSettings.CAR_TWIZY:
            car = "CAR_TWIZY"
        case AppSettings.CAR_X10PH2:
            car = "CAR_X10PH2"
        case AppSettings.CAR_ZOE_Q90:
            car = "CAR_ZOE_Q90"
        case AppSettings.CAR_ZOE_R90:
            car = "CAR_ZOE_R90"
        case AppSettings.CAR_ZOE_Q210:
            car = "CAR_ZOE_Q210"
        case AppSettings.CAR_ZOE_R240:
            car = "CAR_ZOE_R240"
        default:
            car = "unknown"
        }

        var deviceConnection = ""
        var deviceBleName = ""
        switch Globals.shared.deviceConnection {
        case .WIFI:
            deviceConnection = "WIFI"
        case .BLE:
            deviceConnection = "BLE"
            switch Globals.shared.deviceBleName {
            case .VGATE:
                deviceBleName = "VGATE"
            case .LELINK:
                deviceBleName = "LELINK"
            case .OBDII:
                deviceBleName = "OBDII"
            default:
                deviceBleName = "unknown"
            }
        case .HTTP:
            deviceConnection = "HTTP"
        default:
            deviceConnection = "unknown"
        }

        var deviceType = ""
        switch Globals.shared.deviceType {
        case .ELM327:
            deviceType = "ELM327"
        case .CANSEE:
            deviceType = "CANSEE"
        case .HTTP_GW:
            deviceType = "HTTP_GW"
        default:
            deviceType = "unknown"
        }

        Analytics.logEvent("settings", parameters: [
            "car": car as NSObject,
            "deviceConnection": deviceConnection as NSObject,
            "deviceBleName": deviceBleName as NSObject,
            "deviceType": deviceType as NSObject,
        ]
        )
    }

//    @objc func reloadPicker(notification: Notification) {
//        picker.reloadAllComponents()
//    }

    func setupPickers() {
        // picker
        pickerView.alpha = 0.0
        picker.delegate = self
        // btnPickerDone.backgroundColor = .lightGray
        // btnPickerCancel.backgroundColor = .lightGray
        btnPickerDone.setTitle(NSLocalizedString_("default_Ok", comment: "").uppercased(), for: .normal)
        btnPickerCancel.setTitle(NSLocalizedString_("default_Cancel", comment: "").lowercased(), for: .normal)

        // textfield
        textFieldView.alpha = 0.0
        // btnTextFieldDone.backgroundColor = .lightGray
        // btnTextFieldCancel.backgroundColor = .lightGray
        btnTextFieldDone.setTitle(NSLocalizedString_("default_Ok", comment: "").uppercased(), for: .normal)
        btnTextFieldCancel.setTitle(NSLocalizedString_("default_Cancel", comment: "").lowercased(), for: .normal)
    }

    func showPicker() {
        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        vBG.tag = Globals.K_TAG_vBG
        view.insertSubview(vBG, belowSubview: pickerView)

        pickerView.alpha = 1.0
        picker.reloadAllComponents()
    }

    func hidePicker() {
        pickerView.alpha = 0.0
        let vBG = view.viewWithTag(Globals.K_TAG_vBG)
        vBG?.removeFromSuperview()
    }

    func organizeSettings() {
        settingsDic = [:]

        // car
        var settingsArray: [Setting] = []
        var titolo = NSLocalizedString_("label_Car", comment: "")

        var s = Setting(tag: AppSettings.SETTINGS_CAR, type: .PICKER, title: NSLocalizedString_("label_CarModel", comment: ""), listTitles: [
            "ZOE Q210",
            "ZOE R240",
            "ZOE Q90",
            "ZOE R90/110",
            "ZOE ZE40/ZE50",
            "TWINGO (experimental)",
            "TWIZY (experimental)",
        ], listValues: [
            AppSettings.CAR_ZOE_Q210,
            AppSettings.CAR_ZOE_R240,
            AppSettings.CAR_ZOE_Q90,
            AppSettings.CAR_ZOE_R90,
            AppSettings.CAR_X10PH2,
            AppSettings.CAR_TWINGO,
            AppSettings.CAR_TWIZY,
        ], intValue: Globals.shared.car)
        settingsArray.append(s)

        s = Setting(tag: AppSettings.SETTINGS_CAR_USE_MILES, type: .SWITCH, title: NSLocalizedString_("label_DistanceUnit", comment: ""), subTitle: Globals.shared.milesMode ? NSLocalizedString_("label_Miles", comment: "") : NSLocalizedString_("label_Kilometers", comment: ""), boolValue: Globals.shared.milesMode)
        settingsArray.append(s)

        settingsDic["\(settingsDic.count)\(titleSeparator)\(titolo)"] = settingsArray

        // device
        settingsArray = []
        titolo = NSLocalizedString_("label_Settings_Device", comment: "")

        s = Setting(tag: AppSettings.SETTINGS_DEVICE_TYPE, type: .PICKER, title: NSLocalizedString_("label_DeviceType", comment: ""), listTitles: [
            NSLocalizedString_("ELM327", comment: ""),
            NSLocalizedString_("CANSee", comment: ""),
            NSLocalizedString_("Http Gateway", comment: ""),
        ], listValues: [
            AppSettings.DEVICE_TYPE.ELM327.rawValue,
            AppSettings.DEVICE_TYPE.CANSEE.rawValue,
            AppSettings.DEVICE_TYPE.HTTP_GW.rawValue,
        ], intValue: Globals.shared.deviceType.rawValue)
        settingsArray.append(s)

        s = Setting(tag: AppSettings.SETTINGS_DEVICE_CONNECTION, type: .PICKER, title: NSLocalizedString_("Connection", comment: ""), listTitles: [
            NSLocalizedString_("BLE", comment: ""),
            NSLocalizedString_("WiFi", comment: ""),
            NSLocalizedString_("HTTP", comment: ""),
        ], listValues: [
            AppSettings.DEVICE_CONNECTION.BLE.rawValue,
            AppSettings.DEVICE_CONNECTION.WIFI.rawValue,
            AppSettings.DEVICE_CONNECTION.HTTP.rawValue,
        ], intValue: Globals.shared.deviceConnection.rawValue)
        settingsArray.append(s)

        if Globals.shared.deviceConnection == .WIFI {
            var placeHolder = "192.168.0.10"
            if Globals.shared.deviceType == .CANSEE {
                placeHolder = "192.168.4.1"
            }
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS, type: .TEXTFIELD, title: NSLocalizedString_("label_DeviceAddress", comment: ""), stringValue: Globals.shared.deviceWifiAddress, placeholder: placeHolder)
            settingsArray.append(s)
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_WIFI_PORT, type: .TEXTFIELD, title: NSLocalizedString_("Device port", comment: ""), stringValue: Globals.shared.deviceWifiPort, placeholder: "35000")
            settingsArray.append(s)

        } else if Globals.shared.deviceConnection == .BLE {
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_BLE_NAME, type: .PICKER, title: NSLocalizedString_("Name", comment: ""), listTitles: [
                "Vgate iCar Pro",
                "LELink",
                "OBDII (experimental)",
            ], listValues: [
                AppSettings.DEVICE_BLE_NAME.VGATE.rawValue,
                AppSettings.DEVICE_BLE_NAME.LELINK.rawValue,
                AppSettings.DEVICE_BLE_NAME.OBDII.rawValue,
            ], intValue: Globals.shared.deviceBleName.rawValue)
            settingsArray.append(s)

        } else if Globals.shared.deviceConnection == .HTTP {
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS, type: .TEXTFIELD, title: NSLocalizedString_("http address", comment: ""), stringValue: Globals.shared.deviceHttpAddress)
            settingsArray.append(s)
        }

        s = Setting(tag: AppSettings.SETTINGS_DEVICE_DELAY, type: .SLIDER, title: NSLocalizedString_("Delay", comment: ""), doubleValue: Globals.shared.deviceDelay, placeholder: nil)
        settingsArray.append(s)

        if Globals.shared.car != AppSettings.CAR_X10PH2 {
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS, type: .SWITCH, title: NSLocalizedString_("label_AltFields", comment: ""), boolValue: Globals.shared.useIsoTpFields)
            settingsArray.append(s)
        }

        settingsDic["\(settingsDic.count)\(titleSeparator)\(titolo)"] = settingsArray

        // debug
        settingsArray = []
        titolo = NSLocalizedString_("Logs", comment: "")

        s = Setting(tag: AppSettings.SETTING_LOGGING_USE_SD_CARD, type: .SWITCH, title: NSLocalizedString_("Log to File App", comment: ""), boolValue: Globals.shared.useSdCard)
        settingsArray.append(s)

        s = Setting(tag: AppSettings.SETTING_LOGGING_WRITE_FOR_EMULATOR, type: .SWITCH, title: NSLocalizedString_("Log for emulator", comment: ""), boolValue: Globals.shared.writeForEmulator)
        settingsArray.append(s)

        settingsDic["\(settingsDic.count)\(titleSeparator)\(titolo)"] = settingsArray

        // app version
        settingsArray = []
        titolo = NSLocalizedString_("label_Info", comment: "")

        let version = "\(Bundle.main.infoDictionary!["CFBundleShortVersionString"] ?? "")(\(Bundle.main.infoDictionary!["CFBundleVersion"] ?? ""))"

        s = Setting(tag: nil, type: .TEXTFIELD_READONLY, title: NSLocalizedString_("version", comment: ""), stringValue: version)
        settingsArray.append(s)

        settingsDic["\(settingsDic.count)\(titleSeparator)\(titolo)"] = settingsArray
    }

    @IBAction func btnDongleTest() {
        //        if Globals.shared.deviceType != .ELM327 {
        //            return
        //        }

        if !Globals.shared.deviceIsConnected || !Globals.shared.deviceIsInitialized {
            view.hideAllToasts()
            view.makeToast(NSLocalizedString_("Please connect", comment: ""))
            return
        }
        view.hideAllToasts()
        view.makeToast(NSLocalizedString_("Starting test", comment: ""))

        NotificationCenter.default.addObserver(self, selector: #selector(endDongleTest), name: Notification.Name("endQueue2"), object: nil)

        Globals.shared.queue2 = []
        Globals.shared.lastId = 0
        if Utils.isPh2() {
            addField(Sid.EVC, intervalMs: 2000) // open EVC
        }
        addField(Sid.SoC, intervalMs: 5000)
        addField(Sid.BatterySerial, intervalMs: 5000)
        startQueue2()
    }

    @objc func endDongleTest() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("endQueue2"), object: nil)

        let sid1 = Sid.UserSoC
        let v1 = Globals.shared.fieldResultsDouble[sid1]
//        let f1 = Fields.getInstance.getBySID(sid1)

        let sid2 = Sid.BatterySerial
        let v2 = Globals.shared.fieldResultsString[sid2]
//        let f2 = Fields.getInstance.getBySID(sid2)

        if v1 != nil, v2 != nil {
//            view.hideAllToasts()
//            view.makeToast("\(f1!.name ?? "?") \(v1 ?? 0.0)\n\(f2!.name ?? "?") \(v2!)", duration: 5.0, position: ToastPosition.center, title: nil, image: nil, style: ToastStyle(), completion: nil)
//            view.makeToast("\(f1!.name ?? "?") \(v1 ?? 0.0)\n\(f2!.name ?? "?") \(v2!)")
            let msg = "User SoC \(String(format: "%.2f", v1!)) %\nSerial \(v2!)"
            let ac = UIAlertController(title: NSLocalizedString_("Test dongle", comment: ""), message: msg, preferredStyle: .alert)
            let ac1 = UIAlertAction(title: NSLocalizedString_("default_Ok", comment: ""), style: .default, handler: nil)
            ac.addAction(ac1)
            present(ac, animated: true, completion: nil)

        } else {
            let ac = UIAlertController(title: NSLocalizedString_("Test dongle", comment: ""), message: NSLocalizedString_("Test KO", comment: ""), preferredStyle: .alert)
            let ac1 = UIAlertAction(title: NSLocalizedString_("default_Ok", comment: ""), style: .default, handler: nil)
            ac.addAction(ac1)
            present(ac, animated: true, completion: nil)
        }
    }

    @IBAction func btnPickerDone_() {
        hidePicker()

        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[lastSelectedIndexPath.section]
        let arraySettings = settingsDic[myKey]
        let setting = arraySettings?[lastSelectedIndexPath.row]

        let value = Globals.shared.pickerValues![picker.selectedRow(inComponent: 0)]

        switch setting?.tag {
        case AppSettings.SETTINGS_CAR:
            Globals.shared.ud.setValue(value, forKey: AppSettings.SETTINGS_CAR)
            Globals.shared.ud.synchronize()

        case AppSettings.SETTINGS_DEVICE_TYPE:

            Globals.shared.deviceType = AppSettings.DEVICE_TYPE(rawValue: value as! Int) ?? .NONE

            Globals.shared.ud.setValue(Globals.shared.deviceType.rawValue, forKey: AppSettings.SETTINGS_DEVICE_TYPE)

            if Globals.shared.deviceType == .HTTP_GW { // http gw is only supported via http
                Globals.shared.ud.setValue(AppSettings.DEVICE_CONNECTION.HTTP.rawValue, forKey: AppSettings.SETTINGS_DEVICE_CONNECTION)
            } else if Globals.shared.deviceType == .ELM327, Globals.shared.deviceConnection == .WIFI {
                Globals.shared.ud.setValue(AppSettings.DEVICE_CONNECTION.WIFI.rawValue, forKey: AppSettings.SETTINGS_DEVICE_CONNECTION)
                Globals.shared.ud.setValue("192.168.0.10", forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
            } else if Globals.shared.deviceType == .CANSEE { // cansee is only supported with wifi
                Globals.shared.ud.setValue(AppSettings.DEVICE_CONNECTION.WIFI.rawValue, forKey: AppSettings.SETTINGS_DEVICE_CONNECTION)
                Globals.shared.ud.setValue("192.168.4.1", forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
            }
            Globals.shared.ud.synchronize()

        case AppSettings.SETTINGS_DEVICE_CONNECTION:

            Globals.shared.deviceConnection = AppSettings.DEVICE_CONNECTION(rawValue: value as! Int) ?? .NONE

            Globals.shared.ud.setValue(Globals.shared.deviceConnection.rawValue, forKey: AppSettings.SETTINGS_DEVICE_CONNECTION)

            if Globals.shared.deviceType == .ELM327, Globals.shared.deviceConnection == .WIFI {
                Globals.shared.ud.setValue("192.168.0.10", forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
            } else if Globals.shared.deviceType == .CANSEE { // cansee is only supported with wifi
                Globals.shared.ud.setValue("192.168.4.1", forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
            }

            Globals.shared.ud.synchronize()

            disconnect(showToast: false)

        case AppSettings.SETTINGS_DEVICE_BLE_NAME:

            Globals.shared.deviceBleName = AppSettings.DEVICE_BLE_NAME(rawValue: value as! Int) ?? .NONE

            Globals.shared.ud.setValue(Globals.shared.deviceBleName.rawValue, forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME)

            if Globals.shared.deviceBleName == .VGATE {
//                Globals.shared.ud.setValue("D63109B1-C246-911F-F180-CAE0377D718D", forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID)
                Globals.shared.ud.setValue("IOS-Vlink", forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_NAME)
                Globals.shared.ud.setValue("C77D5F27-9FF8-837E-B370-1A4FAF0DAEDB", forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID)
                Globals.shared.ud.setValue("E7810A71-73AE-499D-8C15-FAA9AEF0C3F2", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                Globals.shared.ud.setValue("BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                Globals.shared.ud.setValue("BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
            } else if Globals.shared.deviceBleName == .LELINK {
                Globals.shared.ud.setValue("OBDBLE", forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_NAME)
                Globals.shared.ud.setValue("7A4984CB-7607-37D8-337E-7CA5AC17C9B0", forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID)
                Globals.shared.ud.setValue("FFE0", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                Globals.shared.ud.setValue("FFE1", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                Globals.shared.ud.setValue("FFE1", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
            } else if Globals.shared.deviceBleName == .OBDII {
                Globals.shared.ud.setValue("OBDII", forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_NAME)
                Globals.shared.ud.setValue("6464A14D-1E38-8FF0-1ED1-FB4ABFB024F7", forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID)
                Globals.shared.ud.setValue("FFF0", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                Globals.shared.ud.setValue("FFF2", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                Globals.shared.ud.setValue("FFF1", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
            } else {
                print("unknown ble device")
            }

            Globals.shared.ud.synchronize()

        default:
            print("setting?.tag unknown")
        }

        disconnect(showToast: false)
        Globals.shared.deviceIsConnected = false
        Globals.shared.deviceIsInitialized = false
        NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)

        loadSettings()
        organizeSettings()
        settingsTableView.reloadData()
    }

    @IBAction func btnPickerCancel_() {
        Globals.shared.pickerPhase = .PERIPHERAL
        hidePicker()

        loadSettings()
        organizeSettings()
        settingsTableView.reloadData()
    }

    @IBAction func btnTextFieldDone_() {
        textField.resignFirstResponder()
        // print("done")
        textFieldView.alpha = 0.0
        let vBG = view.viewWithTag(Globals.K_TAG_vBG)
        vBG?.removeFromSuperview()

        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[lastSelectedIndexPath.section]
        let arraySettings = settingsDic[myKey]
        let setting = arraySettings?[lastSelectedIndexPath.row]

        let value = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        Globals.shared.ud.setValue(value, forKey: setting!.tag!)
        Globals.shared.ud.synchronize()

        /*
         switch setting?.tag {
         case AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS:
             Globals.shared.ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
             Globals.shared.ud.synchronize()
         case AppSettings.SETTINGS_DEVICE_WIFI_PORT:
             Globals.shared.ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT)
             Globals.shared.ud.synchronize()
         case AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS:
             Globals.shared.ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS)
             Globals.shared.ud.synchronize()
         default:
             break
         }
         */

        textField.text = ""

        disconnect(showToast: false)
        Globals.shared.deviceIsConnected = false
        Globals.shared.deviceIsInitialized = false
        NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)

        loadSettings()
        organizeSettings()
        settingsTableView.reloadData()
    }

    @IBAction func btnTextFieldCancel_() {
        textField.resignFirstResponder()
        // print("cancel")
        textFieldView.alpha = 0.0
        textField.text = ""
        let vBG = view.viewWithTag(Globals.K_TAG_vBG)
        vBG?.removeFromSuperview()
    }

    @IBAction func btnSliderDone_() {
        let vBG = view.viewWithTag(Globals.K_TAG_vBG)
        vBG?.removeFromSuperview()

        /*
         let sortedKeys = Array(settingsDic.keys).sorted(by: <)
                let myKey = sortedKeys[lastSelectedIndexPath.section]
                let arraySettings = settingsDic[myKey]
                let setting = arraySettings?[lastSelectedIndexPath.row]

                let value = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)

                Globals.shared.ud.setValue(value, forKey: setting!.tag!)
                Globals.shared.ud.synchronize()

                /*
                 switch setting?.tag {
                 case AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS:
                     Globals.shared.ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
                     Globals.shared.ud.synchronize()
                 case AppSettings.SETTINGS_DEVICE_WIFI_PORT:
                     Globals.shared.ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT)
                     Globals.shared.ud.synchronize()
                 case AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS:
                     Globals.shared.ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS)
                     Globals.shared.ud.synchronize()
                 default:
                     break
                 }
                 */

                textField.text = ""
                disconnect(showToast: false)
                Globals.shared.deviceIsConnected = false
                Globals.shared.deviceIsInitialized = false
                NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)
         */

        loadSettings()
        organizeSettings()
        settingsTableView.reloadData()
    }

    @IBAction func btnSliderCancel_() {
        let vBG = view.viewWithTag(Globals.K_TAG_vBG)
        vBG?.removeFromSuperview()
    }
}

// MARK: UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsDic.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let mySection = sortedKeys[section]
        let myArray = settingsDic[mySection]
        return myArray!.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[section]
        let titleArray = myKey.components(separatedBy: titleSeparator)
        return titleArray.last
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[indexPath.section]
        let arraySettings = settingsDic[myKey]
        let setting = arraySettings?[indexPath.row]

        switch setting?.type {
        case .SWITCH:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellSwitch")! as! SettingsSwitchTableViewCell
            if setting?.subTitle != nil {
                cell.titleLabel.text = "\(setting?.title ?? "")\n\(setting?.subTitle ?? "")"
            } else {
                cell.titleLabel.text = setting?.title
            }
            cell.sw.isOn = setting!.boolValue
            return cell
        case .TEXTFIELD, .TEXTFIELD_READONLY:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! SettingsTableViewCell
            cell.titleLabel.text = setting?.title
            if setting?.stringValue != "" {
                cell.valueLabel.text = setting?.stringValue
                cell.valueLabel.textColor = .black
                cell.contentView.backgroundColor = .clear
                if cell.timerWarning.isValid {
                    cell.timerWarning.invalidate()
                }
            } else {
                cell.valueLabel.text = "?"
                if cell.timerWarning.isValid {
                    cell.timerWarning.invalidate()
                }
                cell.warning()
            }
            return cell
        case .PICKER:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! SettingsTableViewCell
            cell.valueLabel.text = "?"
            if cell.timerWarning.isValid {
                cell.timerWarning.invalidate()
            }
            cell.warning()

            if setting?.intValue != -1 {
                var indice = 0
                while indice < (setting?.listValues!.count)! {
                    let z = (setting?.listValues![indice])! as? Int
                    if z == (setting?.intValue)! {
                        cell.valueLabel.text = setting?.listTitles![indice] ?? ""
                        cell.valueLabel.textColor = .black
                        cell.contentView.backgroundColor = .clear
                        if cell.timerWarning.isValid {
                            cell.timerWarning.invalidate()
                        }
                        break
                    }
                    indice += 1
                }
            } else if setting?.stringValue != nil {
                var indice = 0
                while indice < (setting?.listValues!.count)! {
                    let z = (setting?.listValues![indice])! as! String
                    if z == (setting?.stringValue)! {
                        cell.valueLabel.text = setting?.listTitles![indice] ?? ""
                        cell.valueLabel.textColor = .black
                        cell.contentView.backgroundColor = .clear
                        if cell.timerWarning.isValid {
                            cell.timerWarning.invalidate()
                        }
                        break
                    }
                    indice += 1
                }
            }
            cell.titleLabel?.text = setting?.title
            return cell
        case .SLIDER:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cellSlider")! as! SettingsSliderTableViewCell
            cell.titleLabel.text = setting?.title
            cell.valueLabel.text = String(format: "%.2f", (setting?.doubleValue!)! as Double)
            cell.valueLabel.textColor = .black
            cell.valueLabel.tag = indexPath.section * 2000 + indexPath.row
            cell.contentView.backgroundColor = .clear
            cell.slider.value = Float((setting?.doubleValue)!)
            cell.slider.minimumValue = 0.01
            cell.slider.maximumValue = 1.0
            cell.slider.isContinuous = true
            let slider = cell.slider as! SliderWithParameters
            slider.params = ["indexPath": indexPath]
            slider.addTarget(self, action: #selector(sliderValueChanged(slider:)), for: .valueChanged)
            return cell
        case .none:
            break
        case .NONE:
            break
        }
        return UITableViewCell()
    }

    @objc func sliderValueChanged(slider: SliderWithParameters) {
        let i = slider.params["indexPath"] as! IndexPath
        let label = settingsTableView.viewWithTag(i.section * 2000 + i.row) as! UILabel
        label.text = String(format: "%.2f", slider.value)

        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[i.section]
        let arraySettings = settingsDic[myKey]
        let setting = arraySettings?[i.row]

        switch setting?.tag {
        case AppSettings.SETTINGS_DEVICE_DELAY:
            Globals.shared.ud.set(slider.value, forKey: AppSettings.SETTINGS_DEVICE_DELAY)
            Globals.shared.ud.synchronize()
            break
        default:
            break
        }
    }
}

// MARK: UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        lastSelectedIndexPath = indexPath
        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[indexPath.section]
        let arraySettings = settingsDic[myKey]
        var setting = (arraySettings?[indexPath.row])! as Setting

        switch setting.type {
        case .PICKER:

            disconnect(showToast: false)
            Globals.shared.deviceIsConnected = false
            Globals.shared.deviceIsInitialized = false
            NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)

            Globals.shared.pickerTitles = setting.listTitles
            Globals.shared.pickerValues = setting.listValues
            picker.selectRow(0, inComponent: 0, animated: false)
            showPicker()

            // preselect previous value if available
            if setting.intValue != -1 {
                var indice = 0
                while indice < setting.listValues!.count {
                    let z = setting.listValues![indice] as? Int
                    if z == setting.intValue {
                        picker.selectRow(indice, inComponent: 0, animated: false)
                        break
                    }
                    indice += 1
                }
            } else if setting.stringValue != nil {
                var indice = 0
                while indice < setting.listValues!.count {
                    let z = setting.listValues![indice] as! String
                    if z == setting.stringValue {
                        picker.selectRow(indice, inComponent: 0, animated: false)
                        break
                    }
                    indice += 1
                }
            }

        case .TEXTFIELD:
            disconnect(showToast: false)
            Globals.shared.deviceIsConnected = false
            Globals.shared.deviceIsInitialized = false
            NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)

            let vBG = UIView(frame: view.frame)
            vBG.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            vBG.tag = Globals.K_TAG_vBG
            view.insertSubview(vBG, belowSubview: textFieldView)

            textFieldView.center = view.center
            textFieldView.alpha = 1.0
            textField.text = setting.stringValue
            textField.placeholder = setting.placeholder
            // btnTextFieldDone.backgroundColor = .lightGray
            // btnTextFieldCancel.backgroundColor = .lightGray

        case .SWITCH:

            if setting.boolValue {
                setting.boolValue = false
            } else {
                setting.boolValue = true
            }
//            arraySettings![indexPath.row] = setting
//            settingsDic[myKey] = arraySettings
            Globals.shared.ud.setValue(setting.boolValue, forKey: setting.tag!)
            Globals.shared.ud.synchronize()

            loadSettings()
            organizeSettings()
            tableView.reloadData()

        case .TEXTFIELD_READONLY:
            // non fare niente
            break
        case .SLIDER:
            // non fare niente
            break
        case .none:
            break
        case .NONE:
            break
        }
    }
}

// MARK: UIPickerViewDataSource

extension SettingsViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Globals.shared.pickerValues!.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Globals.shared.pickerTitles![row]
    }
}

// MARK: UIPickerViewDelegate

extension SettingsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // print("selected row \(row)")
    }
}
