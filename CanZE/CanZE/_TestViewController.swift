//
//  TestViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 22/12/20.
//

import CoreBluetooth
import SystemConfiguration
import UIKit

class _TestViewController: UIViewController {
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
    
    var blePhase: BlePhase = .DISCOVER
    
    var arraySequenze: [Sequence] = []
    
    @IBOutlet var seg: UISegmentedControl!
    @IBOutlet var tf: UITextField!
    @IBOutlet var tv: UITextView!
    
    @IBOutlet var pickerView: UIView!
    @IBOutlet var picker: UIPickerView!
    @IBOutlet var btn_PickerCancel: UIButton!
    @IBOutlet var btn_PickerDone: UIButton!
    var tmpPickerIndex = 0
    
    let ud = UserDefaults.standard
    
    var centralManager: CBCentralManager!
    var peripheralsDic: [String: BlePeripheral]!
    var selectedPeripheral: BlePeripheral!
    var selectedService: CBService!
    var selectedWriteCharacteristic: CBCharacteristic!
    var selectedReadCharacteristic: CBCharacteristic!
    var timeoutTimerBle: Timer!
    
    var peripheralsArray: [BlePeripheral] = []
    var servicesArray: [CBService] = []
    var characteristicArray: [CBCharacteristic] = []
    
    // WIFI
    var inputStream: InputStream!
    var outputStream: OutputStream!
    let maxReadLength = 4096
    var timeoutTimerWifi: Timer!
    var incompleteReply = ""
    var repliesAddedCounter = 0

    let test: [String] = ["atz", "ate0", "ats0", "atsp6", "atat1", "atcaf0", "atsh7e4", "atfcsh7e4", "03222006", "atcra699", "atma", "atar", "!?"] // , "!atz!ate0!ats0!atsp6!atat1"]
    var indiceTest = 0
    
    // queue
    let autoInitElm327: [String] = ["ate0", "ats0", "ath0", "atl0", "atal", "atcaf0", "atfcsh77b", "atfcsd300000", "atfcsm1", "atsp6"]
    var queue: [String] = []
    var timeoutTimer: Timer!
    var lastRxString = ""
    var lastId = -1
    
    // queue2
    var queue2: [Sequence] = []
    var indiceCmd = 0
    
    var fieldResult: [String: Double] = [:]
    
    var deviceIsInitialized = false

    @IBAction func deviceType() {
        if seg.selectedSegmentIndex == 0 {
            Globals.shared.deviceType = .ELM327
            Globals.shared.deviceConnection = .BLE
        } else if seg.selectedSegmentIndex == 1 {
            Globals.shared.deviceType = .ELM327
            Globals.shared.deviceConnection = .WIFI
        } else if seg.selectedSegmentIndex == 2 {
            Globals.shared.deviceType = .CANSEE
            Globals.shared.deviceConnection = .WIFI
        } else {
            Globals.shared.deviceType = .HTTP_GW
            Globals.shared.deviceConnection = .HTTP
        }
        btnDisconnect()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(received(notification:)), name: Notification.Name("received"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(received2(notification:)), name: Notification.Name("received2"), object: nil)
        
        deviceType()
        
        title = "TEST !"
        
        // Do any additional setup after loading the view.
        
        // title = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        
        /*
         // da mostrare solo se non pagina singola
         let backButton = UIBarButtonItem()
         backButton.title = "back"
         backButton.tintColor = UIColor(white: 0.15, alpha: 1)
         navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
         */
        
        view.backgroundColor = UIColor(white: 0.9, alpha: 1)
        
        tv.text = ""
        tv.layoutManager.allowsNonContiguousLayout = false
        tf.text = "ATI"
        seg.selectedSegmentIndex = 0
        
        var f = pickerView.frame
        f.origin.y = view.frame.height - f.size.height
        pickerView.frame = f
        
        //        serviceCBUUID = CBUUID(string: "03B80E5A-EDE8-4B33-A751-6CE34EC4C700")
        
        peripheralsDic = [:]
        peripheralsArray = []
        servicesArray = []
        characteristicArray = []
        
        pickerView.alpha = 0
        pickerPhase = .PERIPHERAL
        picker.delegate = self
        picker.dataSource = self
        picker.reloadAllComponents()
        btn_PickerDone.setTitle("select peripheral", for: .normal)
        
        // wifi
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFromWifiDongle(notification:)), name: Notification.Name("didReceiveFromWifiDongle"), object: nil)
        
        //        checkReachable()
        //        setReachabilityNotifier()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
    }
    
    // MARK: DONGLE
    
    // DONGLE
    // DONGLE
    // DONGLE
    @IBAction func btnConnect() {
        deviceIsInitialized = false
        tf.resignFirstResponder()
        switch seg.selectedSegmentIndex {
        case 0:
            // ELM327 BLE
            blePhase = .DISCOVER
            pickerPhase = .PERIPHERAL
            connectBle()
        case 1:
            // ELM327 WIFI
//            Globals.shared.deviceWifiAddress = "192.168.0.10"
//            Globals.shared.deviceWifiPort = "35000"
            connectWifi()
        case 2:
            // CanSee WIFI
//            Globals.shared.deviceWifiAddress = "192.168.4.1"
//            Globals.shared.deviceWifiPort = "35000"
            connectWifi()
        case 3:
            // HTTP GW
//            Globals.shared.deviceHttpAddress = "http://192.168.10.153/r/CanSeeEmulatorZE50.php"
            break
        default:
            break
        }
    }
    
    @IBAction func btnDisconnect() {
        deviceIsInitialized = false
        tf.resignFirstResponder()
        switch seg.selectedSegmentIndex {
        case 0:
            // ELM327 BLE
            disconnectBle()
        case 1:
            // ELM327 WIFI
            disconnectWifi()
        case 2:
            // CanSee WIFI
            disconnectWifi()
        case 3:
            // HTTP GW
            break
        default:
            break
        }
        
        if timeoutTimer != nil {
            if timeoutTimer.isValid {
                timeoutTimer.invalidate()
            }
            timeoutTimer = nil
        }
        if timeoutTimerBle != nil {
            if timeoutTimerBle.isValid {
                timeoutTimerBle.invalidate()
            }
            timeoutTimerBle = nil
        }
        if timeoutTimerWifi != nil {
            if timeoutTimerWifi.isValid {
                timeoutTimerWifi.invalidate()
            }
            timeoutTimerWifi = nil
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
        default:
            debug2("can't find device connection")
        }
    }
    
    func write_(s: String) {
        tf.resignFirstResponder()
        switch seg.selectedSegmentIndex {
        case 0:
            // ELM327 BLE
            writeBle(s: s)
        case 1:
            // ELM327 WIFI
            writeWifi(s: s)
        case 2:
            // CanSee WIFI
            writeWifi(s: s)
        case 3:
            // HTTP GW
            writeHttp(s: s)
        default:
            break
        }
    }

    // BTN
    
    @IBAction func btnAutoInit() {
        queue = []
        for s in autoInitElm327 {
            queue.append(s)
        }
        processQueue()
    }
    
    @IBAction func btnSaveBleConnectionParams() {
        //        ud.setValue(selectedPeripheral.blePeripheral.identifier.uuidString, forKey: "blePeripheral.identifier.uuidString")
        //        ud.setValue(selectedService.uuid.uuidString, forKey: "selectedService.uuid.uuidString")
        //        ud.setValue(selectedReadCharacteristic.uuid.uuidString, forKey: "selectedReadCharacteristic.uuid.uuidString")
        //        ud.setValue(selectedWriteCharacteristic.uuid.uuidString, forKey: "selectedWriteCharacteristic.uuid.uuidString")
        
        ud.setValue(Globals.shared.deviceBleName.rawValue, forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME)
        ud.setValue(Globals.shared.deviceBlePeripheralName, forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_NAME)
        ud.setValue(Globals.shared.deviceBlePeripheralUuid, forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID)
        ud.setValue(Globals.shared.deviceBleServiceUuid, forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID)
        ud.setValue(Globals.shared.deviceBleReadCharacteristicUuid, forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID)
        ud.setValue(Globals.shared.deviceBleWriteCharacteristicUuid, forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID)
       
        ud.synchronize()
        
        debug2("\(Globals.shared.deviceBleName.rawValue)")
        debug2(Globals.shared.deviceBlePeripheralName)
        debug2(Globals.shared.deviceBlePeripheralUuid)
        debug2(Globals.shared.deviceBleServiceUuid)
        debug2(Globals.shared.deviceBleReadCharacteristicUuid)
        debug2(Globals.shared.deviceBleWriteCharacteristicUuid)
    }
    
    @IBAction func btnLoadBleConnectionParams() {
        //        blePeripheral_identifier_uuidString = ud.string(forKey: "blePeripheral.identifier.uuidString") ?? ""
        //        selectedService_uuid_uuidString = ud.string(forKey: "selectedService.uuid.uuidString") ?? ""
        //        selectedReadCharacteristic_uuid_uuidString = ud.string(forKey: "selectedReadCharacteristic.uuid.uuidString") ?? ""
        //        selectedWriteCharacteristic_uuid_uuidString = ud.string(forKey: "selectedWriteCharacteristic.uuid.uuidString") ?? ""
        
        Globals.shared.deviceBleName = AppSettings.DEVICE_BLE_NAME(rawValue: ud.value(forKey: AppSettings.SETTINGS_DEVICE_BLE_NAME) as? Int ?? 0) ?? .NONE
        Globals.shared.deviceBlePeripheralName = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_NAME) ?? ""
        Globals.shared.deviceBlePeripheralUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_PERIPHERAL_UUID) ?? ""
        Globals.shared.deviceBleServiceUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_SERVICE_UUID) ?? ""
        Globals.shared.deviceBleReadCharacteristicUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_READ_CHARACTERISTIC_UUID) ?? ""
        Globals.shared.deviceBleWriteCharacteristicUuid = ud.string(forKey: AppSettings.SETTINGS_DEVICE_BLE_WRITE_CHARACTERISTIC_UUID) ?? ""
        
        debug2("\(Globals.shared.deviceBleName.rawValue)")
        debug2(Globals.shared.deviceBlePeripheralName)
        debug2(Globals.shared.deviceBlePeripheralUuid)
        debug2(Globals.shared.deviceBleServiceUuid)
        debug2(Globals.shared.deviceBleReadCharacteristicUuid)
        debug2(Globals.shared.deviceBleWriteCharacteristicUuid)
        
        blePhase = .DISCOVERED
        Globals.shared.deviceConnection = .BLE
        Globals.shared.deviceType = .ELM327
        if Globals.shared.deviceBlePeripheralName != "" {
            connectBle()
        } else {
            print("non configurato")
        }
    }
    
    @IBAction func btnTest() {
        tf.resignFirstResponder()
        if indiceTest > test.count - 1 {
            indiceTest = 0
        }
        let s = test[indiceTest]
        write_(s: s)
        
        debug2(s)
        
        indiceTest += 1
    }
    
    @IBAction func btnSend() {
        tf.resignFirstResponder()
        if tf.text != nil {
            write_(s: tf.text!)
        }
    }
    
    // ENCODE
    
    @IBAction func requestIsoTpFrame_() {
        //       if true { // TEST TEST TEST
        //            lastId = -1
        queue2 = []
        lastId = 0
        //        if Utils.isPh2() {
        //            addField(Sid.EVC, intervalMs: 2000) // open EVC
        //        }
        
        //            addField(Sid.MaxCharge, intervalMs: 5000)
        // addField(Sid.UserSoC, intervalMs: 5000)
        // addField(Sid.RealSoC, intervalMs: 5000)
        //            addField(Sid.SOH, intervalMs: 5000) // state of health gives continuous timeouts. This frame is send at a very low rate
        //            addField(Sid.RangeEstimate, intervalMs: 5000)
        // addField(Sid.DcPowerIn, intervalMs: 5000) // virtual virtual virtual
        //            addField(Sid.AvailableChargingPower, intervalMs: 5000)
        //            addField(Sid.HvTemp, intervalMs: 5000)
        
        //            addField(Sid.Counter_Full, intervalMs: 99999) //                   ff
        
        //        for i in 0 ..< 1 {
        let i = 0
        //            addField("\(Sid.Preamble_KM)\(240 - i * 24)", intervalMs: 6000)
        //            addField("\(Sid.Preamble_END)\(96 - i * 8)", intervalMs: 6000)
        //            addField("\(Sid.Preamble_TYP)\(96 - i * 8)", intervalMs: 6000)
        //            addField("\(Sid.Preamble_SOC)\(168 - i * 16)", intervalMs: 6000)
        addField("\(Sid.Preamble_TMP)\(96 - i * 8)", intervalMs: 6000) // test multiple reply
        //      }

        let ecu = Ecus.getInstance.getByMnemonic("LBC")
        if ecu != nil {
            if let frame = getFrame(fromId: ecu!.fromId, responseId: "62f18a") { // systemSupplierIdentifier
                addFrame(frame: frame)
            }
        }
        
        addField(Sid.BatterySerial, intervalMs: 99999) // 7bb.6162.16      2ff

        addField(Sid.Total_kWh, intervalMs: 99999) // 7bb.6161.120         1ff

        addField(Sid.Counter_Partial, intervalMs: 99999) //                ff

        startQueue2()
        
        /*       } else {
         // let field = Fields.getInstance.getBySID(Sid.UserSoC)
         
         //  print("\(field?.from ?? -1) \(field?.to ?? -1)")
         
         struct A {
         var a1 = ""
         var a2 = ""
         }
         var arr: [A] = []
         var a = A(a1: Sid.MaxCharge, a2: "05629018041AAAAA")
         //            arr.append(a)
         //            a = A(a1: Sid.UserSoC, a2: "622002130A")
         //            arr.append(a)
         //            a = A(a1: Sid.RealSoC, a2: "056290011843AAAA")
         //            arr.append(a)
         //            a = A(a1: Sid.SOH, a2: "0562900324ADAAAA")
         //            arr.append(a)
         //            a = A(a1: Sid.RangeEstimate, a2: "037F2231AAAAAAAA")
         //            arr.append(a)
         //            a = A(a1: Sid.DcPowerIn, a2: "")
         //            arr.append(a)
         //            a = A(a1: Sid.AvailableChargingPower, a2: "0562300F0000AAAA")
         //            arr.append(a)
         //            a = A(a1: Sid.HvTemp, a2: "0562901202B0AAAA")
         //            arr.append(a)
         a = A(a1: Sid.BatterySerial, a2: "101462F19056463121414730303030362234393531353432")
         arr.append(a)
         //            a = A(a1: Sid.Total_kWh, a2: "076292430018424E")
         //            arr.append(a)
         //            a = A(a1: Sid.Counter_Full, a2: "056292100019AAAA")
         //            arr.append(a)
         //            a = A(a1: Sid.Counter_Partial, a2: "0562921500BBAAAA")
         //            arr.append(a)
         
         for s in arr {
         let nn = Notification.Name("a")
         let no = Notification(name: nn, object: ["sid": s.a1, "reply": s.a2], userInfo: nil)
         received2(notification: no)
         /*
         let field = Fields.getInstance.getBySID(s.a1)
         
         if field != nil, s.a2 != "" {
         print("\(field?.sid ?? "?") \(field?.name ?? "?")")
         tv.text += "\n\(field?.sid ?? "?") \(field?.name ?? "?")"
         
         if Globals.shared.deviceType == AppSettings.DEVICE_TYPE_ELM327 {
         field?.strVal = decodeIsoTp(elmResponse2: s.a2) // ""
         if field!.strVal.hasPrefix("7f") {
         debug2( "error 7f")
         } else if field!.strVal == "" {
         debug2( "empty")
         } else {
         let binString = getAsBinaryString(data: field!.strVal)
         onMessageCompleteEventField(binString_: binString, field: field!)
         if field!.isString() || field!.isHexString() {
         debug2( "\(field!.strVal)")
         } else {
         debug2( "\(String(format: "%.\(field!.decimals!)f", field!.getValue()))")
         }
         }
         } else if Globals.shared.deviceType == AppSettings.DEVICE_TYPE_CANSEE {
         let binString = getAsBinaryString(data: s.a2)
         onMessageCompleteEventField(binString_: binString, field: field!)
         
         if field!.isString() || field!.isHexString() {
         debug2( "\(field!.strVal)")
         } else {
         debug2( " \(String(format: "%.\(field!.decimals!)f", field!.getValue()))")
         }
         } else {
         debug2( "device ?")
         }
         } else {
         debug2( "field \(s.a1) not found")
         }
         */
         }
         }*/
    }
    
    func getFrame(fromId: Int, responseId: String) -> Frame? {
        let frame = Frames.getInstance.getById(id: fromId, responseId: responseId)
        if frame == nil {
//            MainActivity.getInstance().dropDebugMessage(String.format(Locale.getDefault(), "Frame for this ECU %X.%s not found", fromId, responseId));
            return nil
        }
//        MainActivity.getInstance().dropDebugMessage(frame.getFromIdHex() + "." + frame.getResponseId());
        return frame!
    }

    func addFrame(frame: Frame) {
        if frame.isIsoTp() {
            requestIsoTpFrame(frame: frame, field: nil, virtual: nil)
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
                //  addField(field:field, intervalMs: intervalMs)
                //   print("sid \(field?.from ?? -1)")
                requestIsoTpFrame(frame: field.frame, field: field, virtual: nil)
            }
        } else {
            //            MainActivity.debug2(this.getClass().getSimpleName() + " (CanzeActivity): SID " + sid + " does not exist in class Fields");
            //            MainActivity.toast(MainActivity.TOAST_NONE, String.format(Locale.getDefault(), MainActivity.getStringSingle(R.string.format_NoSid), this.getClass().getSimpleName(), sid));
        }
    }
    
    func requestIsoTpFrame(frame: Frame, field: Field?, virtual: String?) {
        let seq = Sequence()

        if virtual != nil { // } || field!.sid.starts(with: "800.") {
            seq.sidVirtual = virtual
        }

        seq.frame = frame
        seq.field = field

        switch Globals.shared.deviceType {
        case .HTTP_GW:
            let s = "?command=i\(String(format: "%02x", frame.fromId)),\(frame.getRequestId()),\(frame.responseId ?? "")"
            seq.cmd.append(s)
            queue2.append(seq)
            return
        case .CANSEE:
            let s = "i\(String(format: "%02x", frame.fromId)),\(frame.getRequestId()),\(frame.responseId ?? "")"
            seq.cmd.append(s)
            queue2.append(seq)
            return
        case .ELM327:
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
        default:
            break
        }
    }

    // DECODE
   
    func decodeIsoTp(elmResponse: String) -> String { // TEST
        var hexData = ""
        var len = 0
        
//        var elmResponse = elmResponse2
        
        // ISOTP receiver starts here
        // clean-up if there is mess around
//        elmResponse = elmResponse.trimmingCharacters(in: .whitespacesAndNewlines)
//        if elmResponse.starts(with: ">") {
//            elmResponse = elmResponse.subString(from: 1)
//        }
        
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
            
            print("multi frame")
            
            len = Int(elmResponse.subString(from: 1, to: 4), radix: 16)!
            hexData = elmResponse.subString(from: 4)
            let framesToReceive = len / 7 // read this as ((len - 6 [remaining characters]) + 6 [offset to / 7, so 0->0, 1-7->7, etc]) / 7
            var fin = hexData.subString(from: 0, to: 12)
            var i = 0
            while i < framesToReceive {
                let sub = hexData.subString(from: 14 + i * 16, to: 28 + i * 16)
                fin.append(sub)
                i += 1
            }
            hexData = fin
            
        /*
         try {
             len = Integer.parseInt(elmResponse.substring(1, 4), 16);
             // remove 4 nibbles (type + length)
             hexData = elmResponse.substring(4);
         } catch (StringIndexOutOfBoundsException e) {
             return new Message(frame, "-E-ISOTP rx unexpected length of FRST frame:" + elmResponse, true);
         } catch (NumberFormatException e) {
             return new Message(frame, "-E-ISOTP rx uninterpretable length of FRST frame:" + elmResponse, true);
         }
         // calculate the # of frames to come. 6 byte are in and each of the 0x2 frames has a payload of 7 bytes
         int framesToReceive = len / 7; // read this as ((len - 6 [remaining characters]) + 6 [offset to / 7, so 0->0, 1-7->7, etc]) / 7
         // get all remaining 0x2 (NEXT) frames
         String lines0x1 = sendAndWaitForAnswer(null, 0, framesToReceive);
         // split into lines with hex data
         String[] hexDataLines = lines0x1.split("[\\r]+");
         int next = 1;
         for (String hexDataLine : hexDataLines) {
             // ignore empty lines
             hexDataLine = hexDataLine.trim();
             if (hexDataLine.length() > 2) {
                 // check the proper sequence
                 if (hexDataLine.startsWith(String.format("2%01X", next))) {
                     // cut off the first byte (type + sequence) and add to the result
                     hexData += hexDataLine.substring(2);
                 } else {
                     return new Message(frame, "-E-ISOTP rx out of sequence:" + hexDataLine, true);
                 }
                 if (next == 15) next = 0;
                 else next++;
             }
         }
         break;
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
        
        return hexData.lowercased()
    }
    
    func getAsBinaryString(data: String) -> String {
        // 629001266f
        // 0110001010010000000000010010011001101111
        
        var result = ""
        
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
        return result
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
                    let nn = Int(n, radix: 2)
                    let c = UnicodeScalar(nn!)
                    let s = String(format: "%02X", c as! CVarArg)
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
                // MainActivity.debug2("Value of " + field.getFromIdHex() + "." + field.getResponseId() + "." + field.getFrom()+" = "+val);
                // MainActivity.debug2("Fields: onMessageCompleteEvent > "+field.getSID()+" = "+val);
                
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
            //                MainActivity.debug2("Message.onMessageCompleteEventField: Exception:");
            //                MainActivity.debug2(e.getMessage());
            // ignore
            //            }
        }
        // update the fields last request date
        //  field.updateLastRequest();
    }
    
    // PICKER
    @IBAction func btnPickerCancel() {
        tf.resignFirstResponder()
        if pickerPhase == .PERIPHERAL {
            pickerView.alpha = 0
            
            tmpPickerIndex = 0
            selectedPeripheral = nil
            peripheralsArray = []
            picker.selectRow(0, inComponent: 0, animated: false)
            picker.reloadAllComponents()
            selectedPeripheral = nil
            
            centralManager.stopScan()
            
        } else if pickerPhase == .SERVICES {
            pickerPhase = .PERIPHERAL
            
            tmpPickerIndex = 0
            selectedService = nil
            servicesArray = []
            picker.selectRow(0, inComponent: 0, animated: false)
            picker.reloadAllComponents()
            btn_PickerDone.setTitle("select peripheral", for: .normal)
            
        } else if pickerPhase == .WRITE_CHARACTERISTIC {
            pickerPhase = .SERVICES
            
            tmpPickerIndex = 0
            selectedWriteCharacteristic = nil
            characteristicArray = []
            picker.selectRow(0, inComponent: 0, animated: false)
            picker.reloadAllComponents()
            btn_PickerDone.setTitle("select services", for: .normal)
            
        } else if pickerPhase == .READ_CHARACTERISTIC {
            pickerPhase = .WRITE_CHARACTERISTIC
            
            tmpPickerIndex = 0
            selectedReadCharacteristic = nil
            picker.selectRow(0, inComponent: 0, animated: false)
            picker.reloadAllComponents()
            btn_PickerDone.setTitle("select WRITE characteristic", for: .normal)
        }
    }
    
    @IBAction func btnPickerDone() {
        tf.resignFirstResponder()
        // print(tmpPickerIndex)
        if pickerPhase == .PERIPHERAL {
            if peripheralsArray.count > tmpPickerIndex {
                centralManager.stopScan()
                selectedPeripheral = peripheralsArray[tmpPickerIndex]
                Globals.shared.deviceBlePeripheralName = selectedPeripheral.blePeripheral.name ?? ""
                Globals.shared.deviceBlePeripheralUuid = selectedPeripheral.blePeripheral.identifier.uuidString
                debug2("selected peripheral \(selectedPeripheral.blePeripheral.name ?? "?")")
                selectedPeripheral.blePeripheral.delegate = self
                centralManager.connect(selectedPeripheral.blePeripheral)
                btn_PickerDone.setTitle("select service", for: .normal)
            }
        } else if pickerPhase == .SERVICES {
            if servicesArray.count > tmpPickerIndex {
                pickerPhase = .WRITE_CHARACTERISTIC
                selectedService = servicesArray[tmpPickerIndex]
                Globals.shared.deviceBleServiceUuid = selectedService.uuid.uuidString
                debug2("selected service \(selectedService.uuid)")
                characteristicArray = []
                selectedPeripheral.blePeripheral.discoverCharacteristics([selectedService.uuid], for: selectedService)
                btn_PickerDone.setTitle("select WRITE characteristic", for: .normal)
            }
        } else if pickerPhase == .WRITE_CHARACTERISTIC {
            if characteristicArray.count > tmpPickerIndex {
                selectedWriteCharacteristic = characteristicArray[tmpPickerIndex]
                Globals.shared.deviceBleWriteCharacteristicUuid = selectedWriteCharacteristic.uuid.uuidString
                debug2("selected write characteristic \(selectedWriteCharacteristic.uuid)")
                // peripheral.discoverDescriptors(for: characteristics)
                btn_PickerDone.setTitle("select NOTIFY characteristic", for: .normal)
                pickerPhase = .READ_CHARACTERISTIC
                tmpPickerIndex = 0
                picker.selectRow(0, inComponent: 0, animated: false)
                picker.reloadAllComponents()
            }
        } else if pickerPhase == .READ_CHARACTERISTIC {
            if characteristicArray.count > tmpPickerIndex {
                pickerPhase = .PERIPHERAL
                selectedReadCharacteristic = characteristicArray[tmpPickerIndex]
                Globals.shared.deviceBleReadCharacteristicUuid = selectedReadCharacteristic.uuid.uuidString
                debug2("selected notify characteristic \(selectedReadCharacteristic.uuid)")
                if selectedReadCharacteristic.properties.contains(.notify) {
                    for c in selectedService.characteristics! {
                        selectedPeripheral.blePeripheral.setNotifyValue(false, for: c)
                    }
                    selectedPeripheral.blePeripheral.setNotifyValue(true, for: selectedReadCharacteristic)
                    view.makeToast("ok")
                }
                // peripheral.discoverDescriptors(for: characteristics)
            }
            pickerView.alpha = 0
        }
    }
    
    // QUEUE
    
    func initQueue() {
        arraySequenze = []
    }
    
    func processQueue() {
        if queue.count == 0 {
            print("END")
            deviceIsInitialized = true
            return
        }
        
        if Globals.shared.deviceConnection == .BLE {
            writeBle(s: queue.first!)
        } else if Globals.shared.deviceConnection == .WIFI {
            writeWifi(s: queue.first!)
        } else {
            print("unknown connection type ???")
            return
        }
        
        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            print("queue timeout !!!")
            timer.invalidate()
            self.view.hideAllToasts()
            self.view.makeToast("TIMEOUT")
            return
        }
    }
    
    func continueQueue() {
        // next step, after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in // Change n to the desired number of seconds
            if queue.count > 0 {
                queue.remove(at: 0)
                processQueue()
            }
        }
    }
    
    // QUEUE2

    func startQueue2() {
        // TEST
        // if !deviceIsInitialized {
        // debug2( "device not Initialized")
        // return
        // }
        // TEST
        indiceCmd = 0
        processQueue2()
    }
    
    func processQueue2() {
        if queue2.count == 0 {
            print("END queue2")
            return
        }
        
        let seq = queue2.first! as Sequence
        if indiceCmd >= seq.cmd.count {
            queue2.removeFirst()
            print("END cmd")
            startQueue2()
            return
        }
        let cmd = seq.cmd[indiceCmd]
        write(s: cmd)
        
        if timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            timer.invalidate()
            self.debug2("queue2 timeout !!!")
            self.view.hideAllToasts()
            self.view.makeToast("TIMEOUT")
            return
        }
    }
    
    func continueQueue2() {
        // next step, after delay
        indiceCmd += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in // Change n to the desired number of seconds
            processQueue2()
        }
    }
    
    func debug2(_ s: String) {
        print(s)
        DispatchQueue.main.async { [self] in
            tv.text += "\n\(s)"
            tv.scrollToBottom()
        }
    }

    // received
    
    @objc func received(notification: Notification) {
        if queue.count > 0 {
            if timeoutTimer != nil {
                if timeoutTimer.isValid {
                    timeoutTimer.invalidate()
                    timeoutTimer = nil
                }
                continueQueue()
            }
        } else if queue2.count > 0 {
            NotificationCenter.default.post(name: Notification.Name("received2"), object: notification.object)
        } else {
            let notificationObject = notification.object as! [String: Any]
            let ss = notificationObject["reply"] as! String
            debug2("< '\(ss)' \(ss.count)")
//            print(Date().timeIntervalSince1970)
        }
    }

    @objc func received2(notification: Notification) {
        let notificationObject = notification.object as! [String: Any]
        let reply = notificationObject["reply"] as! String
        
        debug2("< '\(reply)' \(reply.count)")
        
        // TEST
        var sid = ""
        let seq = queue2.first
        if notificationObject["sid"] != nil {
            sid = notificationObject["sid"] as! String
        } else if seq?.frame != nil {
            // frame
            if queue2.count > 0, timeoutTimer != nil, timeoutTimer.isValid {
                timeoutTimer.invalidate()
                continueQueue2()
            }
            return
        } else {
            sid = (seq?.field.sid)!
        }
        // TEST
        
        let field = Fields.getInstance.getBySID(sid)
        
        if reply.contains("ERROR") {
            // do nothing
            debug2("ERROR")
        } else if reply == "OK" {
            // do nothing
        } else if reply == "" {
            debug2("empty")
        } else if field != nil {
            if Globals.shared.deviceType == .ELM327 {
                field?.strVal = decodeIsoTp(elmResponse: reply) // ""
            } else {
                // http, cansee
                field?.strVal = reply
            }
            
            //            print("\(field?.sid ?? "?") \(field?.name ?? "?")")
            //            tv.text += "\n\(field?.sid ?? "?") \(field?.name ?? "?")"
            
            if field!.strVal.hasPrefix("7f") {
                debug2("error 7f")
            } else if field!.strVal == "" {
                debug2("empty")
            } else {
                let binString = getAsBinaryString(data: field!.strVal)
                debug2(binString)
                onMessageCompleteEventField(binString_: binString, field: field!)
                
                if seq?.sidVirtual != nil {
                    var result = 0.0
                    switch seq?.sidVirtual {
                    case Sid.Instant_Consumption:
                        break
                    case Sid.FrictionTorque:
                        break
                    case Sid.DcPowerIn:
                        if fieldResult[Sid.TractionBatteryVoltage] != nil, fieldResult[Sid.TractionBatteryCurrent] != nil {
                            result = fieldResult[Sid.TractionBatteryVoltage]! * fieldResult[Sid.TractionBatteryCurrent]! / 1000.0
                        }
                    case Sid.DcPowerOut:
                        if fieldResult[Sid.TractionBatteryVoltage] != nil, fieldResult[Sid.TractionBatteryCurrent] != nil {
                            result = fieldResult[Sid.TractionBatteryVoltage]! * fieldResult[Sid.TractionBatteryCurrent]! / -1000.0
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
                        print("unknown virtual sid \(seq!.sidVirtual!)")
                    }
                    
                    field?.value = result
                }
                
                if field!.isString() || field!.isHexString() {
                    debug2("\(field!.strVal)")
                } else {
                    debug2("\(field?.name ?? "?") \(String(format: "%.\(field!.decimals!)f", field!.getValue()))\n")
                    fieldResult[field!.sid] = field!.getValue()
                }
            }
            
        } else {
            debug2("field \(seq?.field.sid ?? "?") not found")
        }
        
        if queue2.count > 0, timeoutTimer != nil, timeoutTimer.isValid {
            timeoutTimer.invalidate()
            continueQueue2()
        }
    }
}
