//
//  SettingsViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import CoreBluetooth
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

    /*
         @IBAction func btnBleStandard(sender: UIBarButtonItem) {
             let ac = UIAlertController(title: "_supported ble devices", message: "_select yours", preferredStyle: .actionSheet)

             let actionLelink = UIAlertAction(title: "LELink", style: .default) { _ in
                 self.ud.setValue("LELink", forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME)
                 self.ud.setValue("7A4984CB-7607-37D8-337E-7CA5AC17C9B0", forKey: AppSettings.SETTINGS_DEVICE_BLE_IDENTIFIER_UUID)
                 self.ud.setValue("FFE0", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                 self.ud.setValue("FFE1", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                 self.ud.setValue("FFE1", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
                 self.ud.synchronize()
                 self.loadSettings()
                 self.organizeSettings()
                 self.settingsTableView.reloadData()

     //            self.startAutoInit()
             }

             let actionVgate = UIAlertAction(title: "Vgate iCar Pro", style: .default) { _ in
                 self.ud.setValue("Vgate iCar Pro", forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME)
                 self.ud.setValue("D63109B1-C246-911F-F180-CAE0377D718D", forKey: AppSettings.SETTINGS_DEVICE_BLE_IDENTIFIER_UUID)
                 self.ud.setValue("E7810A71-73AE-499D-8C15-FAA9AEF0C3F2", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                 self.ud.setValue("BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                 self.ud.setValue("BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
                 self.ud.synchronize()
                 self.loadSettings()
                 self.organizeSettings()
                 self.settingsTableView.reloadData()

     //            self.startAutoInit()
             }

             /*
              let a3 = UIAlertAction(title: "Kimood", style: .default) { _ in
                  self.ud.setValue("OBDII", forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME)
                  self.ud.setValue("9F8DFDE2-FBE9-F71C-B744-E774EB120742", forKey: AppSettings.SETTINGS_DEVICE_BLE_IDENTIFIER_UUID)
                  self.ud.setValue("FFF0", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                  self.ud.setValue("FFF2", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                  self.ud.setValue("FFF1", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
                  self.ud.synchronize()
                  self.loadSettings()
                  self.organizeSettings()
                  self.settingsTableView.reloadData()
              }
              */

     //        let actionCancel = UIAlertAction(title: "cancel", style: .cancel) { _ in
     //        }

             ac.addAction(actionLelink)
             ac.addAction(actionVgate)
             // ac.addAction(a3)
     //        ac.addAction(actionCancel)

             if UIDevice.isPad {
                 // This will turn the Action Sheet into a popover
                 ac.modalPresentationStyle = .automatic
                 ac.isModalInPresentation = true
                 let popPresenter = ac.popoverPresentationController
                 popPresenter!.sourceView = settingsTableView.superview
                 popPresenter!.sourceRect = CGRect(x: 0, y: 0, width: settingsTableView.frame.width, height: settingsTableView.frame.height * 0.5)
             }

             present(ac, animated: true, completion: nil)
         }
          */

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_settings", comment: "")

//        NotificationCenter.default.addObserver(self, selector: #selector(ricevuto(notification:)), name: Notification.Name("ricevuto"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(ricevuto2(notification:)), name: Notification.Name("ricevuto2"), object: nil)

        pickerView.alpha = 0.0
        textFieldView.alpha = 0.0

        settingsTableView.delegate = self
        settingsTableView.dataSource = self

        setupPicker()

        loadSettings()
        organizeSettings()

        settingsTableView.reloadData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadPicker(notification:)), name: Notification.Name("reloadPicker"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("reloadPicker"), object: nil)
    }

    // ricezione dati wifi
    @objc func reloadPicker(notification: Notification) {
        picker.reloadAllComponents()
    }

    func setupPicker() {
        pickerView.center = view.center
        pickerView.alpha = 0.0
        picker.delegate = self
        btnPickerDone.backgroundColor = UIColor.red.withAlphaComponent(0.5)
        btnPickerCancel.backgroundColor = UIColor.orange.withAlphaComponent(0.5)
    }

    func showPicker() {
        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        vBG.tag = vBG_TAG
        view.insertSubview(vBG, belowSubview: pickerView)

        pickerView.alpha = 1.0
        picker.reloadAllComponents()
    }

    func hidePicker() {
        pickerView.alpha = 0.0
        let vBG = view.viewWithTag(vBG_TAG)
        vBG?.removeFromSuperview()
    }

    func organizeSettings() {
        settingsDic = [:]

        // car
        var settingsArray: [Setting] = []
        var titolo = NSLocalizedString("label_Car", comment: "")

        var s = Setting(tag: AppSettings.SETTINGS_CAR, type: .PICKER, title: NSLocalizedString("label_CarModel", comment: ""), listTitles: [
            "ZOE Q210",
            "ZOE R240",
            "ZOE Q90",
            "ZOE R90",
            "ZOE ZE50",
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
        ], intValue: AppSettings.shared.car)
        settingsArray.append(s)

        s = Setting(tag: AppSettings.SETTINGS_CAR_USE_MILES, type: .SWITCH, title: NSLocalizedString("label_DistanceUnit", comment: ""), subTitle: AppSettings.shared.milesMode ? NSLocalizedString("label_Miles", comment: "") : NSLocalizedString("label_Kilometers", comment: ""), boolValue: AppSettings.shared.milesMode)
        settingsArray.append(s)

        settingsDic["\(settingsDic.count)\(titleSeparator)\(titolo)"] = settingsArray

        // device
        settingsArray = []
        titolo = NSLocalizedString("label_Settings_Device", comment: "")

        s = Setting(tag: AppSettings.SETTINGS_DEVICE_TYPE, type: .PICKER, title: NSLocalizedString("label_DeviceType", comment: ""), listTitles: [
            "ELM327",
            "CanSee",
            "Http Gateway",
        ], listValues: [
            AppSettings.DEVICE_TYPE.ELM327.rawValue,
            AppSettings.DEVICE_TYPE.CANSEE.rawValue,
            AppSettings.DEVICE_TYPE.HTTP.rawValue,
        ], intValue: AppSettings.shared.deviceType.rawValue)
        settingsArray.append(s)

        s = Setting(tag: AppSettings.SETTINGS_DEVICE_CONNECTION, type: .PICKER, title: "_connection", listTitles: [
            "_BLE",
            "_WiFi",
            "_HTTP",
        ], listValues: [
            AppSettings.DEVICE_CONNECTION.BLE.rawValue,
            AppSettings.DEVICE_CONNECTION.WIFI.rawValue,
            AppSettings.DEVICE_CONNECTION.HTTP.rawValue,
        ], intValue: AppSettings.shared.deviceConnection.rawValue)
        settingsArray.append(s)

        if AppSettings.shared.deviceConnection == .WIFI {
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS, type: .TEXTFIELD, title: NSLocalizedString("label_DeviceAddress", comment: ""), stringValue: AppSettings.shared.deviceWifiAddress, placeholder: "192.168.0.10")
            settingsArray.append(s)
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_WIFI_PORT, type: .TEXTFIELD, title: "_device port:", stringValue: AppSettings.shared.deviceWifiPort, placeholder: "35000")
            settingsArray.append(s)

        } else if AppSettings.shared.deviceConnection == .BLE {
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_BLE_NAME, type: .PICKER, title: "_name", listTitles: [
                "Vgate iCar Pro",
                "LELink",
            ], listValues: [
                AppSettings.DEVICE_BLE_NAME.VGATE.rawValue,
                AppSettings.DEVICE_BLE_NAME.LELINK.rawValue,
            ], intValue: AppSettings.shared.deviceBleName.rawValue)
            settingsArray.append(s)

        } else if AppSettings.shared.deviceConnection == .HTTP {
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS, type: .TEXTFIELD, title: "_http address", stringValue: AppSettings.shared.deviceHttpAddress)
            settingsArray.append(s)
        }

        if AppSettings.shared.car != AppSettings.CAR_X10PH2 {
            s = Setting(tag: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS, type: .SWITCH, title: NSLocalizedString("label_AltFields", comment: ""), boolValue: AppSettings.shared.useIsoTpFields)
            settingsArray.append(s)
        }

        settingsDic["\(settingsDic.count)\(titleSeparator)\(titolo)"] = settingsArray
    }

    @IBAction func btnOBDTest() {
        if AppSettings.shared.deviceType == .ELM327, !AppSettings.shared.deviceIsConnected {
            view.hideAllToasts()
            view.makeToast("_please connect")
            return
        }
        view.hideAllToasts()
        view.makeToast("starting test")

        NotificationCenter.default.addObserver(self, selector: #selector(fineOBDTest), name: Notification.Name("fineCoda2"), object: nil)

        coda2 = []
        if Utils.isPh2() {
            addField(sid: "7ec.5003.0", intervalMs: 2000) // open EVC
        }
        addField(sid: Sid.SoC, intervalMs: 5000)
        addField(sid: Sid.BatterySerial, intervalMs: 5000)
        iniziaCoda2()
    }

    @objc func fineOBDTest() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("fineCoda2"), object: nil)

        let sid1 = Sid.SoC
        let v1 = fieldResultsDouble[sid1]
        let f1 = Fields.getInstance.getBySID(sid: sid1)

        let sid2 = Sid.BatterySerial
        let v2 = fieldResultsString[sid2]
        let f2 = Fields.getInstance.getBySID(sid: sid2)

        if f1 != nil, v1 != nil, f2 != nil, v2 != nil {
            view.hideAllToasts()
            view.makeToast("\(f1!.name ?? "?") \(v1 ?? 0.0)\n\(f2!.name ?? "?") \(v2!)", duration: 5.0, position: ToastPosition.center, title: nil, image: nil, style: ToastStyle(), completion: nil)
//            view.makeToast("\(f1!.name ?? "?") \(v1 ?? 0.0)\n\(f2!.name ?? "?") \(v2!)")
        } else {
            view.hideAllToasts()
            view.makeToast("test ko :-(")
        }
    }

    @IBAction func btnPickerDone_() {
        hidePicker()

        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[lastSelectedIndexPath.section]
        let arraySettings = settingsDic[myKey]
        let setting = arraySettings?[lastSelectedIndexPath.row]

        let value = pickerValues![picker.selectedRow(inComponent: 0)]

        switch setting?.tag {
        case AppSettings.SETTINGS_CAR:
            ud.setValue(value, forKey: AppSettings.SETTINGS_CAR)
            ud.synchronize()
        case AppSettings.SETTINGS_DEVICE_CONNECTION:

            AppSettings.shared.deviceConnection = AppSettings.DEVICE_CONNECTION(rawValue: value as! Int) ?? .NONE

            ud.setValue(AppSettings.shared.deviceConnection.rawValue, forKey: AppSettings.SETTINGS_DEVICE_CONNECTION)
            ud.synchronize()

            disconnect(showToast: false)

        case AppSettings.SETTINGS_DEVICE_TYPE:

            AppSettings.shared.deviceType = AppSettings.DEVICE_TYPE(rawValue: value as! Int) ?? .NONE

            ud.setValue(AppSettings.shared.deviceType.rawValue, forKey: AppSettings.SETTINGS_DEVICE_TYPE)

            if AppSettings.shared.deviceType == .HTTP { // http gw is only supported via http
                ud.setValue(AppSettings.DEVICE_CONNECTION.HTTP.rawValue, forKey: AppSettings.SETTINGS_DEVICE_CONNECTION)
            }
            if AppSettings.shared.deviceType == .CANSEE { // cansee is only supported with wifi
                ud.setValue(AppSettings.DEVICE_CONNECTION.WIFI.rawValue, forKey: AppSettings.SETTINGS_DEVICE_CONNECTION)
            }
            ud.synchronize()

        case AppSettings.SETTINGS_DEVICE_BLE_NAME:

            AppSettings.shared.deviceBleName = AppSettings.DEVICE_BLE_NAME(rawValue: value as! Int) ?? .NONE

            ud.setValue(AppSettings.shared.deviceBleName.rawValue, forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME)

            if AppSettings.shared.deviceBleName == .VGATE {
                ud.setValue("D63109B1-C246-911F-F180-CAE0377D718D", forKey: AppSettings.SETTINGS_DEVICE_BLE_IDENTIFIER_UUID)
                ud.setValue("E7810A71-73AE-499D-8C15-FAA9AEF0C3F2", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                ud.setValue("BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                ud.setValue("BEF8D6C9-9C21-4C9E-B632-BD58C1009F9F", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
            } else if AppSettings.shared.deviceBleName == .LELINK {
                ud.setValue("7A4984CB-7607-37D8-337E-7CA5AC17C9B0", forKey: AppSettings.SETTINGS_DEVICE_BLE_IDENTIFIER_UUID)
                ud.setValue("FFE0", forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
                ud.setValue("FFE1", forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
                ud.setValue("FFE1", forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
            } else {
                print("unknown ble device")
            }

            ud.synchronize()

        default:
            print("?")
        }

        disconnect(showToast: false)
        AppSettings.shared.deviceIsConnected = false
        AppSettings.shared.deviceIsInitialized = false
        NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)

        loadSettings()
        organizeSettings()
        settingsTableView.reloadData()
    }

    @IBAction func btnPickerCancel_() {
        pickerPhase = .PERIPHERAL
        hidePicker()

        loadSettings()
        organizeSettings()
        settingsTableView.reloadData()
    }

    @IBAction func btnTextFieldDone_() {
        textField.resignFirstResponder()
        // print("done")
        textFieldView.alpha = 0.0
        let vBG = view.viewWithTag(vBG_TAG)
        vBG?.removeFromSuperview()

        let sortedKeys = Array(settingsDic.keys).sorted(by: <)
        let myKey = sortedKeys[lastSelectedIndexPath.section]
        let arraySettings = settingsDic[myKey]
        let setting = arraySettings?[lastSelectedIndexPath.row]

        let value = textField.text

        ud.setValue(value, forKey: setting!.tag)
        ud.synchronize()

        /*
         switch setting?.tag {
         case AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS:
             ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
             ud.synchronize()
         case AppSettings.SETTINGS_DEVICE_WIFI_PORT:
             ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT)
             ud.synchronize()
         case AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS:
             ud.setValue(value, forKey: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS)
             ud.synchronize()
         default:
             break
         }
         */

        textField.text = ""

        disconnect(showToast: false)
        AppSettings.shared.deviceIsConnected = false
        AppSettings.shared.deviceIsInitialized = false
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
        let vBG = view.viewWithTag(vBG_TAG)
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
            } else {
                cell.valueLabel.text = "?"
                cell.valueLabel.textColor = .red
            }
            return cell
        case .PICKER:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as! SettingsTableViewCell
            cell.valueLabel.text = "?"
            cell.valueLabel.textColor = .red
            if setting?.intValue != -1 {
                var indice = 0
                while indice < (setting?.listValues!.count)! {
                    let z = (setting?.listValues![indice])! as? Int
                    if z == (setting?.intValue)! {
                        cell.valueLabel.text = setting?.listTitles![indice] ?? ""
                        cell.valueLabel.textColor = .black
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
                        break
                    }
                    indice += 1
                }
            }
            cell.titleLabel?.text = setting?.title
            return cell
        case .none:
            break
        case .NONE:
            break
        }
        return UITableViewCell()
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

            pickerTitles = setting.listTitles
            pickerValues = setting.listValues
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

            disconnect(showToast: false)
            AppSettings.shared.deviceIsConnected = false
            AppSettings.shared.deviceIsInitialized = false
            NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)

        case .TEXTFIELD:
            let vBG = UIView(frame: view.frame)
            vBG.backgroundColor = UIColor.black.withAlphaComponent(0.75)
            vBG.tag = vBG_TAG
            view.insertSubview(vBG, belowSubview: textFieldView)
            textFieldView.center = view.center
            textFieldView.alpha = 1.0
            textField.text = setting.stringValue
            textField.placeholder = setting.placeholder
            btnTextFieldDone.backgroundColor = UIColor.red.withAlphaComponent(0.5)
            btnTextFieldCancel.backgroundColor = UIColor.orange.withAlphaComponent(0.5)

            disconnect(showToast: false)
            AppSettings.shared.deviceIsConnected = false
            AppSettings.shared.deviceIsInitialized = false
            NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)

        case .SWITCH:

            if setting.boolValue {
                setting.boolValue = false
            } else {
                setting.boolValue = true
            }
//            arraySettings![indexPath.row] = setting
//            settingsDic[myKey] = arraySettings
            ud.setValue(setting.boolValue, forKey: setting.tag)
            ud.synchronize()
            loadSettings()
            organizeSettings()
            tableView.reloadData()

        case .TEXTFIELD_READONLY:
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
        return pickerValues!.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerTitles![row]
    }
}

// MARK: UIPickerViewDelegate

extension SettingsViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // print("selected row \(row)")
    }
}
