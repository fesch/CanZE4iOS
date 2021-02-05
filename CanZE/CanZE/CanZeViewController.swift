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
    let maxReadLength = 4096
    var timeoutTimerWifi: Timer!

    // BLE
    var centralManager: CBCentralManager!
    var timeoutTimerBle: Timer!

    // init elm327
    let autoInitElm327: [String] = ["ate0", "ats0", "ath0", "atl0", "atal", "atcaf0", "atfcsh77b", "atfcsd300000", "atfcsm1", "atsp6"]

    var timeoutTimer: Timer!

    // queue
    var queue: [String] = []
    var queueInit: [String] = []
    var queue2: [Sequence] = []
    var indiceCmd = 0
    var lastRxString = ""
    var lastId = -1

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

        let vBG = view.viewWithTag(vBG_TAG)
        if vBG != nil {
            vBG?.removeFromSuperview()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queue2 = []

        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        if timeoutTimerBle != nil, timeoutTimerBle.isValid {
            timeoutTimerBle.invalidate()
        }
        if timeoutTimerWifi != nil, timeoutTimerWifi.isValid {
            timeoutTimerWifi.invalidate()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("didReceiveFromWifiDongle"), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceDisconnected"), object: nil)

        NotificationCenter.default.removeObserver(self, name: Notification.Name("received"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
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

    func debug(_ s: String) {
        print(s)
        Globals.shared.logger.add(s: s)
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
            let vBG = view.viewWithTag(vBG_TAG)
            if vBG != nil {
                vBG?.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
        }
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

        let vBG = view.viewWithTag(vBG_TAG)
        if vBG != nil {
            vBG?.removeFromSuperview()
        }

        view.makeToast("connected and initialized")
    }

    func deviceIsConnectable() -> Bool {
        var connectable = false
        if Globals.shared.deviceType == .ELM327 || Globals.shared.deviceType == .CANSEE || Globals.shared.deviceType == .HTTP {
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
        case .HTTP:
            print("DEVICE_TYPE_HTTP")
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

        /*
         Globals.shared.dataExportMode = false
                 if ud.exists(key: SETTING_LOGGING_USE_SD_CARD) {
         Globals.shared.dataExportMode = ud.bool(forKey: SETTING_LOGGING_USE_SD_CARD)
                 }

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
            view.makeToast("please configure")
            return
        }

        print("connecting")

        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        vBG.tag = vBG_TAG
        view.addSubview(vBG)

        view.hideAllToasts()
        view.makeToast("_connecting, wait for initialize")

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
            let vBG = view.viewWithTag(vBG_TAG)
            if vBG != nil {
                vBG?.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
            return
        default:
            break
        }

        if Globals.shared.deviceType == .CANSEE {
            Globals.shared.deviceIsConnected = true
            Globals.shared.deviceIsInitialized = true
            deviceConnected()
            let vBG = view.viewWithTag(vBG_TAG)
            if vBG != nil {
                vBG?.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
        }
    }

    func disconnect(showToast: Bool) {
        print("disconnecting")
        if showToast {
            DispatchQueue.main.async {
                self.view.hideAllToasts()
                self.view.makeToast("_disconnecting")
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
        fieldResultsDouble = [:]
        fieldResultsString = [:]

        let vBG = view.viewWithTag(vBG_TAG)
        if vBG != nil {
            vBG?.removeFromSuperview()
        }
    }

    func processQueue() {
        if !Globals.shared.deviceIsConnected {
            print("can't continue, device not connected")
            return
        }

        if queue.count == 0 {
            print("END")
            NotificationCenter.default.post(name: Notification.Name("endQueue"), object: nil)
            return
        }

        write(s: queue.first!)

        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            print("queue timeout !!!")
            timer.invalidate()
            return
        }
    }

    func continueQueue() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if self.queue.count > 0 {
                self.queue.remove(at: 0)
                self.processQueue()
            }
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
            requestFreeFrame(frame: frame)
        }
    }

    func addField(_ sid: String, intervalMs: Int) {
        let field = Fields.getInstance.getBySID(sid)
        if field != nil {
            if field!.responseId != "999999" {
                if field!.virtual {
                    let virtualField = Fields.getInstance.getBySID(field!.sid) as! VirtualField
                    let fields = virtualField.getFields()
                    for f in fields {
                        if f.responseId != "999999" {
                            requestIsoTpFrame(frame2: (f.frame)!, field: f, virtual: field!.sid)
                        }
                    }
                } else {
                    requestIsoTpFrame(frame2: (field?.frame)!, field: field!, virtual: nil)
                }
            }
//        } else {
//            MainActivity.debug(this.getClass().getSimpleName() + " (CanzeActivity): SID " + sid + " does not exist in class Fields");
//            MainActivity.toast(MainActivity.TOAST_NONE, String.format(Locale.getDefault(), MainActivity.getStringSingle(R.string.format_NoSid), this.getClass().getSimpleName(), sid));
        }
    }

    func requestFreeFrame(frame: Frame) {
        //  var command = ""
        switch Globals.shared.deviceType {
        case .ELM327:

            // TODO:

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

        case .HTTP, .CANSEE:
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
        if frame.sendingEcu.fromId == 0x18DAF1DA, frame.responseId == "5003" {
            let ecu = Ecus.getInstance.getByFromId(fromId: 0x18DAF1D2)
            frame.sendingEcu = ecu
            frame.fromId = ecu.fromId
        }
        // TEST
        // TEST

        let seq = Sequence()

        if virtual != nil {
            seq.sidVirtual = virtual
        }

        seq.frame = frame
        seq.field = field

        if Globals.shared.deviceType == .HTTP {
            let s = "?command=i\(String(format: "%02x", frame.fromId)),\(frame.getRequestId()),\(frame.responseId ?? "")"
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
            if next == 15 {
                next = 0
            } else {
                next += 1
            }
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

        debug("decodeIsoTp \(hexData.lowercased())")

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
                    let nn = Int(n, radix: 2)!
                    let c = UnicodeScalar(nn)
                    let s = String(c!)
                    // let s = String(format: "%02X", c as! CVarArg)
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
                    self.view.hideAllToasts()
                    self.view.makeToast("can't connect to ble device: TIMEOUT")
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
            let data = ss.data(using: .utf8)
            if data != nil {
                if Globals.shared.selectedWriteCharacteristic.properties.contains(.write) {
                    Globals.shared.selectedPeripheral.blePeripheral.writeValue(data!, for: Globals.shared.selectedWriteCharacteristic, type: .withResponse)
                    debug("> \(s)")
                } else if Globals.shared.selectedWriteCharacteristic.properties.contains(.writeWithoutResponse) {
                    Globals.shared.selectedPeripheral.blePeripheral.writeValue(data!, for: Globals.shared.selectedWriteCharacteristic, type: .withoutResponse)
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
            contatore = 500000
        #endif
        timeoutTimerWifi = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            print(contatore)

            if Globals.shared.inputStream != nil, Globals.shared.outputStream != nil, Globals.shared.inputStream.streamStatus == .open, Globals.shared.outputStream.streamStatus == .open {
                // connesso
                self.timeoutTimerWifi.invalidate()
                self.timeoutTimerWifi = nil
                Globals.shared.deviceIsConnected = true
                self.deviceConnected()

                if Globals.shared.inputStream.streamStatus == .open && Globals.shared.outputStream.streamStatus == .open {
                    NotificationCenter.default.post(name: Notification.Name("connected"), object: nil)
                }
            }

            if contatore < 1 {
                // NON connesso
                self.timeoutTimerWifi.invalidate()
                self.timeoutTimerWifi = nil
                self.disconnectWifi()
                DispatchQueue.main.async {
                    self.disconnect(showToast: false)
                    self.view.hideAllToasts()
                    self.view.makeToast("TIMEOUT")
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
        if Globals.shared.outputStream != nil {
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
        let dic = notification.object as? [String: Any]
        if dic != nil, dic?.keys != nil {
            for k in dic!.keys {
                let ss = dic![k] as! String
                NotificationCenter.default.post(name: Notification.Name("received"), object: ["tag": ss])
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
            guard let data = data else {
                print(error?.localizedDescription ?? "?")
                self.view.makeToast(error?.localizedDescription)
                return
            }
            let reply = String(data: data, encoding: .utf8)
            let reply2 = reply?.components(separatedBy: ",")
            if reply2?.count == 2 {
                var reply3 = reply2?.last
                if reply3!.contains("problem") {
                    reply3 = "ERROR"
                }
                let dic = ["tag": reply3]
                NotificationCenter.default.post(name: Notification.Name("received2"), object: dic)
            } else {
                self.debug(reply!)
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
            queue2.removeFirst()
            startQueue2()
            return
        }
        if indiceCmd == 0, seq.field != nil {
            let dic = ["debug": "Debug \(seq.field?.sid ?? "?")"]
            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
            //  debug(seq.field.sid)
        }

        let cmd = seq.cmd[indiceCmd]
        write(s: cmd)

        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }

        var contatore = 5.0
        #if targetEnvironment(simulator)
            contatore = 500000.0
        #endif
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: contatore, repeats: false) { timer in
            timer.invalidate()
            self.debug("queue2 timeout !!!")
            DispatchQueue.main.async {
                self.disconnect(showToast: false)
                self.view.hideAllToasts()
                self.view.makeToast("TIMEOUT")
            }
            return
        }
    }

    func continueQueue2() {
        indiceCmd += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.processQueue2()
        }
    }
}

// MARK: StreamDelegate

// wifi
extension CanZeViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if aStream == Globals.shared.inputStream {
                readAvailableBytes(stream: aStream as! InputStream)
            }
        case .endEncountered:
            debug("\(aStream) endEncountered")
        case .hasSpaceAvailable:
            if aStream == Globals.shared.outputStream {}
        case .errorOccurred:
            debug("\(aStream) errorOccurred")
        case .openCompleted:
            debug("\(aStream) openCompleted")
        default:
            debug("\(aStream) \(eventCode.rawValue)")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = Globals.shared.inputStream.read(buffer, maxLength: maxReadLength)
            if numberOfBytesRead < 0, let error = stream.streamError {
                debug(error.localizedDescription)
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

    @objc func received(notification: Notification) {
        if queue.count > 0 || queueInit.count > 0 {
            if timeoutTimer != nil, timeoutTimer.isValid {
                timeoutTimer.invalidate()
                if queue.count > 0 {
                    continueQueue()
                } else if queueInit.count > 0 {
                    continueQueueInit()
                }
            }
        } else if queue2.count > 0 {
            NotificationCenter.default.post(name: Notification.Name("received2"), object: notification.object)
        } else {
            let dic = notification.object as! [String: Any]
            let ss = dic["tag"] as! String
            debug("< \(ss)")
        }
    }

    @objc func received2(notification: Notification) {
        var error = "ok"
        let dic = notification.object as! [String: Any]
        let reply = dic["tag"] as! String

        debug("< '\(reply)' (\(reply.count))")

        var sid = ""
        let seq = queue2.first
        if seq == nil {
            return
        }
        if dic["sid"] != nil {
            sid = dic["sid"] as! String
        } else if seq?.field != nil {
            sid = (seq?.field.sid)!
        }
        if sid == "" {
            // firmware

            let binString = getAsBinaryString(data: reply)
            debug("\(binString) (\(binString.count))")

            for field in seq!.frame.getAllFields() {
                onMessageCompleteEventField(binString_: binString, field: field)

                if field.isString() || field.isHexString() {
                    debug("\(field.strVal)")
                    fieldResultsString[field.sid] = field.strVal
                } else if sid == Sid.BatterySerial, field.strVal != "", field.strVal.count > 6, Globals.shared.car == AppSettings.CAR_ZOE_Q210 {
                    field.strVal = field.strVal.subString(from: field.strVal.count - 6)
                    field.strVal = "F" + field.strVal
                    fieldResultsString[field.sid] = field.strVal
                    debug("\(field.strVal)")
                } else {
                    debug("\(field.name ?? "?") \(String(format: "%.\(field.decimals!)f", field.getValue()))\n")
                    fieldResultsDouble[field.sid] = field.getValue()
                }

                var n = notification.object as! [String: String]
                n["sid"] = field.sid
                if seq?.sidVirtual != nil {
                    n["sid"] = seq?.sidVirtual
                }
                NotificationCenter.default.post(name: Notification.Name("decoded"), object: n)

                let dic = ["debug": "Debug \(field.sid ?? "?") \(error)"]
                NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
            }

        } else {
            let field = Fields.getInstance.getBySID(sid)

            if reply.contains("ERROR") {
                // do nothing
                error = "ERROR"
                debug(error)
            } else if reply == "OK" {
                // do nothing
            } else if reply == "" {
                error = "EMPTY"
                debug(error)
            } else if field != nil {
                if Globals.shared.deviceType == .ELM327 {
                    field?.strVal = decodeIsoTp(elmResponse2: reply) // ""
                } else {
                    // http, cansee
                    field?.strVal = reply
                }

                if field!.strVal.hasPrefix("7f") {
                    error = "ERROR 7F"
                    debug(error)
                } else if field!.strVal == "" {
                    error = "EMPTY"
                    debug(error)
                } else if field!.strVal.contains("not found") {
                    error = "NOT FOUND"
                    debug(error)
                } else {
                    let binString = getAsBinaryString(data: field!.strVal)
                    debug("\(binString) (\(binString.count))")

                    for f in field!.frame.getAllFields() {
                        onMessageCompleteEventField(binString_: binString, field: f)

                        if seq?.sidVirtual != nil {
                            var result = 0.0
                            switch seq?.sidVirtual {
                            case Sid.Instant_Consumption:
                                break
                            case Sid.FrictionTorque:
                                break
                            case Sid.DcPowerIn:
                                if fieldResultsDouble[Sid.TractionBatteryVoltage] != nil, fieldResultsDouble[Sid.TractionBatteryCurrent] != nil, !fieldResultsDouble[Sid.TractionBatteryVoltage]!.isNaN, !fieldResultsDouble[Sid.TractionBatteryCurrent]!.isNaN {
                                    result = fieldResultsDouble[Sid.TractionBatteryVoltage]! * fieldResultsDouble[Sid.TractionBatteryCurrent]! / 1000.0
                                }
                            case Sid.DcPowerOut:
                                if fieldResultsDouble[Sid.TractionBatteryVoltage] != nil, fieldResultsDouble[Sid.TractionBatteryCurrent] != nil, !fieldResultsDouble[Sid.TractionBatteryVoltage]!.isNaN, !fieldResultsDouble[Sid.TractionBatteryCurrent]!.isNaN {
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
//                            debug( "\(field!.strVal)")
                            fieldResultsString[field!.sid] = field!.strVal
                        } else if sid == Sid.BatterySerial, field?.strVal != nil, (field?.strVal.count)! > 6, Globals.shared.car == AppSettings.CAR_ZOE_Q210 {
                            field?.strVal = (field?.strVal.subString(from: (field?.strVal.count)! - 6))!
                            field?.strVal = "F" + field!.strVal
                            fieldResultsString[field!.sid] = field!.strVal
//                            debug( "\(field!.strVal)")
                        } else {
//                            debug( "\(field?.name ?? "?") \(String(format: "%.\(field!.decimals!)f", field!.getValue()))\n")
                            fieldResultsDouble[field!.sid] = field!.getValue()
                        }
                    }
                }
            }

            let dic = ["debug": "Debug \(field?.sid ?? "?") \(error)"]
            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)

            var n = notification.object as! [String: String]
            n["sid"] = field!.sid
            if seq?.sidVirtual != nil {
                n["sid"] = seq?.sidVirtual
            }
            NotificationCenter.default.post(name: Notification.Name("decoded"), object: n)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.queueInit.remove(at: 0)
                self.processQueueInit()
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
            debug("central.state is .unknown")
        case .resetting:
            debug("central.state is .resetting")
        case .unsupported:
            debug("central.state is .unsupported")
        case .unauthorized:
            debug("central.state is .unauthorized")
        case .poweredOff:
            debug("central.state is .poweredOff")
        case .poweredOn:
            debug("central.state is .poweredOn")
            //            centralManager.scanForPeripherals(withServices: [serviceCBUUID])
            centralManager.scanForPeripherals(withServices: [])
        @unknown default:
            debug("central.state is unknown")
        }
    }

    // Peripheral
    // Peripheral
    // Peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let p = BlePeripheral()
        p.blePeripheral = peripheral
        p.rssi = RSSI
        Globals.shared.peripheralsDic[peripheral.identifier.uuidString] = p

        if blePhase == .DISCOVERED, Globals.shared.deviceBlePeripheralName == p.blePeripheral.name {
            timeoutTimerBle.invalidate()
            centralManager.stopScan()
            p.blePeripheral.delegate = self
            Globals.shared.selectedPeripheral = p
            debug("found selected Peripheral \(Globals.shared.selectedPeripheral.blePeripheral.name ?? "")")
            centralManager.connect(Globals.shared.selectedPeripheral.blePeripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debug("didConnect \(peripheral.name ?? "?") \(peripheral.identifier.uuidString)")
        Globals.shared.servicesArray = []
        pickerPhase = .SERVICES
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debug("didFailToConnect \(peripheral) \(error?.localizedDescription ?? "")")
    }

    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        debug("connectionEventDidOccur \(peripheral)")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debug("didDisconnectPeripheral \(peripheral.name ?? "")")
    }

    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {}
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
        Globals.shared.servicesArray.append(contentsOf: peripheral.services ?? [])

        if blePhase == .DISCOVERED {
            for s in Globals.shared.servicesArray {
                if s.uuid.uuidString == Globals.shared.deviceBleServiceUuid {
                    Globals.shared.selectedService = s
                    debug("found selected service \(Globals.shared.selectedService.uuid)")
                    Globals.shared.characteristicArray = []
                    Globals.shared.selectedPeripheral.blePeripheral.discoverCharacteristics([Globals.shared.selectedService.uuid], for: Globals.shared.selectedService)
                    break
                }
            }
        }
    }

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
        if service.characteristics != nil, service.characteristics!.count > 0 {
            Globals.shared.characteristicArray.append(contentsOf: service.characteristics ?? [])

            if blePhase == .DISCOVERED {
                for c in Globals.shared.characteristicArray {
//                    print(c.uuid.uuidString)
                    if c.uuid.uuidString == Globals.shared.deviceBleWriteCharacteristicUuid {
                        Globals.shared.selectedWriteCharacteristic = c
                        debug("found selected write characteristic \(c.uuid)")
                    }
                    if c.uuid.uuidString == Globals.shared.deviceBleReadCharacteristicUuid {
                        Globals.shared.selectedReadCharacteristic = c
                        debug("found selected notify characteristic \(c.uuid)")
                        if c.properties.contains(.notify) {
                            Globals.shared.selectedPeripheral.blePeripheral.setNotifyValue(true, for: c)
                        }
                    }

                    if Globals.shared.selectedReadCharacteristic != nil, Globals.shared.selectedWriteCharacteristic != nil {
                        NotificationCenter.default.post(name: Notification.Name("connected"), object: nil)
                        Globals.shared.deviceIsConnected = true
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
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        } else if characteristic.uuid.uuidString == Globals.shared.selectedReadCharacteristic.uuid.uuidString {
            let s = String(data: characteristic.value!, encoding: .utf8)
            if s?.last == ">" {
                lastRxString += s!

                var ss = lastRxString.trimmingCharacters(in: .whitespacesAndNewlines)
                ss = String(ss.filter { !">".contains($0) })
                ss = String(ss.filter { !"\r".contains($0) })

                NotificationCenter.default.post(name: Notification.Name("received"), object: ["tag": ss])
                lastRxString = ""
            } else {
                lastRxString += s ?? ""
            }
        } else {
            print("received dati da char sconosciuta \(characteristic.uuid.uuidString)")
        }
    }

    // Descriptors
    // Descriptors
    // Descriptors
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            debug(error!.localizedDescription)
        } else {
            let s = "didDiscoverDescriptorsFor \(characteristic.uuid)"
            debug(s)
            debug("characteristic.descriptors \(characteristic.descriptors!)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {}

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            debug("error didUpdateNotificationStateFor characteristic \(characteristic.uuid.uuidString): \(error?.localizedDescription as Any)")
        } else {
            let s = "didUpdateNotificationStateFor \(characteristic.uuid)"
            debug(s)
        }
    }
}
