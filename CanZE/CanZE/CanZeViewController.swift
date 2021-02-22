//
//  CanZeViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import CoreBluetooth
import UIKit

class CanZeViewController: RootViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        Globals.shared.peripheralsDic = [:]
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
        // wifi
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFromWifiDongle(notification:)), name: Notification.Name("didReceiveFromWifiDongle"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(deviceConnected), name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDisconnected), name: Notification.Name("deviceDisconnected"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(received(notification:)), name: Notification.Name("received"), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(received2(notification:)), name: Notification.Name("received2"), object: nil)

        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queue2 = []

        if timeoutTimer != nil {
            if timeoutTimer.isValid {
                timeoutTimer.invalidate()
            }
            timeoutTimer = nil
//            disconnect(showToast: true)
        }
        if timeoutTimerBle != nil {
            if timeoutTimerBle.isValid {
                timeoutTimerBle.invalidate()
            }
            timeoutTimerBle = nil
//            disconnect(showToast: true)
        }
        if timeoutTimerWifi != nil {
            if timeoutTimerWifi.isValid {
                timeoutTimerWifi.invalidate()
            }
            timeoutTimerWifi = nil
//            disconnect(showToast: true)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("didReceiveFromWifiDongle"), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceDisconnected"), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name("received"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
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

    @IBAction func btnConnect() {
        if Globals.shared.deviceIsConnected {
            disconnect(showToast: true)
            deviceDisconnected()
        } else {
            startAutoInit()
        }
    }

    func startAutoInit() {
        disconnect(showToast: false)
        NotificationCenter.default.addObserver(self, selector: #selector(connected), name: Notification.Name("connected"), object: nil)
        connect()
    }

    @objc func connected() {
        Globals.shared.deviceIsConnected = true
        NotificationCenter.default.post(name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("connected"), object: nil)
        if Globals.shared.deviceType == .ELM327 {
            NotificationCenter.default.addObserver(self, selector: #selector(autoInit), name: Notification.Name("autoInit"), object: nil)
            initDeviceELM327()
        } else {
            if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
                vBG.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
            Globals.shared.deviceIsInitialized = true
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
        }
    }

    @objc func autoInit2() {
        autoInit()
        startQueue()
    }

    func startQueue() {
        // stub
    }

    func initDeviceELM327() {
        queueInit = []
        for s in autoInitElm327 {
            queueInit.append(s)
        }
        processQueueInit()
    }

    @objc func autoInit() {
        Globals.shared.deviceIsInitialized = true
        NotificationCenter.default.removeObserver(self, name: Notification.Name("autoInit"), object: nil)

        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }

        view.makeToast("connected and initialized")
    }

    func deviceIsConnectable() -> Bool {
        var connectable = false
        if Globals.shared.deviceType == .ELM327 || Globals.shared.deviceType == .CANSEE || Globals.shared.deviceType == .HTTP_GW {
            if Globals.shared.deviceConnection == .BLE, Globals.shared.deviceBlePeripheralName != "", Globals.shared.deviceBlePeripheralUuid != "", Globals.shared.deviceBleServiceUuid != "", Globals.shared.deviceBleReadCharacteristicUuid != "", Globals.shared.deviceBleWriteCharacteristicUuid != "" {
                connectable = true
            } else if Globals.shared.deviceConnection == .WIFI, Globals.shared.deviceWifiAddress != "", Globals.shared.deviceWifiPort != "" {
                connectable = true
            } else if Globals.shared.deviceConnection == .HTTP, Globals.shared.deviceHttpAddress != "" {
                connectable = true
            }
        }
        return connectable
    }

    func loadSettings() {
        Globals.shared.car = AppSettings.CAR_NONE
        Globals.shared.car = ud.integer(forKey: AppSettings.SETTINGS_CAR)
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

        Globals.shared.deviceConnection = AppSettings.DEVICE_CONNECTION(rawValue: ud.value(forKey: AppSettings.SETTINGS_DEVICE_CONNECTION) as? Int ?? 0) ?? .NONE

        Globals.shared.deviceWifiAddress = ud.string(forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS) ?? "192.168.0.10"
        Globals.shared.deviceWifiPort = ud.string(forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT) ?? "35000"
        ud.setValue(Globals.shared.deviceWifiAddress, forKey: AppSettings.SETTINGS_DEVICE_WIFI_ADDRESS)
        ud.setValue(Globals.shared.deviceWifiPort, forKey: AppSettings.SETTINGS_DEVICE_WIFI_PORT)
        ud.synchronize()

        Globals.shared.deviceBleName = AppSettings.DEVICE_BLE_NAME(rawValue: ud.value(forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME) as? Int ?? 0) ?? .NONE
        Globals.shared.deviceBlePeripheralName = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_NAME) ?? ""
        Globals.shared.deviceBlePeripheralUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID) ?? ""
        Globals.shared.deviceBleServiceUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID) ?? ""
        Globals.shared.deviceBleReadCharacteristicUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID) ?? ""
        Globals.shared.deviceBleWriteCharacteristicUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID) ?? ""

        Globals.shared.deviceHttpAddress = ud.string(forKey: AppSettings.SETTINGS_DEVICE_HTTP_ADDRESS) ?? ""

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

        Globals.shared.deviceType = AppSettings.DEVICE_TYPE(rawValue: ud.value(forKey: AppSettings.SETTINGS_DEVICE_TYPE) as? Int ?? 0) ?? .NONE
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
                 if ud.exists(key: AppSettings.SETTING_SECURITY_SAFE_MODE) {
         Globals.shared.safeDrivingMode = ud.bool(forKey: AppSettings.SETTING_SECURITY_SAFE_MODE)
                 }
         */

        Globals.shared.milesMode = false
        if ud.exists(key: AppSettings.SETTINGS_CAR_USE_MILES) {
            Globals.shared.milesMode = ud.bool(forKey: AppSettings.SETTINGS_CAR_USE_MILES)
        }
        print("SETTINGS_CAR_USE_MILES \(Globals.shared.milesMode)")

        Globals.shared.useIsoTpFields = true
        if ud.exists(key: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS) {
            Globals.shared.useIsoTpFields = ud.bool(forKey: AppSettings.SETTINGS_DEVICE_USE_ISOTP_FIELDS)
        }
        if Globals.shared.car == AppSettings.CAR_X10PH2 { // Ph2 car has no IsoTp Fields
            Globals.shared.useIsoTpFields = false
        }
        print("SETTINGS_DEVICE_USE_ISOTP_FIELDS \(Globals.shared.useIsoTpFields)")

        Globals.shared.useSdCard = false
        if ud.exists(key: AppSettings.SETTING_LOGGING_USE_SD_CARD) {
            Globals.shared.useSdCard = ud.bool(forKey: AppSettings.SETTING_LOGGING_USE_SD_CARD)
        }

        Globals.shared.writeForEmulator = false
        if ud.exists(key: AppSettings.SETTING_LOGGING_WRITE_FOR_EMULATOR) {
            Globals.shared.writeForEmulator = ud.bool(forKey: AppSettings.SETTING_LOGGING_WRITE_FOR_EMULATOR)
        }

        /*
         Globals.shared.debugLogMode = false
                 if ud.exists(key: SETTING_LOGGING_DEBUG_LOG) {
         Globals.shared.debugLogMode = ud.bool(forKey: SETTING_LOGGING_DEBUG_LOG)
                 }

         Globals.shared.fieldLogMode = false
                 if ud.exists(key: SETTING_LOGGING_FIELDS_LOG) {
         Globals.shared.fieldLogMode = ud.bool(forKey: SETTING_LOGGING_FIELDS_LOG)
                 }

         Globals.shared.toastLevel = TOAST_ELM
                 if ud.exists(key: SETTING_DISPLAY_TOAST_LEVEL) {
         Globals.shared.toastLevel = ud.integer(forKey: SETTING_DISPLAY_TOAST_LEVEL)
                 }
         */

        Ecus.getInstance.load(assetName: "")
        Frames.getInstance.load(assetName: "")
        Fields.getInstance.load(assetName: "")
    }

    func connect() {
        if !deviceIsConnectable() {
            view.hideAllToasts()
            view.makeToast("_please configure")
            return
        }

        print("connecting")

        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        vBG.tag = Globals.K_TAG_vBG
        view.addSubview(vBG)

        view.hideAllToasts()

        var s = ""

        switch Globals.shared.deviceType {
        case .ELM327:
            s += "DEVICE_TYPE_ELM327\n"
        case .CANSEE:
            s += "DEVICE_TYPE_CANSEE\n"
        case .HTTP_GW:
            s += "DEVICE_TYPE_HTTP_GW\n"
        default:
            s += "unknown\n"
        }

        switch Globals.shared.deviceConnection {
        case .WIFI:
            s += "DEVICE_CONNECTION_WIFI\n"
            s += Globals.shared.deviceWifiAddress + "\n"
            s += Globals.shared.deviceWifiPort + "\n"
        case .BLE:
            s += "DEVICE_CONNECTION_BLE\n"
            switch Globals.shared.deviceBleName {
            case .VGATE:
                s += "VGATE\n"
            case .LELINK:
                s += "LELINK\n"
            default:
                s += "unknown\n"
            }
        case .HTTP:
            s += "DEVICE_CONNECTION_HTTP\n"
            s += Globals.shared.deviceHttpAddress + "\n"
        default:
            s += "unknown\n"
        }

        view.makeToast("_connecting, wait for initialize\n\(s)")

        if Globals.shared.deviceIsConnected {
            disconnect(showToast: false)
        }
        switch Globals.shared.deviceConnection {
        case .BLE:
            connectBle()
        case .WIFI:
            connectWifi()
        case .HTTP:
            Globals.shared.deviceIsConnected = true
            Globals.shared.deviceIsInitialized = true
            deviceConnected()
            if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
                vBG.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
            return
        default:
            break
        }

        if Globals.shared.deviceType == .CANSEE {
            Globals.shared.deviceIsConnected = true
            Globals.shared.deviceIsInitialized = true
            deviceConnected()
            if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
                vBG.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
        }
    }

    func disconnect(showToast: Bool) {
        print("disconnecting")
        if showToast {
            DispatchQueue.main.async { [self] in
                view.hideAllToasts()
                view.makeToast("_disconnecting")
            }
        }
        switch Globals.shared.deviceConnection {
        case .BLE:
            disconnectBle()
        case .WIFI:
            disconnectWifi()
        default:
            break
        }
        Globals.shared.deviceIsConnected = false
        Globals.shared.deviceIsInitialized = false
        deviceDisconnected()
        Globals.shared.fieldResultsDouble = [:]
        Globals.shared.fieldResultsString = [:]
        Globals.shared.resultsBySid = [:]

        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }
    }

    func write(s: String) {
        switch Globals.shared.deviceConnection {
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

    func addFrame(frame: Frame) {
        if frame.isIsoTp() {
            requestIsoTpFrame(frame2: frame, field: nil, virtual: nil)
        } else {
//                if (MainActivity.altFieldsMode) MainActivity.toast(MainActivity.TOAST_NONE, "Free frame in ISOTP mode:" + frame.getRID()); // MainActivity.debug("********* free frame in alt mode ********: " + frame.getRID());
            // TODO:
            // requestFreeFrame(frame: frame)
            DispatchQueue.main.async { [self] in
                view.makeToast("FREE FRAMES NOT YET SUPPORTED")
            }
        }
    }

    func addField(_ sid: String, intervalMs: Int) {
        if let field = Fields.getInstance.getBySID(sid) {
            if field.responseId != "999999" {
                if field.virtual {
                    let virtualField = Fields.getInstance.getBySID(field.sid) as! VirtualField
                    let fields = virtualField.getFields()
                    for f in fields {
                        if f.responseId != "999999" {
                            var found = false
                            for s in queue2 {
                                if s.field.sid == f.sid {
                                    found = true
                                    break
                                }
                            }
                            if !found {
                                requestIsoTpFrame(frame2: (f.frame)!, field: f, virtual: field.sid)
                            }
                        }
                    }
                } else {
                    var found = false
                    if intervalMs != 0 { // to speed up pedal position update on DrivingViewController
                        for s in queue2 {
                            if s.field.sid == field.sid {
                                found = true
                                break
                            }
                        }
                    }
                    if !found {
                        requestIsoTpFrame(frame2: (field.frame)!, field: field, virtual: nil)
                    }
                }
            }
//        } else {
//            MainActivity.debug(this.getClass().getSimpleName() + " (CanzeActivity): SID " + sid + " does not exist in class Fields");
//            MainActivity.toast(MainActivity.TOAST_NONE, String.format(Locale.getDefault(), MainActivity.getStringSingle(R.string.format_NoSid), this.getClass().getSimpleName(), sid));
        }
    }

    func addField_(_ sid: String, intervalMs: Int) {
        if let f = Fields.getInstance.fieldsBySid[sid] {
            if f.lastRequest + Double(intervalMs / 1000) < Date().timeIntervalSince1970 {
                addField(sid, intervalMs: intervalMs)
            }
        }
    }

    func requestFreeFrame(frame: Frame) {
        //  var command = ""
        switch Globals.shared.deviceType {
        case .ELM327:

            //  var hexData = ""

            // ensure the ATCRA filter is reset in the next NON free frame request
//                 lastCommandWasFreeFrame = true

            // EML needs the filter to be 3 hex symbols and contains the from CAN id of the ECU.
            // getFromIdHex returns 3 chars for 11 bit id, and 8 bits for a 29 bit id
            let emlFilter = frame.getFromIdHex()

//                 MainActivity.debug("ELM327: requestFreeFrame: atcra" + emlFilter);
//                 if (!initCommandExpectOk("atcra" + emlFilter))
//                     return new Message(frame, "-E-Problem sending atcra command", true);

            let seq = Sequence()
            seq.cmd.append("atcra\(emlFilter)")

            // sendAndWaitForAnswer("atcra" + emlFilter, 400);
            // atma     (wait for one answer line)
//                 generalTimeout = (int) (frame.getInterval() * intervalMultiplicator + 50);
//                 if (generalTimeout < MINIMUM_TIMEOUT) generalTimeout = MINIMUM_TIMEOUT;
//                 MainActivity.debug("ELM327: requestFreeFrame > TIMEOUT = " + generalTimeout);

            // 10 ms plus repeat time timeout, do not wait until empty, do not count lines, add \r to command
//                 hexData = sendAndWaitForAnswer("atma", frame.getInterval() + 10);
            seq.cmd.append("atma\(frame.interval + 10)")
            seq.cmd.append("x")

            queue2.append(seq)

                // MainActivity.debug("ELM327: requestFreeFrame > hexData = [" + hexData + "]");
                 // the dongle starts babbling now. sendAndWaitForAnswer should stop at the first full line
                 // ensure any running operation is stopped
                 // sending a return might restart the last command. Bad plan.
                // sendNoWait("x");
                 // let it settle down, the ELM should indicate STOPPED then prompt >
//                 flushWithTimeout(100, '>');
//                 generalTimeout = DEFAULT_TIMEOUT;

                 // atar     (clear filter)
                 // AM has suggested the atar might not be neccesary as it might only influence cra filters and they are always set
                 // however, make sure proper flushing is done
                 // if cra does influence ISO-TP requests, an small optimization might be to only sending an atar when switching from free
                 // frames to isotp frames.
                 // if (!initCommandExpectOk("atar")) someThingWrong |= true;

//                 hexData = hexData.trim();
//                 if (hexData.equals(""))
//                     return new Message(frame, "-E-data empty", true);
//                 else
//                     return new Message(frame, hexData, false);

//             */

        case .HTTP_GW, .CANSEE:
            let seq = Sequence()
            seq.cmd.append("g" + frame.getFromIdHex())
            queue2.append(seq)
        default:
            print("device unknown")
        }
        addFrame(frame: frame)
    }

    func requestIsoTpFrame(frame2: Frame, field: Field?, virtual: String?) {
        // TEST
        // TEST
        let frame = frame2
        // if frame.sendingEcu.fromId == 0x18DAF1DA, frame.responseId == "5003" {
        // let ecu = Ecus.getInstance.getByFromId(0x18DAF1D2)
        // frame.sendingEcu = ecu
        // frame.fromId = ecu.fromId
        // }
        // TEST
        // TEST

        let seq = Sequence()

        if virtual != nil { // } || field!.sid.starts(with: "800.") {
            seq.sidVirtual = virtual
        }

        seq.frame = frame
        seq.field = field

        if Globals.shared.deviceType == .HTTP_GW {
            let s = "?command=i\(String(format: "%02x", frame.fromId)),\(frame.getRequestId()),\(frame.responseId ?? "")"
            seq.cmd.append(s)
            queue2.append(seq)
            return
        } else if Globals.shared.deviceType == .CANSEE {
            let s = "i\(String(format: "%02x", frame.fromId)),\(frame.getRequestId()),\(frame.responseId ?? "")"
            seq.cmd.append(s)
            queue2.append(seq)
            return
        }

        if lastId != frame.fromId {
            if frame.isExtended() {
                seq.cmd.append("atsp7")
            } else {
                seq.cmd.append("atsp6")
            }
            seq.cmd.append("atcp\(frame.getToIdHexMSB())") // atcp18
            seq.cmd.append("atsh\(frame.getToIdHexLSB())") // atshdad2f1
            seq.cmd.append("atcra\(String(format: "%02x", frame.fromId))") // 18daf1d2
            seq.cmd.append("atfcsh\(String(format: "%02x", frame.getToId()))") // 18dad2f1
            lastId = frame.fromId
        }

        // ISOTP outgoing starts here
        let outgoingLength = frame.getRequestId().count
        var elmCommand = ""
        if outgoingLength <= 14 {
            // SINGLE transfers up to 7 bytes. If we ever implement extended addressing (which is
            // not the same as 29 bits mode) this driver considers this simply data
            // 022104           ISO-TP single frame - length 2 - payload 2104, which means PID 21 (??), id 04 (see first tab).
            elmCommand = "0\(outgoingLength / 2)\(frame.getRequestId())" // 021003
            seq.cmd.append(elmCommand)
            // send SING frame.
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
//            if next == 15 {
//                next = 0
//            } else {
            next += 1
//            }
        }
        queue2.append(seq)
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

            // queue.append(framesToReceive)

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

        hexData = hexData.lowercased()
        debug("decodeIsoTp \(hexData)")

        return hexData
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
                field.strVal = tmpVal.trim()
            } else if field.isHexString() {
                var tmpVal = ""
                var i = 0
                while i < binString.count {
                    let n = "0" + binString.subString(from: i, to: i + 8)
                    let nn = Int(n, radix: 2)!
                    let c = UnicodeScalar(nn)
                    let s = String(c!)
                    // let s = String(format: "%02X", c as! CVarArg)
                    tmpVal.append(s)
                    i += 8
                }
                field.strVal = tmpVal.trim()
            } else if binString.count <= 4 || binString.contains("0") {
                // experiment with unavailable: any field >= 5 bits whose value contains only 1's
                var val = 0 // long to avoid craze overflows with 0x8000 ofsets

                if field.isSigned(), binString.hasPrefix("1") {
                    // ugly method: flip bits, add a minus in front and subtract one
                    val = Int("-" + binString.replacingOccurrences(of: "0", with: "q").replacingOccurrences(of: "1", with: "0").replacingOccurrences(of: "q", with: "1"), radix: 2)! - 1
                } else {
                    val = Int("0" + binString, radix: 2)!
                }

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

    func getAsBinaryString(data: String) -> String {
//        var result = ""
//        var data2 = data
//        if data2.count % 2 != 0 {
//            data2 = "0" + data2
//        }
//        result = data2.hexaToBinary

        let hex = data
        let result = hex.compactMap { c -> String? in
            guard let value = Int(String(c), radix: 16) else { return nil }
            let string = String(value, radix: 2)
            return repeatElement("0", count: 4 - string.count) + string
        }.joined()

        return result
    }

    // ELM327 BLE
    // ELM327 BLE
    // ELM327 BLE
    func connectBle() {
        Globals.shared.peripheralsDic = [:]
        // peripheralsArray = []
        Globals.shared.selectedPeripheral = nil
        if blePhase == .DISCOVERED {
            timeoutTimerBle = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
                if Globals.shared.selectedPeripheral == nil {
                    // timeout
                    self.centralManager.stopScan()
                    timer.invalidate()
                    self.disconnect(showToast: false)
                    DispatchQueue.main.async { [self] in
                        view.hideAllToasts()
                        view.makeToast("can't connect to ble device: TIMEOUT")
                    }
                }
            })
        }
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func disconnectBle() {
        if Globals.shared.selectedPeripheral != nil, Globals.shared.selectedPeripheral.blePeripheral != nil {
            if centralManager != nil {
                centralManager.cancelPeripheralConnection(Globals.shared.selectedPeripheral.blePeripheral)
            }
            Globals.shared.selectedPeripheral.blePeripheral = nil
            Globals.shared.selectedService = nil
            Globals.shared.selectedReadCharacteristic = nil
            Globals.shared.selectedWriteCharacteristic = nil
        }
    }

    func writeBle(s: String) {
        if Globals.shared.selectedWriteCharacteristic != nil {
            let ss = s.appending("\r")
            if let data = ss.data(using: .utf8) {
                if Globals.shared.selectedWriteCharacteristic.properties.contains(.write) {
                    Globals.shared.selectedPeripheral.blePeripheral.writeValue(data, for: Globals.shared.selectedWriteCharacteristic, type: .withResponse)
                    debug("> \(s)")
                } else if Globals.shared.selectedWriteCharacteristic.properties.contains(.writeWithoutResponse) {
                    Globals.shared.selectedPeripheral.blePeripheral.writeValue(data, for: Globals.shared.selectedWriteCharacteristic, type: .withoutResponse)
                    debug("> \(s)")
                } else {
                    debug("can't write to characteristic")
                }
            } else {
                debug("data is nil")
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
                                           Globals.shared.deviceWifiAddress as CFString,
                                           UInt32(Globals.shared.deviceWifiPort)!,
                                           &readStream,
                                           &writeStream)

        Globals.shared.inputStream = readStream!.takeRetainedValue()
        Globals.shared.outputStream = writeStream!.takeRetainedValue()

        Globals.shared.inputStream.delegate = self
        Globals.shared.outputStream.delegate = self

        Globals.shared.inputStream.schedule(in: RunLoop.current, forMode: .default)
        Globals.shared.outputStream.schedule(in: RunLoop.current, forMode: .default)

        Globals.shared.inputStream.open()
        Globals.shared.outputStream.open()

        print("inputStream \(decodeStatus(status: Globals.shared.inputStream.streamStatus))")
        print("outputStream \(decodeStatus(status: Globals.shared.outputStream.streamStatus))")

        var contatore = 5
        #if targetEnvironment(simulator)
            contatore = 50
        #endif
        timeoutTimerWifi = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            print(contatore)

            if Globals.shared.inputStream != nil, Globals.shared.outputStream != nil, Globals.shared.inputStream.streamStatus == .open, Globals.shared.outputStream.streamStatus == .open {
                // connesso, disabilita timer timeout connessione
                if self.timeoutTimerWifi != nil {
                    if self.timeoutTimerWifi.isValid {
                        self.timeoutTimerWifi.invalidate()
                    }
                    self.timeoutTimerWifi = nil
                }
                Globals.shared.deviceIsConnected = true
                self.deviceConnected()

                if Globals.shared.inputStream.streamStatus == .open && Globals.shared.outputStream.streamStatus == .open {
                    NotificationCenter.default.post(name: Notification.Name("connected"), object: nil)
                }
            }

            if contatore < 1 {
                // NON connesso
                if self.timeoutTimerWifi != nil {
                    if self.timeoutTimerWifi.isValid {
                        self.timeoutTimerWifi.invalidate()
                    }
                    self.timeoutTimerWifi = nil
                }
                self.disconnectWifi()
                DispatchQueue.main.async { [self] in
                    disconnect(showToast: false)
                    view.hideAllToasts()
                    view.makeToast("TIMEOUT")
                }
                Globals.shared.deviceIsConnected = false
                self.deviceDisconnected()
            }

            contatore -= 1

        })
    }

    func disconnectWifi() {
        Globals.shared.deviceIsConnected = false
        deviceDisconnected()
        if Globals.shared.inputStream != nil {
            Globals.shared.inputStream.close()
            Globals.shared.inputStream.remove(from: RunLoop.current, forMode: .default)
            Globals.shared.inputStream.delegate = nil
            Globals.shared.inputStream = nil
        }
        if Globals.shared.outputStream != nil {
            Globals.shared.outputStream.close()
            Globals.shared.outputStream.remove(from: RunLoop.current, forMode: .default)
            Globals.shared.outputStream.delegate = nil
            Globals.shared.outputStream = nil
        }
    }

    func writeWifi(s: String) {
        if Globals.shared.outputStream != nil, Globals.shared.outputStream.streamStatus == .open {
            let s2 = s.appending("\r")
            let data = s2.data(using: .utf8)!
            data.withUnsafeBytes {
                guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    debug("Error")
                    return
                }
                debug("> \(s)")
                Globals.shared.outputStream.write(pointer, maxLength: data.count)
            }
        }
    }

    @objc func didReceiveFromWifiDongle(notification: Notification) {
        let notificationObject = notification.object as? [String: Any]
        if notificationObject != nil, notificationObject?.keys != nil {
            for k in notificationObject!.keys {
                let reply = notificationObject![k] as! String
                NotificationCenter.default.post(name: Notification.Name("received"), object: ["reply": reply])
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

    // HTTP
    func writeHttp(s: String) {
        var request = URLRequest(url: URL(string: "\(Globals.shared.deviceHttpAddress)\(s)")!, timeoutInterval: 5)
        request.httpMethod = "GET"

        debug("> \(s)")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if error != nil {
                DispatchQueue.main.async { [self] in
                    view.makeToast(error?.localizedDescription)
                }
                return
            }
            if data == nil {
                self.debug("data == nil")
                return
            }
            if var reply = String(data: data!, encoding: .utf8) {
                let a = reply.components(separatedBy: ",")
                if a.count > 0 {
                    reply = a.last!
                }
                if reply.contains("problem") {
                    reply = "ERROR"
                }
                let dic = ["reply": reply]
                NotificationCenter.default.post(name: Notification.Name("received2"), object: dic)
            }
        }
        task.resume()
    }

    func startQueue2() {
        UIApplication.shared.isIdleTimerDisabled = true
        indiceCmd = 0
        lastId = -1
        processQueue2()
    }

    func processQueue2() {
        if queue2.count == 0 {
            print("END queue2")
            UIApplication.shared.isIdleTimerDisabled = false
            NotificationCenter.default.post(name: Notification.Name("endQueue2"), object: nil)
            return
        }

        let seq = queue2.first! as Sequence

        if indiceCmd >= seq.cmd.count {
//            if seq.frame != nil {
//                seq.frame.lastRequest = Date().timeIntervalSince1970
//            }
            if seq.field != nil {
                seq.field.lastRequest = Date().timeIntervalSince1970
            }
            queue2.removeFirst()
            startQueue2()
            return
        }
        if indiceCmd == 0, seq.field != nil {
            let dic = ["debug": "Debug \(seq.field?.sid ?? "?") \(seq.field.name ?? "?")"]
            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
            //  debug(seq.field.sid)
        }

        /*
         // cached ?
                if seq.field != nil {
                    if let res = Globals.shared.resultsBySid[(seq.field.sid)!] {
                        if Date().timeIntervalSince1970 - res.lastTimestamp < 1 { // TEST CACHED
                            debug("cached")

                            let dic = ["debug": "Debug \(seq.field.sid ?? "?") cached"]
                            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)

                            // notify real field
                            var n: [String: String] = [:]
                            n["sid"] = seq.field.sid
                            NotificationCenter.default.post(name: Notification.Name("decoded"), object: n)

                            lastId = -1
                            queue2.removeFirst()
                            startQueue2()
                            return
                        }
                    }
                }
         */

        let cmd = seq.cmd[indiceCmd]
        write(s: cmd)

        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }

        var contatore = 5.0
        #if targetEnvironment(simulator)
            contatore = 50.0
        #endif
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: contatore, repeats: false) { timer in
            timer.invalidate()
            self.debug("queue2 timeout !!!")
            DispatchQueue.main.async { [self] in
                disconnect(showToast: false)
                view.hideAllToasts()
                view.makeToast("TIMEOUT")
            }
            return
        }
    }

    func continueQueue2() {
        indiceCmd += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
            processQueue2()
        }
    }

    @objc func received(notification: Notification) {
//        if queue.count > 0 || queueInit.count > 0 {
        if queueInit.count > 0 {
            if timeoutTimer != nil, timeoutTimer.isValid {
                timeoutTimer.invalidate()
                //    if queue.count > 0 {
                //        continueQueue()
                //    } else
                if queueInit.count > 0 {
                    continueQueueInit()
                }
            }
        } else if queue2.count > 0 {
            var notificationObject = notification.object as! [String: Any]
            var reply = notificationObject["reply"] as! String
            reply = reply.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            notificationObject["reply"] = reply
            if reply == "", Globals.shared.deviceConnection == .WIFI { // prevent "empty" debug errors for wifi devices ?
                // do nothing
            } else {
                NotificationCenter.default.post(name: Notification.Name("received2"), object: notificationObject)
            }
        } else {
            let notificationObject = notification.object as! [String: Any]
            let reply = notificationObject["reply"] as! String
            if reply == "", Globals.shared.deviceConnection == .WIFI {
                // do nothing
            } else {
                debug("< \(reply)")
            }
        }
    }

    @objc func received2(notification: Notification) {
        var error = "ok"
        let notificationObject = notification.object as! [String: Any]
        let reply = notificationObject["reply"] as! String

        debug("< '\(reply)' (\(reply.count))")

        var sid = ""
        if let seq = queue2.first {
            if notificationObject["sid"] != nil {
                sid = notificationObject["sid"] as! String
            } else if seq.field != nil {
                sid = seq.field.sid!
            }

            if sid == "" {
                // firmware

                for field in seq.frame.getAllFields() {
                    if reply.contains("ERROR") {
                        error = "ERROR"
                        debug(error)
                    } else if reply == "OK" {
                        // do nothing
                    } else if reply == "NO DATA" {
                        error = reply
                        debug(error)
                    } else if reply == "" {
                        error = "EMPTY"
                        debug(error)
                    } else if reply.contains("not found") { // http
                        error = "NOT FOUND"
                        debug(error)
                    } else {
                        if Globals.shared.deviceType == .ELM327 {
                            field.strVal = decodeIsoTp(elmResponse2: reply)
                        } else { // http, cansee
                            field.strVal = reply
                        }
                        let binString = getAsBinaryString(data: field.strVal)
                        debug("\(binString) (\(binString.count))")

                        onMessageCompleteEventField(binString_: binString, field: field)

                        if field.isString() || field.isHexString() {
                            debug("\(field.strVal)")
                            Globals.shared.fieldResultsString[field.sid] = field.strVal
                        } else {
                            debug("\(field.name ?? "?") \(String(format: "%.\(field.decimals!)f", field.getValue()))\n")
                            Globals.shared.fieldResultsDouble[field.sid] = field.getValue()
                        }
                        let key = "\(field.frame.getFromIdHex()).\(field.frame.responseId!)"
                        if !Globals.shared.sidFatti.contains(key) {
                            Globals.shared.loggerEmulator.add("case \"\(key)\": // \(field.name ?? "")")
                            Globals.shared.loggerEmulator.add("$RES = \"\(reply)\";")
                            Globals.shared.loggerEmulator.add("break;")
                            Globals.shared.sidFatti.append(key)
                        }
                    }

                    var notificationObject = notification.object as! [String: String]
                    notificationObject["sid"] = field.sid
                    NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)
                    let debugMessage = "Debug \(field.sid ?? "?") \(error) \(field.isString() ? field.strVal : String(format: "%.2f", field.getValue()))"
                    if debugMessage != lastDebugMessage {
                        let dic = ["debug": debugMessage]
                        lastDebugMessage = debugMessage
                        NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
                    }

                    if seq.sidVirtual != nil {
                        notificationObject["sid"] = seq.sidVirtual
                        NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)
                    }
                }

            } else {
                if let field = Fields.getInstance.getBySID(sid) {
                    if reply.contains("ERROR") {
                        error = "ERROR"
                        debug(error)
                    } else if reply == "OK" {
                        // do nothing
                    } else if reply == "NO DATA" {
                        error = reply
                        debug(error)
                    } else if reply == "" {
                        error = "EMPTY"
                        debug(error)
                    } else if reply.contains("not found") { // http
                        error = "NOT FOUND"
                        debug(error)
                    } else {
                        if Globals.shared.deviceType == .ELM327 {
                            field.strVal = decodeIsoTp(elmResponse2: reply) // ""
                        } else { // http, cansee
                            field.strVal = reply
                        }
                        if field.strVal.hasPrefix("7f") {
                            error = "ERROR 7F"
                            debug(error)
                        } else if field.strVal == "" {
                            error = "EMPTY"
                            debug(error)
                        } else if field.strVal.contains("not found"), !field.virtual {
                            error = "NOT FOUND"
                            debug(error)
                        } else {
                            let binString = getAsBinaryString(data: field.strVal)
                            debug("\(binString) (\(binString.count))")

                            for f in field.frame.getAllFields() {
                                onMessageCompleteEventField(binString_: binString, field: f)

                                if f.isString() || f.isHexString() {
//                            debug( "\(field!.strVal)")
                                    Globals.shared.fieldResultsString[f.sid] = f.strVal
                                    Globals.shared.resultsBySid[f.sid] = FieldResult(doubleValue: nil, stringValue: f.strVal)
                                } else if sid == Sid.BatterySerial, f.strVal.count > 6, Globals.shared.car == AppSettings.CAR_ZOE_Q210 {
                                    f.strVal = f.strVal.subString(from: f.strVal.count - 6)
                                    f.strVal = "F" + f.strVal
                                    Globals.shared.fieldResultsString[f.sid] = f.strVal
                                    Globals.shared.resultsBySid[f.sid] = FieldResult(doubleValue: nil, stringValue: f.strVal)
//                            debug( "\(field!.strVal)")
                                } else {
//                            debug( "\(field?.name ?? "?") \(String(format: "%.\(field!.decimals!)f", field!.getValue()))\n")
                                    Globals.shared.fieldResultsDouble[f.sid] = f.getValue()
                                    Globals.shared.resultsBySid[f.sid] = FieldResult(doubleValue: f.getValue(), stringValue: nil)
                                }

                                let debugMessage = "Debug \(f.sid ?? "?") \(error) \(f.isString() ? f.strVal : String(format: "%.2f", f.getValue()))"
                                if debugMessage != lastDebugMessage {
                                    let dic = ["debug": debugMessage]
                                    lastDebugMessage = debugMessage
                                    NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
                                }
                                if error == "ok" {
                                    let key = "\(f.frame.getFromIdHex()).\(f.frame.responseId!)"
                                    if !Globals.shared.sidFatti.contains(key) {
                                        Globals.shared.loggerEmulator.add("case \"\(key)\": // \(f.name ?? "")")
                                        Globals.shared.loggerEmulator.add("$RES = \"\(reply)\";")
                                        Globals.shared.loggerEmulator.add("break;")
                                        Globals.shared.sidFatti.append(key)
                                    }
                                }

                                // notify real field
                                var notificationObject = notification.object as! [String: String]
                                notificationObject["sid"] = f.sid
                                NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)

                                if seq.sidVirtual != nil {
                                    var result = Double.nan
                                    switch seq.sidVirtual {
                                    case Sid.Instant_Consumption: // 800.6100.24
                                        // get real speed
                                        if let realSpeed = Globals.shared.fieldResultsDouble[Sid.RealSpeed] {
                                            if realSpeed < 0 || realSpeed > 150 {
                                                break
                                            }
                                            if realSpeed < 5 {
                                                result = 0
                                                break
                                            }
                                            // get voltage
                                            if let dcVolt = Globals.shared.fieldResultsDouble[Sid.TractionBatteryVoltage] {
                                                // get current
                                                if let dcCur = Globals.shared.fieldResultsDouble[Sid.TractionBatteryCurrent] {
                                                    if dcVolt < 300 || dcVolt > 450 || dcCur < -200 || dcCur > 100 {
                                                        break
                                                    }
                                                    // power in kW
                                                    let dcPwr = dcVolt * dcCur / 1000.0
                                                    let usage = -(round(1000.0 * dcPwr / realSpeed) / 10.0)
                                                    if usage < -150 {
                                                        result = -150
                                                    } else if usage > 150 {
                                                        result = 150
                                                    } else {
                                                        result = usage
                                                    }
                                                }
                                            }
                                        }
                                    case Sid.FrictionTorque:
                                        if let val = Globals.shared.fieldResultsDouble[Sid.HydraulicTorqueRequest] {
                                            result = -val
                                        }
                                    case Sid.DcPowerIn:
                                        if Globals.shared.fieldResultsDouble[Sid.TractionBatteryVoltage] != nil, Globals.shared.fieldResultsDouble[Sid.TractionBatteryCurrent] != nil, !Globals.shared.fieldResultsDouble[Sid.TractionBatteryVoltage]!.isNaN, !Globals.shared.fieldResultsDouble[Sid.TractionBatteryCurrent]!.isNaN {
                                            result = Globals.shared.fieldResultsDouble[Sid.TractionBatteryVoltage]! * Globals.shared.fieldResultsDouble[Sid.TractionBatteryCurrent]! / 1000.0
                                        }
                                    case Sid.DcPowerOut:
                                        if Globals.shared.fieldResultsDouble[Sid.TractionBatteryVoltage] != nil, Globals.shared.fieldResultsDouble[Sid.TractionBatteryCurrent] != nil, !Globals.shared.fieldResultsDouble[Sid.TractionBatteryCurrent]!.isNaN {
                                            result = Globals.shared.fieldResultsDouble[Sid.TractionBatteryVoltage]! * Globals.shared.fieldResultsDouble[Sid.TractionBatteryCurrent]! / -1000.0
                                        }
                                    case Sid.ElecBrakeTorque:
                                        if Globals.shared.useIsoTpFields || Utils.isPh2() {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.PEBTorque] {
                                                let electricTorque = val * Globals.reduction
                                                result = electricTorque <= 0 ? -electricTorque : 0
                                            }
                                        } else {
                                            if let val1 = Globals.shared.fieldResultsDouble[Sid.ElecBrakeWheelsTorqueApplied] {
                                                let electricTorque = val1
                                                if let val2 = Globals.shared.fieldResultsDouble[Sid.Coasting_Torque] {
                                                    result = electricTorque + val2 * Globals.reduction
                                                }
                                            }
                                        }
                                    case Sid.TotalPositiveTorque:
                                        if Globals.shared.useIsoTpFields || Utils.isPh2() {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.PEBTorque] {
                                                result = val >= 0 ? val * Globals.reduction : 0
                                            }
                                        } else {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.MeanEffectiveTorque] {
                                                result = val * Globals.reduction
                                            }
                                        }
                                    case Sid.TotalNegativeTorque:
                                        if Globals.shared.useIsoTpFields || Utils.isPh2() {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.HydraulicTorqueRequest] {
                                                let hydraulicTorqueRequest = val
                                                if let val2 = Globals.shared.fieldResultsDouble[Sid.PEBTorque] {
                                                    let pebTorque = val2
                                                    result = pebTorque <= 0 ? -hydraulicTorqueRequest - pebTorque * Globals.reduction : -hydraulicTorqueRequest
                                                }
                                            }
                                        } else {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.DriverBrakeWheel_Torque_Request] {
                                                result = val
                                            }
                                        }
                                    case Sid.ACPilot:
                                        if Globals.shared.useIsoTpFields || Utils.isPh2() {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.ACPilotDutyCycle] {
                                                let dutyCycle = val
                                                result = dutyCycle < 80.0 ? dutyCycle * 0.6 : (dutyCycle - 64.0) * 2.5
                                            }
                                        } else {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.ACPilotAmps] {
                                                result = val
                                            }
                                        }
                                    case "800.6104.24": //  SID_VirtualUsage
                                        let SID_VirtualUsage = "800.6100.24"
                                        if let value = Globals.shared.fieldResultsDouble[SID_VirtualUsage] {
                                            // if !value.isNaN {
                                            let now = Date().timeIntervalSince1970
                                            var since = now - Fields.getInstance.start
                                            if since > 1000 {
                                                since = 1000 // use a maximim of 1 second
                                            }
                                            Fields.getInstance.start = now
                                            let factor = since * 0.00005 // 0.05 per second
                                            Fields.getInstance.runningUsage = Fields.getInstance.runningUsage * (1 - factor) + value * factor
                                            // }
                                            result = Fields.getInstance.runningUsage
                                        }
                                    case "800.6102.24": // FrictionPower
                                        let SID_DriverBrakeWheel_Torque_Request = "130.44" // UBP braking wheel torque the driver wants
                                        let SID_ElecBrakeWheelsTorqueApplied = "1f8.28" // 10ms
                                        let SID_ElecEngineRPM = "1f8.40" // 10ms
                                        if let val = Globals.shared.fieldResultsDouble[SID_DriverBrakeWheel_Torque_Request] {
                                            var torque = val
                                            if let val2 = Globals.shared.fieldResultsDouble[SID_ElecBrakeWheelsTorqueApplied] {
                                                torque -= val2
                                                if let val3 = Globals.shared.fieldResultsDouble[SID_ElecEngineRPM] {
                                                    result = torque * val3 / Globals.reduction
                                                }
                                            }
                                        }
                                    case "800.6105.24": // HeaterSetpoint
                                        if Utils.isPh2() {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.OH_ClimTempDisplay] {
                                                if val == 0 {
                                                } else if val == 4 {
                                                    result = -10.0
                                                } else if val == 5 {
                                                    result = 40.0
                                                }
                                                result = val
                                            }
                                        } else if Globals.shared.useIsoTpFields {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.OH_ClimTempDisplay] {
                                                let value = val / 2
                                                if value == 0 {
                                                } else if value == 4 {
                                                    result = -10.0
                                                } else if value == 5 {
                                                    result = 40.0
                                                }
                                                result = value
                                            }
                                        } else {
                                            if let val = Globals.shared.fieldResultsDouble[Sid.HeaterSetpoint] {
                                                if val == 0 {
                                                } else if val == 4 {
                                                    result = -10.0
                                                } else if val == 5 {
                                                    result = 40.0
                                                }
                                                result = val
                                            }
                                        }
                                    case "800.6106.24": // RealRange
                                        if let odo = Globals.shared.fieldResultsDouble[Sid.EVC_Odometer] {
                                            if let gom = Globals.shared.fieldResultsDouble[Sid.RangeEstimate] {
                                                // timestamp of last inserted dot in MILLISECONDS
                                                if let lastInsertedTime = Globals.shared.lastTime[Sid.RangeEstimate] {
                                                    if Date().timeIntervalSince1970 * 1000 - lastInsertedTime > 15 * 60 * 1000 || Fields.getInstance.realRangeReference.isNaN { // timeout of 15 minutes
                                                        if !gom.isNaN && !odo.isNaN {
                                                            Fields.getInstance.realRangeReference = odo + gom
                                                            Fields.getInstance.realRangeReference2 = odo + gom
                                                        }
                                                    }
                                                }
                                                if Fields.getInstance.realRangeReference.isNaN {
                                                    result = 0.0 // Double.NaN
                                                }
                                                /*
                                                 double delta = realRangeReference - odo - gom;
                                                 if (delta > 12.0 || delta < -12.0) {
                                                     realRangeReference = odo + gom;
                                                 } */
                                                result = Fields.getInstance.realRangeReference - odo
                                            }
                                        }
                                    case "800.6107.24": // RealDelta
                                        if let val1 = Globals.shared.fieldResultsDouble[Sid.EVC_Odometer] {
                                            let odo = val1
                                            if let val2 = Globals.shared.fieldResultsDouble[Sid.RangeEstimate] {
                                                let gom = val2
                                                // MainActivity.debug("realRange ODO: "+odo);
                                                // MainActivity.debug("realRange GOM: "+gom);
                                                // timestamp of last inserted dot in MILLISECONDS
                                                if let lastInsertedTime = Globals.shared.lastTime[Sid.RangeEstimate] {
                                                    if Date().timeIntervalSince1970 * 1000 - lastInsertedTime > 15 * 60 * 1000 || Fields.getInstance.realRangeReference.isNaN { // timeout of 15 minutes
                                                        if !gom.isNaN && !odo.isNaN {
                                                            Fields.getInstance.realRangeReference = odo + gom
                                                        }
                                                    }
                                                    if Fields.getInstance.realRangeReference.isNaN {
                                                        // return Double.NaN;
                                                        break
                                                    }
                                                    var delta = Fields.getInstance.realRangeReference - odo - gom
                                                    if delta > 12.0 || delta < -12.0 {
                                                        Fields.getInstance.realRangeReference = odo + gom
                                                        delta = 0.0
                                                    }
                                                    result = delta
                                                }
                                            }
                                        }
                                    case "800.6108.24": // RealDeltaNoReset
                                        if let odo = Globals.shared.fieldResultsDouble[Sid.EVC_Odometer] {
                                            if let gom = Globals.shared.fieldResultsDouble[Sid.RangeEstimate] {
                                                // MainActivity.debug("realRange ODO: "+odo);
                                                // MainActivity.debug("realRange GOM: "+gom);

                                                // timestamp of last inserted dot in MILLISECONDS
                                                if let lastInsertedTime = Globals.shared.lastTime[Sid.RangeEstimate] {
                                                    if Date().timeIntervalSince1970 * 1000 - lastInsertedTime > 15 * 60 * 1000 || Fields.getInstance.realRangeReference2.isNaN { // timeout of 15 minutes
                                                        if !gom.isNaN && !odo.isNaN {
                                                            Fields.getInstance.realRangeReference2 = odo + gom
                                                        }
                                                    }
                                                    if Fields.getInstance.realRangeReference2.isNaN {
//                                             return Double.NaN;
                                                        break
                                                    }
                                                    var delta = Fields.getInstance.realRangeReference2 - odo - gom
                                                    if delta > 500.0 || delta < -500.0 {
                                                        Fields.getInstance.realRangeReference2 = odo + gom
                                                        delta = 0.0
                                                    }
                                                    result = delta
                                                }
                                            }
                                        }

                                    default:
                                        print("unknown virtual sid")
                                    }
                                    if result != Double.nan {
                                        Globals.shared.fieldResultsDouble[seq.sidVirtual!] = result
                                        Globals.shared.resultsBySid[f.sid] = FieldResult(doubleValue: f.getValue(), stringValue: nil)
                                    }
                                    let debugMessage = "Debug \(f.sid ?? "?") \(error) \(f.isString() ? f.strVal : String(format: "%.2f", f.getValue()))"
                                    if debugMessage != lastDebugMessage {
                                        let dic = ["debug": debugMessage]
                                        lastDebugMessage = debugMessage
                                        NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
                                    }

                                    // notify real field
                                    var notificationObject = notification.object as! [String: String]
                                    notificationObject["sid"] = f.sid
                                    NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)

                                    // notify virtual
                                    if seq.sidVirtual != nil {
                                        notificationObject["sid"] = seq.sidVirtual
                                        NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)

                                        let debugMessage = "Debug \(seq.sidVirtual ?? "")"
                                        if debugMessage != lastDebugMessage {
                                            let dic = ["debug": debugMessage]
                                            lastDebugMessage = debugMessage
                                            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    let debugMessage = "Debug \(field.sid ?? "?") \(error) \(field.isString() ? field.strVal : String(format: "%.2f", field.getValue()))"
                    if debugMessage != lastDebugMessage {
                        let dic = ["debug": debugMessage]
                        lastDebugMessage = debugMessage
                        NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
                    }

                    // notify real field
                    var notificationObject = notification.object as! [String: String]
                    notificationObject["sid"] = field.sid
                    NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)

                    // notify virtual
                    if seq.sidVirtual != nil {
                        notificationObject["sid"] = seq.sidVirtual
                        NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)
                    }
                }
            }
        } else { // if let seq = queue2.first
            return
        }

        if queue2.count > 0, timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
            continueQueue2()
        }
    }

    func processQueueInit() {
        if queueInit.count == 0 {
            print("END")
            Globals.shared.deviceIsInitialized = true
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
            return
        }
        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        write(s: queueInit.first!)
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            print("queue timeout !!!")
            timer.invalidate()
            return
        }
    }

    func continueQueueInit() {
        if queueInit.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
                queueInit.remove(at: 0)
                processQueueInit()
            }
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
