//
//  CanZeViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import CoreBluetooth
import UIKit

class CanZeViewController: UIViewController {
    let ud = UserDefaults.standard

    let vBG_TAG = 99999

    // WIFI
    var inputStream: InputStream!
    var outputStream: OutputStream!
    let maxReadLength = 4096
    var timeoutTimerWifi: Timer!

    // BLE
    var centralManager: CBCentralManager!
    var peripheralsDic: [String: BlePeripheral]!
//    var peripheralsArray: [BlePeripheral]!
    var selectedPeripheral: BlePeripheral!
    var servicesArray: [CBService]!
    var selectedService: CBService!
    var characteristicArray: [CBCharacteristic]!
    var selectedWriteCharacteristic: CBCharacteristic!
    var selectedReadCharacteristic: CBCharacteristic!
    var timeoutTimerBle: Timer!

    // init elm327
    let autoInitElm327: [String] = ["ate0", "ats0", "ath0", "atl0", "atal", "atcaf0", "atfcsh77b", "atfcsd300000", "atfcsm1", "atsp6"]

    // coda
    var coda: [String] = []
    var lastRxString = ""
    var lastId = -1

    var timeoutTimer: Timer!

    // coda2
    var coda2: [Sequenza] = []
    var indiceCmd = 0

    var codaInit: [String] = []

    // setup ble device
    var pickerTitles: [String]? = []
    var pickerValues: [Any]? = []

    enum PickerPhase: String {
        case PERIPHERAL
        case SERVICES
        case WRITE_CHARACTERISTIC
        case READ_CHARACTERISTIC
    }

    var pickerPhase: PickerPhase = .PERIPHERAL

    enum BlePhase: String {
        case DISCOVER
        case DISCOVERED
    }

    var blePhase: BlePhase = .DISCOVERED

    var fieldResultsDouble: [String: Double] = [:]
    var fieldResultsString: [String: String] = [:]

//    var alertController: UIAlertController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        peripheralsDic = [:]
        // peripheralsArray = []
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if AppSettings.shared.deviceIsConnected {
            deviceConnected()
        } else {
            deviceDisconnected()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        // wifi
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFromWifiDongle(notification:)), name: Notification.Name("didReceiveFromWifiDongle"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(deviceConnected), name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDisconnected), name: Notification.Name("deviceDisconnected"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ricevuto(notification:)), name: Notification.Name("ricevuto"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(ricevuto2(notification:)), name: Notification.Name("ricevuto2"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coda2 = []
    }

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("didReceiveFromWifiDongle"), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceDisconnected"), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name("ricevuto"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ricevuto2"), object: nil)
    }

    @objc func deviceConnected() {
        if navigationItem.rightBarButtonItems != nil {
            for b in navigationItem.rightBarButtonItems! {
                if b.title == "deviceConnect" {
                    b.image = UIImage(named: "device_connected")
                    break
                }
            }
        }
    }

    @objc func deviceDisconnected() {
        if navigationItem.rightBarButtonItems != nil {
            for b in navigationItem.rightBarButtonItems! {
                if b.title == "deviceConnect" {
                    b.image = UIImage(named: "device_disconnected")
                    break
                }
            }
        }
    }

    func debug(s: String) {
        print(s)
    }

    @IBAction func btnConnect() {
        if AppSettings.shared.deviceIsConnected {
            disconnect(showToast: true)
            deviceDisconnected()
        } else {
//            connect()
            startAutoInit()
        }
    }

    func startAutoInit() {
        disconnect(showToast: false)
        // view.makeToast("_auto init")
        NotificationCenter.default.addObserver(self, selector: #selector(connected), name: Notification.Name("connected"), object: nil)
        connect()
    }

    @objc func connected() {
        AppSettings.shared.deviceIsConnected = true
        NotificationCenter.default.post(name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("connected"), object: nil)
        if AppSettings.shared.deviceType == .ELM327 {
            NotificationCenter.default.addObserver(self, selector: #selector(autoInit), name: Notification.Name("autoInit"), object: nil)
            initDeviceELM327()
        } else {
            view.hideAllToasts()
            view.makeToast("connected")
        }
    }

    func initDeviceELM327() {
        codaInit = []
        for s in autoInitElm327 {
            codaInit.append(s)
        }
        processaCodaInit()
    }

    @objc func autoInit() {
        AppSettings.shared.deviceIsInitialized = true
        NotificationCenter.default.removeObserver(self, name: Notification.Name("autoInit"), object: nil)
        view.makeToast("connected and initialized")
    }

    func deviceIsConnectable() -> Bool {
        var connectable = false
        if AppSettings.shared.deviceType == .ELM327 || AppSettings.shared.deviceType == .CANSEE || AppSettings.shared.deviceType == .HTTP {
            if AppSettings.shared.deviceConnection == .BLE, AppSettings.shared.deviceBlePeripheralIdentifierUuid != "", AppSettings.shared.deviceBleServiceUuid != "", AppSettings.shared.deviceBleReadCharacteristicUuid != "", AppSettings.shared.deviceBleWriteCharacteristicUuid != "" {
                connectable = true
            } else if AppSettings.shared.deviceConnection == .WIFI, AppSettings.shared.deviceWifiAddress != "", AppSettings.shared.deviceWifiPort != "" {
                connectable = true
            } else if AppSettings.shared.deviceConnection == .HTTP, AppSettings.shared.deviceHttpAddress != "" {
                connectable = true
            }
        }
        return connectable
    }

    func loadSettings() {
        AppSettings.shared.car = AppSettings.CAR_NONE
        AppSettings.shared.car = ud.integer(forKey: AppSettings.SETTINGS_CAR)
        switch AppSettings.shared.car {
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

        AppSettings.shared.deviceConnection = AppSettings.DEVICE_CONNECTION(rawValue: ud.value(forKey: AppSettings.SETTINGS_DEVICE_CONNECTION) as? Int ?? 0) ?? .NONE

        AppSettings.shared.deviceWifiAddress = ud.string(forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS) ?? "192.168.0.10"
        AppSettings.shared.deviceWifiPort = ud.string(forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT) ?? "35000"
        ud.setValue(AppSettings.shared.deviceWifiAddress, forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
        ud.setValue(AppSettings.shared.deviceWifiPort, forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT)
        ud.synchronize()

        AppSettings.shared.deviceBleName = AppSettings.DEVICE_BLE_NAME(rawValue: ud.value(forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME) as? Int ?? 0) ?? .NONE
        AppSettings.shared.deviceBlePeripheralIdentifierUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_IDENTIFIER_UUID) ?? ""
        AppSettings.shared.deviceBleServiceUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID) ?? ""
        AppSettings.shared.deviceBleReadCharacteristicUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID) ?? ""
        AppSettings.shared.deviceBleWriteCharacteristicUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID) ?? ""
        AppSettings.shared.deviceHttpAddress = ud.string(forKey: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS) ?? ""

        switch AppSettings.shared.deviceConnection {
        case .WIFI:
            print("DEVICE_CONNECTION_WIFI")
            print(AppSettings.shared.deviceWifiAddress)
            print(AppSettings.shared.deviceWifiPort)
        case .BLE:
            print("DEVICE_CONNECTION_BLE")

            switch AppSettings.shared.deviceBleName {
            case .VGATE:
                print("VGATE")
            case .LELINK:
                print("LELINK")
            default:
                print("unknown")
            }
            print(AppSettings.shared.deviceBlePeripheralIdentifierUuid)
            print(AppSettings.shared.deviceBleServiceUuid)
            print(AppSettings.shared.deviceBleReadCharacteristicUuid)
            print(AppSettings.shared.deviceBleWriteCharacteristicUuid)
        case .HTTP:
            print("DEVICE_CONNECTION_HTTP")
            print(AppSettings.shared.deviceHttpAddress)
        default:
            print("unknown")
        }

        AppSettings.shared.deviceType = AppSettings.DEVICE_TYPE(rawValue: ud.value(forKey: AppSettings.SETTINGS_DEVICE_TYPE) as? Int ?? 0) ?? .NONE
        switch AppSettings.shared.deviceType {
        case .ELM327:
            print("DEVICE_TYPE_ELM327")
        case .CANSEE:
            print("DEVICE_TYPE_CANSEE")
        case .HTTP:
            print("DEVICE_TYPE_HTTP")
        default:
            print("unknown")
        }

        /*
         AppSettings.shareds.safeDrivingMode = true
                 if ud.exists(key: AppSettings.SETTING_SECURITY_SAFE_MODE) {
         AppSettings.shared.safeDrivingMode = ud.bool(forKey: AppSettings.SETTING_SECURITY_SAFE_MODE)
                 }

         AppSettings.shared.bluetoothBackgroundMode = false
                 if ud.exists(key: AppSettings.SETTING_DEVICE_USE_BACKGROUND_MODE) {
         AppSettings.shared.bluetoothBackgroundMode = ud.bool(forKey: AppSettings.SETTING_DEVICE_USE_BACKGROUND_MODE)
                 }

         */

        AppSettings.shared.milesMode = false
        if ud.exists(key: AppSettings.SETTINGS_CAR_USE_MILES) {
            AppSettings.shared.milesMode = ud.bool(forKey: AppSettings.SETTINGS_CAR_USE_MILES)
        }
        print("SETTINGS_CAR_USE_MILES \(AppSettings.shared.milesMode)")

        AppSettings.shared.useIsoTpFields = true
        if ud.exists(key: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS) {
            AppSettings.shared.useIsoTpFields = ud.bool(forKey: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS)
        }
        if AppSettings.shared.car == AppSettings.CAR_X10PH2 { // Ph2 car has no IsoTp Fields
            AppSettings.shared.useIsoTpFields = false
        }
        print("SETTINGS_DEVICE_USE_ISOTP_FIELDS \(AppSettings.shared.useIsoTpFields)")

        /*
         AppSettings.shared.dataExportMode = false
                 if ud.exists(key: SETTING_LOGGING_USE_SD_CARD) {
         AppSettings.shared.dataExportMode = ud.bool(forKey: SETTING_LOGGING_USE_SD_CARD)
                 }

         AppSettings.shared.debugLogMode = false
                 if ud.exists(key: SETTING_LOGGING_DEBUG_LOG) {
         AppSettings.shared.debugLogMode = ud.bool(forKey: SETTING_LOGGING_DEBUG_LOG)
                 }

         AppSettings.shared.fieldLogMode = false
                 if ud.exists(key: SETTING_LOGGING_FIELDS_LOG) {
         AppSettings.shared.fieldLogMode = ud.bool(forKey: SETTING_LOGGING_FIELDS_LOG)
                 }

         AppSettings.shared.toastLevel = TOAST_ELM
                 if ud.exists(key: SETTING_DISPLAY_TOAST_LEVEL) {
         AppSettings.shared.toastLevel = ud.integer(forKey: SETTING_DISPLAY_TOAST_LEVEL)
                 }

         //        if bluetoothDeviceName != nil && !bluetoothDeviceName.isEmpty() && bluetoothDeviceName.length() > 4
         //        BluetoothManager.getInstance().setDummyMode(bluetoothDeviceName.subString(0, 4).compareTo("HTTP") == 0)

                 /* TODO:
                  if device != None {
                      // initialise the connection
                      device.initConnection()

                      // register application wide fields
                      // registerApplicationFields() // now done in Fields.load
                  }
                   */

                 // after loading PREFERENCES we may have new values for "dataExportMode"
                 // TODO: dataExportMode = dataLogger.activate(dataExportMode)
                  */

        Ecus.getInstance.load(assetName: "")
        Frames.getInstance.load(assetName: "")
        Fields.getInstance.load(assetName: "")

        // auto connect ? TODO
        // auto init ? TODO

//        let field = Fields.getInstance.getBySID(sid: "7ec.5003.0")
//        print(field?.sid)
    }

    func connect() {
        if !deviceIsConnectable() {
            view.hideAllToasts()
            view.makeToast("please configure")
            return
        }

        print("connecting")
        view.hideAllToasts()
        view.makeToast("_connecting, wait for initialize")
        if AppSettings.shared.deviceIsConnected {
            disconnect(showToast: false)
        }
        switch AppSettings.shared.deviceConnection {
        case .BLE:
            connectBle()
        case .WIFI:
            connectWifi()
        case .HTTP:
            AppSettings.shared.deviceIsConnected = true
            AppSettings.shared.deviceIsInitialized = true
            deviceConnected()
            view.hideAllToasts()
            view.makeToast("connected")
            return
        default:
            break
        }

        if AppSettings.shared.deviceType == .CANSEE {
            deviceConnected()
            AppSettings.shared.deviceIsConnected = true
            AppSettings.shared.deviceIsInitialized = true
            view.hideAllToasts()
            view.makeToast("connected")
        }
    }

    func disconnect(showToast: Bool) {
        print("disconnecting")
        if showToast {
            view.hideAllToasts()
            view.makeToast("_disconnecting")
        }
        switch AppSettings.shared.deviceConnection {
        case .BLE:
            disconnectBle()
        case .WIFI:
            disconnectWifi()
        default:
            break
        }
        AppSettings.shared.deviceIsConnected = false
        AppSettings.shared.deviceIsInitialized = false
        deviceDisconnected()
        fieldResultsDouble = [:]
        fieldResultsString = [:]
    }

    // gestione coda
    func processaCoda() {
        if !AppSettings.shared.deviceIsConnected {
            print("can't continue, device not connected")
            return
        }

        if coda.count == 0 {
            print("FINITO")
            NotificationCenter.default.post(name: Notification.Name("fineCoda"), object: nil)
            return
        }

        write(s: coda.first!)

        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            print("coda timeout !!!")
            timer.invalidate()
            return
        }
    }

    func continuaCoda() {
        // next step, after delay
        if coda.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { // Change `x.xxx` to the desired number of seconds.
                self.coda.remove(at: 0)
                self.processaCoda()
            }
        }
    }

    func write(s: String) {
        switch AppSettings.shared.deviceConnection {
        case .BLE:
            writeBle(s: s)
        case .WIFI:
            writeWifi(s: s)
        case .HTTP:
            writeHttp(s: s)
        case .NONE:
            print("device connection unknown")
            return
        }
    }

    // TEST

    func addField(sid: String, intervalMs: Int) {
        let field = Fields.getInstance.getBySID(sid: sid)
        if field != nil {
            if field!.responseId != "999999" {
                //  addField(field:field, intervalMs: intervalMs)
                //   print("sid \(field?.from ?? -1)")
                requestIsoTpFrame(frame2: (field?.frame)!, field: field!)
            }
        } else {
//            MainActivity.debug(this.getClass().getSimpleName() + " (CanzeActivity): SID " + sid + " does not exist in class Fields");
//            MainActivity.toast(MainActivity.TOAST_NONE, String.format(Locale.getDefault(), MainActivity.getStringSingle(R.string.format_NoSid), this.getClass().getSimpleName(), sid));
        }
    }

    func requestIsoTpFrame(frame2: Frame, field: Field) {
        // TEST
        // TEST
        var frame = frame2
        if frame.sendingEcu.fromId == 0x18DAF1DA, frame.responseId == "5003" {
            let ecu = Ecus.getInstance.getByFromId(fromId: 0x18DAF1D2)
            frame.sendingEcu = ecu
            frame.fromId = ecu.fromId
        }
        // TEST
        // TEST

        // print("\(frame.sendingEcu.name ?? "") \(frame.responseId ?? "")")

        if field.virtual {
//            var r = calcolaVirtual(field)
//            let dic = ["tag":r]
//            NotificationCenter.default.post(name: Notification.Name("ricevuto2"), object: dic)

            let virtualField = Fields.getInstance.getBySID(sid: field.sid) as! VirtualField
            let fields = virtualField.getFields()
            for f in fields {
                if f.responseId != "999999" {
                    requestIsoTpFrame(frame2: (f.frame)!, field: f)
                }
            }
            let seq = coda2.first
            seq?.sidVirtual = field.sid
            return
        }

        let seq = Sequenza()
        seq.field = field

        if lastId != frame.fromId {
            if AppSettings.shared.deviceConnection == .HTTP {
                let s = "?command=i\(String(format: "%02x", frame.fromId)),\(frame.getRequestId()),\(field.responseId ?? "")"
                seq.cmd.append(s)
                coda2.append(seq)
                return

            } else {
                if frame.isExtended() {
                    seq.cmd.append("atsp7")
                } else {
                    seq.cmd.append("atsp6")
                }
                seq.cmd.append("atcp\(frame.getToIdHexMSB())") // atcp18
                seq.cmd.append("atsh\(frame.getToIdHexLSB())") // atshdad2f1
                seq.cmd.append("atcra\(String(format: "%02x", frame.fromId))") // 18daf1d2
                seq.cmd.append("atfcsh\(String(format: "%02x", frame.getToId()))") // 18dad2f1
            }

            lastId = frame.fromId
        }

        // elm327.java

        // ISOTP outgoing starts here
        let outgoingLength = frame.getRequestId().count
//        var elmResponse = ""
        var elmCommand = ""
        if outgoingLength <= 14 {
            // SINGLE transfers up to 7 bytes. If we ever implement extended addressing (which is
            // not the same as 29 bits mode) this driver considers this simply data
            // 022104           ISO-TP single frame - length 2 - payload 2104, which means PID 21 (??), id 04 (see first tab).
            elmCommand = "0\(outgoingLength / 2)\(frame.getRequestId())" // 021003
            seq.cmd.append(elmCommand)
            // send SING frame.
            // elmResponse = sendAndWaitForAnswer(elmCommand, 0, false).replace("\r", "")
        } else {
            var startIndex = 0
            var endIndex = 12
            // send FRST frame.
            print(" send FRST frame")
            elmCommand = String(format: "1%03X", outgoingLength / 2) + frame.getRequestId().subString(from: startIndex, to: endIndex)
            seq.cmd.append(elmCommand)
            // flushWithTimeout(500, '>');
            ///                var elmFlowResponse = sendAndWaitForAnswer(elmCommand, 0, false).replace("\r", "")
            startIndex = endIndex
            if startIndex > outgoingLength {
                startIndex = outgoingLength
            }
            endIndex += 14
            if endIndex > outgoingLength {
                endIndex = outgoingLength
            }
            var next = 1
            while startIndex < outgoingLength {
                // prepare NEXT frame.
                elmCommand = String(format: "2%01X", next) + frame.getRequestId().subString(from: startIndex, to: endIndex)
                seq.cmd.append(elmCommand)
                // for the moment we ignore block size, just 1 or all. Also ignore delay
                ///                    if elmFlowResponse.startsWith("3000") {
                // The receiving ECU expects all data to be sent without further flow control,
                // the ELM still answers with at least a \n after each sent frame.
                // Since there are no further flow control frames, we just pretent the answer
                // of each frame is the actual answer and won't change the FlowResponse
                // flushWithTimeout(500, '>');
                ///                        elmResponse = sendAndWaitForAnswer(elmCommand, 0, false).replace("\r", "")
                ///                    } else if elmFlowResponse.startsWith("30") {
                // The receiving ECU expects the next frame of data to be sent, and it will
                // respond with the next flow control command, or the actual answer. We just
                // pretent the answer of the frame is both the actual answer as wel as the next
                // FlowResponse
                // flushWithTimeout(500, '>');
                ///                        elmFlowResponse = sendAndWaitForAnswer(elmCommand, 0, false).replace("\r", "")
                ///                        elmResponse = elmFlowResponse
                ///                    } else {
                ///                         return new Message(frame, "-E-ISOTP tx flow Error:" + elmFlowResponse, true)
            }
            startIndex = endIndex
            if startIndex > outgoingLength {
                startIndex = outgoingLength
            }
            endIndex += 14
            if endIndex > outgoingLength {
                endIndex = outgoingLength
            }
            if next == 15 {
                next = 0
            } else {
                next += 1
            }
        }

        coda2.append(seq)
    }

    func decodeIsoTp(elmResponse2: String) -> String { // TEST
        var hexData = ""
        var len = 0

        var elmResponse = elmResponse2

        // ISOTP receiver starts here
        // clean-up if there is mess around
        elmResponse = elmResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if elmResponse.starts(with: ">") {
            elmResponse = elmResponse.subString(from: 1)
        }

        /*    // quit on error conditions
         if (elmResponse.compareTo("CAN ERROR") == 0) {
             return new Message(frame, "-E-Can Error", true)
         } else if (elmResponse.compareTo("?") == 0) {
             return new Message(frame, "-E-Unknown command", true)
         } else if (elmResponse.compareTo("") == 0) {
             return new Message(frame, "-E-Empty result", true)
         }
         */
        // get type (first nibble of first line)
        switch elmResponse.subString(from: 0, to: 1) {
        case "0": // SINGLE frame
//                     try {
            len = Int(elmResponse.subString(from: 1, to: 2), radix: 16)!
            // remove 2 nibbles (type + length)
            hexData = elmResponse.subString(from: 2)
        // and we're done
//                     } catch (StringIndexOutOfBoundsException e) {
//                         return new Message(frame, "-E-ISOTP rx unexpected length of SING frame:" + elmResponse, true);
//                     } catch (NumberFormatException e) {
//                         return new Message(frame, "-E-ISOTP rx uninterpretable length of SING frame:" + elmResponse, true);

//        default:
//            print("altri casi ancora da implementare")
//            tv.text.append("\naltri casi ancora da implementare")
//            tv.scrollToBottom()
//        }

        case "1": // FIRST frame
            len = Int(elmResponse.subString(from: 1, to: 4), radix: 16)!
            // remove 4 nibbles (type + length)
            hexData = elmResponse.subString(from: 4)
            //                     } catch (StringIndexOutOfBoundsException e) {
            //                         return new Message(frame, "-E-ISOTP rx unexpected length of FRST frame:" + elmResponse, true);
            //                     } catch (NumberFormatException e) {
            //                         return new Message(frame, "-E-ISOTP rx uninterpretable length of FRST frame:" + elmResponse, true);
            //                     }
            // calculate the # of frames to come. 6 byte are in and each of the 0x2 frames has a payload of 7 bytes
            let framesToReceive = len / 7 // read this as ((len - 6 [remaining characters]) + 6 [offset to / 7, so 0->0, 1-7->7, etc]) / 7
            // get all remaining 0x2 (NEXT) frames

            // coda.append(framesToReceive)

            // TEST
            // TEST
            // TEST
            //  var lines0x1 = "" // sendAndWaitForAnswer(nil, 0, framesToReceive)
            //     "101462F19056463121414730303030362234393531353432"
            // lines0x1 = "62F19056463121414730303030362234393531353432"
            /*
             var fin = hexData.subString(from: 6, to: 12)
             var i = 0
             while i < framesToReceive {
                 let sub = hexData.subString(from: 14+i*16, to:  28+i*16)
                 fin.append(sub)
                 i += 1
             }
             hexData = fin
             */
            var fin = hexData.subString(from: 0, to: 12)
            var i = 0
            while i < framesToReceive {
                let sub = hexData.subString(from: 14 + i * 16, to: 28 + i * 16)
                fin.append(sub)
                i += 1
            }
            hexData = fin

            // TEST
            // TEST
            // TEST

        /*
            // split into lines with hex data
            let hexDataLines = lines0x1.components(separatedBy: "[\\r]+")
            var next = 1
            for hexDataLine_ in hexDataLines {
                // ignore empty lines
                var hexDataLine = hexDataLine_
                hexDataLine = hexDataLine.trimmingCharacters(in: .whitespaces)
                if hexDataLine.count > 2 {
                    // check the proper sequence
                    if hexDataLine.hasPrefix(String(format: "2%01X", next)) {
                        // cut off the first byte (type + sequence) and add to the result
                        hexData += hexDataLine.subString(from: 2)
                    } else {
                        //  return new Message(frame, "-E-ISOTP rx out of sequence:" + hexDataLine, true);
                    }
                    if next == 15 {
                        next = 0
                    } else {
                        next += 1
                    }
                }
            }
         */
        default: // a NEXT, FLOWCONTROL should not be received. Neither should any other string (such as NO DATA)
            // flushWithTimeout(400, '>');
            // return new Message(frame, "-E-ISOTP rx unexpected 1st nibble of 1st frame:" + elmResponse, true);
            print("-E-ISOTP rx unexpected 1st nibble of 1st frame")
        }
        // There was spurious error here, that immediately sending another command STOPPED the still not entirely finished ISO-TP command.
        // It was probably still sending "OK>" or just ">". So, the next command files and if it was i.e. an atcra f a free frame capture,
        // the following ATMA immediately overwhelmed the ELM as no filter was set.
        // As a solution, added this wait for a > after an ISO-TP command.

//             flushWithTimeout(400, '>');
        len *= 2

        // Having less data than specified in length is actually an error, but at least we do not need so substr it
        // if there is more data than specified in length, that is OK (filler bytes in the last frame), so cut those away
        hexData = (hexData.count <= len) ? hexData.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() : hexData.subString(from: 0, to: len).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if hexData == "" {
//                 return new Message(frame, "-E-ISOTP rx data empty", true);
            print("-E-ISOTP rx data empty")
        } else {
//                 return new Message(frame, hexData.toLowerCase(), false);
            // print(hexData.lowercased())
        }

        debug(s: "decodeIsoTp \(hexData.lowercased())")

        return hexData.lowercased()
    }

    func onMessageCompleteEventField(binString_: String, field: Field) {
        var binString = binString_

        if binString.count >= field.to, field.responseId != "999999" {
            // parseInt --> signed, so the first bit is "cut-off"!
            //  try {
            binString = binString.subString(from: field.from, to: field.to + 1)
            if field.isString() {
                var tmpVal = ""
                var i = 0
                while i < binString.count {
                    let n = "0" + binString.subString(from: i, to: i + 8)
                    let nn = Int(n, radix: 2)
                    let c = UnicodeScalar(nn!)
                    tmpVal.append(String(c!))
                    i += 8
                }
                field.strVal = tmpVal
            } else if field.isHexString() {
                var tmpVal = ""
                var i = 0
                while i < binString.count {
                    let n = "0" + binString.subString(from: i, to: i + 8)
                    let nn = Int(n, radix: 2)
                    let c = UnicodeScalar(nn!)
                    let s = String(format: "%02X", c as! CVarArg)
                    tmpVal.append(s)
                    i += 8
                }
                field.strVal = tmpVal
            } else if binString.count <= 4 || binString.contains("0") {
                // experiment with unavailable: any field >= 5 bits whose value contains only 1's
                var val = 0 // long to avoid craze overflows with 0x8000 ofsets

                if field.isSigned(), binString.hasPrefix("1") {
                    // ugly method: flip bits, add a minus in front and subtract one
                    val = Int("-" + binString.replacingOccurrences(of: "0", with: "q").replacingOccurrences(of: "1", with: "0").replacingOccurrences(of: "q", with: "1"), radix: 2)! - 1
                } else {
                    val = Int("0" + binString, radix: 2)!
                }
                // MainActivity.debug("Value of " + field.getFromIdHex() + "." + field.getResponseId() + "." + field.getFrom()+" = "+val);
                // MainActivity.debug("Fields: onMessageCompleteEvent > "+field.getSID()+" = "+val);

                // update the value of the field. This triggers updating all of all listeners of that field
                field.value = Double(val)

            } else {
                field.value = Double.nan
            }

            // do field logging
//                if(MainActivity.fieldLogMode)
//                    FieldLogger.getInstance().log(field.getDebugValue());

//            } catch (Exception e)
//            {
//                MainActivity.debug("Message.onMessageCompleteEventField: Exception:");
//                MainActivity.debug(e.getMessage());
            // ignore
//            }
        }
        // update the fields last request date
        //  field.updateLastRequest();
    }

    var error = false
    func getAsBinaryString(data: String) -> String {
        // 629001266f
        // 0110001010010000000000010010011001101111

        var result = ""

        if !error {
//            let x = Int64(data, radix: 16)            // max data length:16 chars
//            result = String(x!, radix: 2)
            var d = data
            if d.count % 2 != 0 {
                d = "0" + d
            }
            result = d.hexaToBinary
            while result.count % 8 != 0 {
                result = "0" + result
            }
            // print(result)
        }
        return result
    }

    // TEST

    // ELM327 BLE
    // ELM327 BLE
    // ELM327 BLE
    func connectBle() {
        peripheralsDic = [:]
        // peripheralsArray = []
        selectedPeripheral = nil
        if blePhase == .DISCOVERED {
            timeoutTimerBle = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
                if self.selectedPeripheral == nil {
                    // timeout
                    self.centralManager.stopScan()
                    timer.invalidate()
                    self.view.makeToast("can't connect to ble device: TIMEOUT")
                }
            })
        }
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func disconnectBle() {
        if selectedPeripheral != nil, selectedPeripheral.blePeripheral != nil {
            centralManager.cancelPeripheralConnection(selectedPeripheral.blePeripheral)
            selectedPeripheral.blePeripheral = nil
            selectedService = nil
            selectedReadCharacteristic = nil
            selectedWriteCharacteristic = nil
        }
    }

    func writeBle(s: String) {
        if selectedWriteCharacteristic != nil {
            let ss = s.appending("\r")
            let data = ss.data(using: .utf8)
            if data != nil {
                if selectedWriteCharacteristic.properties.contains(.write) {
                    selectedPeripheral.blePeripheral.writeValue(data!, for: selectedWriteCharacteristic, type: .withResponse)
                    debug(s: "> \(s)")
                } else if selectedWriteCharacteristic.properties.contains(.writeWithoutResponse) {
                    selectedPeripheral.blePeripheral.writeValue(data!, for: selectedWriteCharacteristic, type: .withoutResponse)
                    debug(s: "> \(s)")
                } else {
                    debug(s: "can't write to characteristic")
                }
            } else {
                debug(s: "data is nil")
            }
        }
    }

    // ELM327 WIFI
    // ELM327 WIFI
    // ELM327 WIFI
    func connectWifi() {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           AppSettings.shared.deviceWifiAddress as CFString,
                                           UInt32(AppSettings.shared.deviceWifiPort)!,
                                           &readStream,
                                           &writeStream)

        inputStream = readStream!.takeRetainedValue()
        outputStream = writeStream!.takeRetainedValue()

        inputStream.delegate = self
        outputStream.delegate = self

        inputStream.schedule(in: RunLoop.current, forMode: .default)
        outputStream.schedule(in: RunLoop.current, forMode: .default)

        inputStream.open()
        outputStream.open()

        print("inputStream \(decodeStatus(status: inputStream.streamStatus))")
        print("outputStream \(decodeStatus(status: outputStream.streamStatus))")

        var contatore = 5
        timeoutTimerWifi = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            print(contatore)

            if self.inputStream != nil, self.outputStream != nil, self.inputStream.streamStatus == .open, self.outputStream.streamStatus == .open {
                // connesso
                self.timeoutTimerWifi.invalidate()
                self.timeoutTimerWifi = nil
                AppSettings.shared.deviceIsConnected = true
                self.deviceConnected()

                if self.inputStream.streamStatus == .open && self.outputStream.streamStatus == .open {
                    NotificationCenter.default.post(name: Notification.Name("connected"), object: nil)
                }
            }

            if contatore < 1 {
                // NON connesso
                self.timeoutTimerWifi.invalidate()
                self.timeoutTimerWifi = nil
                self.disconnectWifi()
                DispatchQueue.main.async {
                    self.view.hideAllToasts()
                    self.view.makeToast("TIMEOUT")
                    self.disconnect(showToast: false)
                }
                AppSettings.shared.deviceIsConnected = false
                self.deviceDisconnected()
            }

            contatore -= 1

        })
    }

    func disconnectWifi() {
        // TODO:
        AppSettings.shared.deviceIsConnected = false
        deviceDisconnected()
        if inputStream != nil {
            inputStream.close()
            inputStream.remove(from: RunLoop.current, forMode: .default)
            inputStream.delegate = nil
            inputStream = nil
        }
        if outputStream != nil {
            outputStream.close()
            outputStream.remove(from: RunLoop.current, forMode: .default)
            outputStream.delegate = nil
            outputStream = nil
        }
    }

    func writeWifi(s: String) {
        // TODO:
        if outputStream != nil {
            let s2 = s.appending("\r")
            let data = s2.data(using: .utf8)!
            data.withUnsafeBytes {
                guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    debug(s: "Error")
                    return
                }
                debug(s: "> \(s)")
                outputStream.write(pointer, maxLength: data.count)
            }
        }
    }

    // ricezione dati wifi
    @objc func didReceiveFromWifiDongle(notification: Notification) {
        let dic = notification.object as? [String: Any]
        if dic != nil, dic?.keys != nil {
            for k in dic!.keys {
                let ss = dic![k] as! String
                NotificationCenter.default.post(name: Notification.Name("ricevuto"), object: ["tag": ss])
            }
        }
    }

    func decodeStatus(status: Stream.Status) -> String {
        switch status {
        case .notOpen:
            return "notOpen"
        case .opening:
            return "opening"
        case .open:
            return "open"
        case .reading:
            return "reading"
        case .writing:
            return "writing"
        case .atEnd:
            return "atEnd"
        case .closed:
            return "closed"
        case .error:
            return "error"
        @unknown default:
            fatalError()
        }
    }

    // http

    func writeHttp(s: String) {
        var request = URLRequest(url: URL(string: "\(AppSettings.shared.deviceHttpAddress)\(s)")!, timeoutInterval: 5)
        request.httpMethod = "GET"

        debug(s: "> \(s)")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data else {
                print(error?.localizedDescription ?? "?")
                self.view.makeToast(error?.localizedDescription)
                return
            }
//            print(data)
            let reply = String(data: data, encoding: .utf8)
            let reply2 = reply?.components(separatedBy: ",")
            if reply2?.count == 2 {
                var reply3 = reply2?.last
                if reply3!.contains("problem") {
                    reply3 = "ERROR"
                }
                let dic = ["tag": reply3]
                NotificationCenter.default.post(name: Notification.Name("ricevuto2"), object: dic)
            } else {
                self.debug(s: reply!)
            }
        }
        task.resume()
    }

    func iniziaCoda2() {
        // TEST
        // if !deviceIsInitialized {
        // debug(s: "device not Initialized")
        // return
        // }
        // TEST
        indiceCmd = 0
        processaCoda2()
    }

    func processaCoda2() {
        if coda2.count == 0 {
            print("FINITO coda2")
            NotificationCenter.default.post(name: Notification.Name("fineCoda2"), object: nil)
            return
        }

        let seq = coda2.first! as Sequenza
        if indiceCmd >= seq.cmd.count {
            coda2.removeFirst()
            // print("FINITO cmd")
            iniziaCoda2()
            return
        }
        let cmd = seq.cmd[indiceCmd]
        write(s: cmd)

        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { timer in
            timer.invalidate()
            self.debug(s: "coda2 timeout !!!")
            DispatchQueue.main.async {
                self.view.hideAllToasts()
                self.view.makeToast("TIMEOUT")
                self.disconnect(showToast: false)
            }
            return
        }
    }

    func continuaCoda2() {
        // next step, after delay
        indiceCmd += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { // Change n to the desired number of seconds
            self.processaCoda2()
        }
    }
}

// MARK: StreamDelegate

// wifi
extension CanZeViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if aStream == inputStream {
                //   print("\(aStream) hasBytesAvailable")
                readAvailableBytes(stream: aStream as! InputStream)
            }
        case .endEncountered:
            debug(s: "\(aStream) endEncountered")
        case .hasSpaceAvailable:
            // print("\(aStream) hasSpaceAvailable")
            if aStream == outputStream {
//                print("ready")
//                print("ready")
                //   debug(s: "ready")
                // tv.text += ("ready\n")
                // tv.scrollToBottom()
            }
        case .errorOccurred:
            debug(s: "\(aStream) errorOccurred")
        case .openCompleted:
            debug(s: "\(aStream) openCompleted")
        default:
            debug(s: "\(aStream) \(eventCode.rawValue)")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
            if numberOfBytesRead < 0, let error = stream.streamError {
                debug(s: error.localizedDescription)
                break
            }
            var string = String(
                bytesNoCopy: buffer,
                length: numberOfBytesRead,
                encoding: .utf8,
                freeWhenDone: true)
            if string != nil, string!.count > 0 {
                string = string?.trimmingCharacters(in: .whitespacesAndNewlines)
                string = String(string!.filter { !">".contains($0) })
                string = String(string!.filter { !"\r".contains($0) })
                let dic: [String: String] = ["tag": string!]
                NotificationCenter.default.post(name: Notification.Name("didReceiveFromWifiDongle"), object: dic)
            }
        }
    }

    @objc func ricevuto(notification: Notification) {
        if coda.count > 0 || codaInit.count > 0 {
            if timeoutTimer != nil, timeoutTimer.isValid {
                timeoutTimer.invalidate()
                if coda.count > 0 {
                    continuaCoda()
                } else if codaInit.count > 0 {
                    continuaCodaInit()
                }
            }
        } else if coda2.count > 0 {
            NotificationCenter.default.post(name: Notification.Name("ricevuto2"), object: notification.object)
        } else {
            let dic = notification.object as! [String: Any]
            let ss = dic["tag"] as! String
            debug(s: "< \(ss)")
        }
    }

    @objc func ricevuto2(notification: Notification) {
        var error = "ok"
        let dic = notification.object as! [String: Any]
        let risposta = dic["tag"] as! String

        debug(s: "< '\(risposta)' \(risposta.count)")

        // TEST
        var sid = ""
        let seq = coda2.first
        if dic["sid"] != nil {
            sid = dic["sid"] as! String
        } else {
            sid = (seq?.field.sid)!
        }
        // TEST

        let field = Fields.getInstance.getBySID(sid: sid)

        if risposta.contains("ERROR") {
            // do nothing
            error = "ERROR"
            debug(s: error)
        } else if risposta == "OK" {
            // do nothing
        } else if risposta == "" {
            error = "EMPTY"
            debug(s: error)
        } else if field != nil {
            if AppSettings.shared.deviceType == .ELM327 {
                field?.strVal = decodeIsoTp(elmResponse2: risposta) // ""
            } else {
                // http, cansee
                field?.strVal = risposta
            }

//            print("\(field?.sid ?? "?") \(field?.name ?? "?")")
//            tv.text += "\n\(field?.sid ?? "?") \(field?.name ?? "?")"

            if field!.strVal.hasPrefix("7f") {
                error = "ERROR 7F"
                debug(s: error)
            } else if field!.strVal == "" {
                error = "EMPTY"
                debug(s: error)
            } else {
                let binString = getAsBinaryString(data: field!.strVal)
                // debug(s: binString)
                onMessageCompleteEventField(binString_: binString, field: field!)

                if seq?.sidVirtual != nil {
                    var result = 0.0
                    switch seq?.sidVirtual {
                    case Sid.Instant_Consumption:
                        break
                    case Sid.FrictionTorque:
                        break
                    case Sid.DcPowerIn:
                        if fieldResultsDouble[Sid.TractionBatteryVoltage] != nil, fieldResultsDouble[Sid.TractionBatteryCurrent] != nil {
                            result = fieldResultsDouble[Sid.TractionBatteryVoltage]! * fieldResultsDouble[Sid.TractionBatteryCurrent]! / 1000.0
                        }
                    case Sid.DcPowerOut:
                        if fieldResultsDouble[Sid.TractionBatteryVoltage] != nil, fieldResultsDouble[Sid.TractionBatteryCurrent] != nil {
                            result = fieldResultsDouble[Sid.TractionBatteryVoltage]! * fieldResultsDouble[Sid.TractionBatteryCurrent]! / -1000.0
                        }
                    case Sid.ElecBrakeTorque:
                        break
                    case Sid.TotalPositiveTorque:
                        break
                    case Sid.TotalNegativeTorque:
                        break
                    case Sid.ACPilot:
                        break
                    default:
                        print("unknown virtual sid")
                    }
                    field?.value = result
                }

                if field!.isString() || field!.isHexString() {
                    debug(s: "\(field!.strVal)")
                    fieldResultsString[field!.sid] = field!.strVal
                } else if sid == Sid.BatterySerial, field?.strVal != nil, (field?.strVal.count)! > 6, AppSettings.shared.car == AppSettings.CAR_ZOE_Q210 {
                    field?.strVal = (field?.strVal.subString(from: (field?.strVal.count)! - 6))!
                    field?.strVal = "F" + field!.strVal
                    fieldResultsString[field!.sid] = field!.strVal
                    debug(s: "\(field!.strVal)")
                } else {
                    debug(s: "\(field?.name ?? "?") \(String(format: "%.\(field!.decimals!)f", field!.getValue()))\n")
                    fieldResultsDouble[field!.sid] = field!.getValue()
                }
            }

            let dic = ["debug": "Debug \(field?.sid ?? "?") \(error)"]
            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)

        } else {
            debug(s: "field \(seq?.field.sid ?? "?") not found")
        }

        NotificationCenter.default.post(name: Notification.Name("decodificato"), object: notification.object)

        if coda2.count > 0, timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
            continuaCoda2()
        }
    }

    func processaCodaInit() {
        if codaInit.count == 0 {
            print("FINITO")
            AppSettings.shared.deviceIsInitialized = true
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
            return
        }
        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        write(s: codaInit.first!)
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            print("coda timeout !!!")
            timer.invalidate()
            return
        }
    }

    func continuaCodaInit() {
        // next step, after delay
        if codaInit.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { // Change n to the desired number of seconds
                self.codaInit.remove(at: 0)
                self.processaCodaInit()
            }
        }
    }
}

// MARK: CBCentralManagerDelegate

extension CanZeViewController: CBCentralManagerDelegate {
    // CentralManager
    // CentralManager
    // CentralManager
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            debug(s: "central.state is .unknown")
        case .resetting:
            debug(s: "central.state is .resetting")
        case .unsupported:
            debug(s: "central.state is .unsupported")
        case .unauthorized:
            debug(s: "central.state is .unauthorized")
        case .poweredOff:
            debug(s: "central.state is .poweredOff")
        case .poweredOn:
            debug(s: "central.state is .poweredOn")
            //            centralManager.scanForPeripherals(withServices: [serviceCBUUID])
            centralManager.scanForPeripherals(withServices: [])
        @unknown default:
            debug(s: "central.state is unknown")
        }
    }

    // Peripheral
    // Peripheral
    // Peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let p = BlePeripheral()
        p.blePeripheral = peripheral
        p.rssi = RSSI
        peripheralsDic[peripheral.identifier.uuidString] = p

        //        peripheralsArray.sort { (a:Peripheral, b:Peripheral) -> Bool in
        //            a.peripheral.name ?? "" < b.peripheral.name ?? ""
        //        }

        if blePhase == .DISCOVERED, AppSettings.shared.deviceBlePeripheralIdentifierUuid == p.blePeripheral.identifier.uuidString {
            timeoutTimerBle.invalidate()
            centralManager.stopScan()
            p.blePeripheral.delegate = self
            selectedPeripheral = p
            debug(s: "found selected Peripheral \(selectedPeripheral.blePeripheral.name ?? "")")
            centralManager.connect(selectedPeripheral.blePeripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debug(s: "didConnect \(peripheral.name ?? "?") \(peripheral.identifier.uuidString)")
        servicesArray = []
        pickerPhase = .SERVICES
        //   tmpPickerIndex = 0
        //  peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debug(s: "didFailToConnect \(peripheral) \(error?.localizedDescription ?? "")")
    }

    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        debug(s: "connectionEventDidOccur \(peripheral)")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debug(s: "didDisconnectPeripheral \(peripheral.name ?? "")")
    }

    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {}

    //    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    //    }
}

// MARK: CBPeripheralDelegate

extension CanZeViewController: CBPeripheralDelegate {
    // Services
    // Services
    // Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        }
        //        var i = 0
        //        while i < peripheral.services!.count {
        //            let service = peripheral.services![i]
        //            print(service)
        //            tv.text += ("\n\(service.uuid.uuidString)")
        //            tv.scrollToBottom()
        //            servicesArray.append(service)
        //            i = i + 1
        //        }
        servicesArray.append(contentsOf: peripheral.services ?? [])

        if blePhase == .DISCOVERED {
            for s in servicesArray {
                if s.uuid.uuidString == AppSettings.shared.deviceBleServiceUuid {
                    selectedService = s
                    debug(s: "found selected service \(selectedService.uuid)")
                    characteristicArray = []
                    selectedPeripheral.blePeripheral.discoverCharacteristics([selectedService.uuid], for: selectedService)
                    break
                }
            }
        }
    }

    //    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    //        print("\(Date().description(with: Locale.current)) didWriteValueFor \(peripheral.name ?? "") \(descriptor.uuid) \(error?.localizedDescription ?? "")")
    //    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("didUpdateValueFor \(descriptor.uuid) \(error?.localizedDescription ?? "")")
    }

    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print("peripheralDidUpdateName \(peripheral.name!)")
    }

    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        print("peripheralIsReady toSendWriteWithoutResponse \(peripheral.name!)")
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {}

    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {}

    func peripheral(_ peripheral: CBPeripheral, didOpen channel: CBL2CAPChannel?, error: Error?) {}

    // Characteristics
    // Characteristics
    // Characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //        print("didDiscoverCharacteristicsFor ")
        if service.characteristics != nil, service.characteristics!.count > 0 {
            // selectedPeripheral.characteristics = service.characteristics!
            // var ii = 0
            // while ii < service.characteristics!.count {
            //   let characteristic = service.characteristics![ii]
            //  characteristicArray.append(characteristic)
            /*
              let s = "\(characteristic) \(characteristic.properties)"
             print(s)
             tv.text += "\n\(s)"
             tv.scrollToBottom()
             if characteristic.properties.contains(.read) {
                 tv.text += "read "
             }
             if characteristic.properties.contains(.write) {
                 tv.text += "write "
             }
             if characteristic.properties.contains(.writeWithoutResponse) {
                 tv.text += "writeWithoutResponse "
             }
             if characteristic.properties.contains(.notify) {
                 tv.text += "notify"
             }
             tv.text += "\n"
             */
            // ii = ii + 1
            // }
            characteristicArray.append(contentsOf: service.characteristics ?? [])

            if blePhase == .DISCOVERED {
                for c in characteristicArray {
//                    print(c.uuid.uuidString)
                    if c.uuid.uuidString == AppSettings.shared.deviceBleWriteCharacteristicUuid {
                        selectedWriteCharacteristic = c
                        debug(s: "found selected write characteristic \(c.uuid)")
                        // peripheral.discoverDescriptors(for: characteristics)
                    }
                    if c.uuid.uuidString == AppSettings.shared.deviceBleReadCharacteristicUuid {
                        selectedReadCharacteristic = c
                        debug(s: "found selected notify characteristic \(c.uuid)")
                        if c.properties.contains(.notify) {
//                            for c in selectedService.characteristics! {
//                              selectedPeripheral.blePeripheral.setNotifyValue(false, for: c)
//                            }
                            selectedPeripheral.blePeripheral.setNotifyValue(true, for: c)
                        }
                        // peripheral.discoverDescriptors(for: characteristics)
                    }

                    if selectedReadCharacteristic != nil, selectedWriteCharacteristic != nil {
                        NotificationCenter.default.post(name: Notification.Name("connected"), object: nil)
                        AppSettings.shared.deviceIsConnected = true
                        deviceConnected()
                        break
                    }
                }
            }
        } else {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("error didWriteValueFor \(characteristic.uuid.uuidString) \(error!.localizedDescription)")
            return
        } else {
            // print("\(Date().description(with: Locale.current)) didWriteValueFor \(peripheral.name ?? "") \(characteristic.uuid) \(error?.localizedDescription ?? "")")
            // print("didWriteValueFor \(peripheral.name!) \(characteristic.uuid)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // print("\(Date().description(with: Locale.current)) didUpdateValueFor \(characteristic.uuid) \(error?.localizedDescription ?? "")")
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        } else if characteristic.uuid.uuidString == selectedReadCharacteristic.uuid.uuidString {
            let s = String(data: characteristic.value!, encoding: .utf8)
            if s?.last == ">" {
                lastRxString += s!

                var ss = lastRxString.trimmingCharacters(in: .whitespacesAndNewlines)
                ss = String(ss.filter { !">".contains($0) })
                ss = String(ss.filter { !"\r".contains($0) })

//                var ss = String(lastRxString.filter { !"\r".contains($0) })
//                ss = String(ss.filter { !"\n".contains($0) })
//                ss = String(ss.filter { !">".contains($0) })

                //  ss = ss.trimmingCharacters(in: .whitespacesAndNewlines)

//                print("< \(ss) (\(lastRxString.count) chars)")
//                tv.text += "\n< \(ss) (\(lastRxString.count) chars)"
//                tv.scrollToBottom()
                NotificationCenter.default.post(name: Notification.Name("ricevuto"), object: ["tag": ss])
                lastRxString = ""
//                if coda.count > 0, timeoutTimer != nil, timeoutTimer.isValid {
//                    timeoutTimer.invalidate()
                // print("risposta ricevuta")
//                    continuaCoda()
//                }
            } else {
                lastRxString += s ?? ""
                // print(".")
            }
        } else {
            print("ricevuto dati da char sconosciuta \(characteristic.uuid.uuidString)")
        }
    }

    // Descriptors
    // Descriptors
    // Descriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            debug(s: error!.localizedDescription)
        } else {
            let s = "didDiscoverDescriptorsFor \(characteristic.uuid)"
            debug(s: s)
            debug(s: "characteristic.descriptors \(characteristic.descriptors!)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {}

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            debug(s: "errore didUpdateNotificationStateFor characteristic \(characteristic.uuid.uuidString): \(error?.localizedDescription as Any)")
        } else {
            let s = "didUpdateNotificationStateFor \(characteristic.uuid)"
            debug(s: s)
            //   tv.text += "\n\(s)"
            //   tv.scrollToBottom()
        }
    }
}
