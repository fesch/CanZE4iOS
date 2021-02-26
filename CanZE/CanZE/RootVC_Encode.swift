//
//  RootVC_Encode.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import Foundation

extension RootViewController {
    func addField(_ sid: String, intervalMs: Int) {
        if let field = Fields.getInstance.getBySID(sid) {
            if field.responseId != "999999" {
                if field.virtual {
                    let virtualField = Fields.getInstance.getBySID(field.sid) as! VirtualField
                    let fields = virtualField.getFields()
                    for f in fields {
                        if f.responseId != "999999" {
                            var found = false
                            for s in Globals.shared.queue2 {
                                if s.field.sid == f.sid {
                                    found = true
                                    break
                                }
                            }
                            if !found {
                                requestIsoTpFrame(frame: f.frame, field: f, virtual: field.sid)
                            }
                        }
                    }
                } else {
                    var found = false
                    if intervalMs != 0 { // to speed up pedal position update on DrivingViewController
                        for s in Globals.shared.queue2 {
                            if s.field.sid == field.sid {
                                found = true
                                break
                            }
                        }
                    }
                    if !found {
                        requestIsoTpFrame(frame: field.frame, field: field, virtual: nil)
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

            Globals.shared.queue2.append(seq)

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
            Globals.shared.queue2.append(seq)
        default:
            print("device unknown")
        }
        addFrame(frame: frame)
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
            Globals.shared.queue2.append(seq)
            return
        case .CANSEE:
            let s = "i\(String(format: "%02x", frame.fromId)),\(frame.getRequestId()),\(frame.responseId ?? "")"
            seq.cmd.append(s)
            Globals.shared.queue2.append(seq)
            return
        case .ELM327:
            if Globals.shared.lastId != frame.fromId {
                if frame.isExtended() {
                    seq.cmd.append("atsp7")
                } else {
                    seq.cmd.append("atsp6")
                }
                seq.cmd.append("atcp\(frame.getToIdHexMSB())") // atcp18
                seq.cmd.append("atsh\(frame.getToIdHexLSB())") // atshdad2f1
                seq.cmd.append("atcra\(String(format: "%02x", frame.fromId))") // 18daf1d2
                seq.cmd.append("atfcsh\(String(format: "%02x", frame.getToId()))") // 18dad2f1
                Globals.shared.lastId = frame.fromId
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
            Globals.shared.queue2.append(seq)
        default:
            break
        }
    }
}
