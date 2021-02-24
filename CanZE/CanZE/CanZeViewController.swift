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
        NotificationCenter.default.addObserver(self, selector: #selector(received(notification:)), name: Notification.Name("received"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(received2(notification:)), name: Notification.Name("received2"), object: nil)
        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        queue2 = []
        lastId = 0
        
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
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
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
    
    func connect() {
        if !super.deviceIsConnectable() {
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
            // new field
            let dic = ["debug": "Debug \(seq.field?.sid ?? "?") \(seq.field.name ?? "?")"]
            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
            // debug("Debug \(seq.field?.sid ?? "")")
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
            timeoutTimer = nil
        }
        
        var contatore = 10
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            contatore -= 1
            print(contatore)
            if contatore < 1 {
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
        timeoutTimer.fire()
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
            let notificationObject = notification.object as! [String: Any]
            let reply = notificationObject["reply"] as! String
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
                debug("< '\(reply)' (\(reply.count))")
            }
        }
    }
    
    @objc func received2(notification: Notification) {
        var error = "ok"
        let notificationObject = notification.object as! [String: Any]
        let reply = notificationObject["reply"] as! String
        
        if reply != lastReply {
            debug("< '\(reply)' (\(reply.count))")
            lastReply = reply
        
            var sid = ""
            if let seq = queue2.first {
                if notificationObject["sid"] != nil {
                    sid = notificationObject["sid"] as! String
                } else if seq.field != nil {
                    sid = seq.field.sid!
                }
            
                if sid == "" { // firmware
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
                                field.strVal = decodeIsoTp(reply)
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
                            if Globals.shared.writeForEmulator {
                                let key = "\(field.frame.getFromIdHex()).\(field.frame.responseId!)"
                                if !Globals.shared.sidFatti.contains(key) {
                                    Globals.shared.loggerEmulator.add("case \"\(key)\": // \(field.name ?? "")")
                                    Globals.shared.loggerEmulator.add("$RES = \"\(reply)\";")
                                    Globals.shared.loggerEmulator.add("break;")
                                    Globals.shared.sidFatti.append(key)
                                }
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
                                field.strVal = decodeIsoTp(reply) // ""
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
                                        if Globals.shared.writeForEmulator {
                                            let key = "\(f.frame.getFromIdHex()).\(f.frame.responseId!)"
                                            if !Globals.shared.sidFatti.contains(key) {
                                                Globals.shared.loggerEmulator.add("case \"\(key)\": // \(f.name ?? "")")
                                                Globals.shared.loggerEmulator.add("$RES = \"\(reply)\";")
                                                Globals.shared.loggerEmulator.add("break;")
                                                Globals.shared.sidFatti.append(key)
                                            }
                                        }
                                    }
                                
                                    // notify real field
                                    // var notificationObject = notification.object as! [String: String]
                                    // notificationObject["sid"] = f.sid
                                    // NotificationCenter.default.post(name: Notification.Name("decoded"), object: notificationObject)
                                
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
                                            print("unknown virtual sid \(seq.sidVirtual!)")
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
}
