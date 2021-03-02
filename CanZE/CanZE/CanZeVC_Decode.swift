//
//  CanZeVC_Decode.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import Foundation

extension CanZeViewController {
    func decodeIsoTp(_ elmResponse: String) -> String { // TEST
        var hexData = ""
        var len = 0

        // var elmResponse = elmResponse2

        // ISOTP receiver starts here
        // clean-up if there is mess around
        // elmResponse = elmResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        // if elmResponse.starts(with: ">") {
        //    elmResponse = elmResponse.subString(from: 1)
        // }

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

    @objc func received(notification: Notification) {
        //        if queue.count > 0 || queueInit.count > 0 {
        if Globals.shared.queueInit.count > 0 {
            if Globals.shared.timeoutTimer != nil, Globals.shared.timeoutTimer.isValid {
                Globals.shared.timeoutTimer.invalidate()
                //    if queue.count > 0 {
                //        continueQueue()
                //    } else
                if Globals.shared.queueInit.count > 0 {
                    continueQueueInit()
                }
            }
        } else if Globals.shared.queue2.count > 0 {
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

        if reply != Globals.shared.lastReply {
            debug("< '\(reply)' (\(reply.count))")
            Globals.shared.lastReply = reply

            var sid = ""
            if let seq = Globals.shared.queue2.first {
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
//                            if Globals.shared.deviceType == .ELM327 {
//                                field.strVal = decodeIsoTp(reply)
//                            } else { // http, cansee
                                field.strVal = reply
//                            }
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
                        if debugMessage != Globals.shared.lastDebugMessage {
                            let dic = ["debug": debugMessage]
                            Globals.shared.lastDebugMessage = debugMessage
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
//                            if Globals.shared.deviceType == .ELM327 {
//                                field.strVal = decodeIsoTp(reply) // ""
//                            } else { // http, cansee
                                field.strVal = reply
//                            }
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
                                    if debugMessage != Globals.shared.lastDebugMessage {
                                        let dic = ["debug": debugMessage]
                                        Globals.shared.lastDebugMessage = debugMessage
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
                                        if debugMessage != Globals.shared.lastDebugMessage {
                                            let dic = ["debug": debugMessage]
                                            Globals.shared.lastDebugMessage = debugMessage
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
                                            if debugMessage != Globals.shared.lastDebugMessage {
                                                let dic = ["debug": debugMessage]
                                                Globals.shared.lastDebugMessage = debugMessage
                                                NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        let debugMessage = "Debug \(field.sid ?? "?") \(error) \(field.isString() ? field.strVal : String(format: "%.2f", field.getValue()))"
                        if debugMessage != Globals.shared.lastDebugMessage {
                            let dic = ["debug": debugMessage]
                            Globals.shared.lastDebugMessage = debugMessage
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

        if Globals.shared.queue2.count > 0, Globals.shared.timeoutTimer != nil, Globals.shared.timeoutTimer.isValid {
            Globals.shared.timeoutTimer.invalidate()
            continueQueue2()
        }
    }
}
