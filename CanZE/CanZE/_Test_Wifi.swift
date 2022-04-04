//
//  _Test_Wifi.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import Foundation

extension _TestViewController {
    func connectWifi() {
        if timeoutTimerWifi != nil {
            return
        }

        if Globals.shared.deviceWifiAddress == "" || Globals.shared.deviceWifiPort == "" {
            view.hideAllToasts()
            view.makeToast(NSLocalizedString("Please configure", comment: ""))
            return
        }

        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?

        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault,
                                           Globals.shared.deviceWifiAddress as CFString,
                                           UInt32(Globals.shared.deviceWifiPort)!,
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

        print("inputStream \(decodeStatus(inputStream.streamStatus))")
        print("outputStream \(decodeStatus(outputStream.streamStatus))")

        var contatore = 5
        timeoutTimerWifi = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [self] _ in
            print(contatore)

            if inputStream != nil, outputStream != nil, inputStream.streamStatus == .open, outputStream.streamStatus == .open {
                // connesso
                timeoutTimerWifi.invalidate()
                timeoutTimerWifi = nil
            }

            if contatore < 1 {
                // NON connesso
                if timeoutTimerWifi != nil {
                    if timeoutTimerWifi.isValid {
                        timeoutTimerWifi.invalidate()
                    }
                    timeoutTimerWifi = nil
                }
                disconnectWifi()
                view.hideAllToasts()
                view.makeToast("TIMEOUT")
            }

            contatore -= 1

        })
    }

    func disconnectWifi() {
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
        debug("disconnected")
    }

    func writeWifi(s: String) {
        if outputStream != nil, outputStream.streamStatus == .open {
            debug("> '\(s)'")
            let s2 = s.appending("\r")
            let data = s2.data(using: .utf8)!
            data.withUnsafeBytes {
                guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    debug("Error")
                    return
                }
                outputStream.write(pointer, maxLength: data.count)
            }
        }
    }

    // ricezione dati wifi
    @objc func didReceiveFromWifiDongle(notification: Notification) {
        let notificationObject = notification.object as? [String: Any]
        if notificationObject != nil, notificationObject?.keys != nil {
            for k in notificationObject!.keys {
                let ss = notificationObject![k] as! String
                NotificationCenter.default.post(name: Notification.Name("received"), object: ["reply": ss])
            }
        }
    }

    func decodeStatus(_ status: Stream.Status) -> String {
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
        default:
            return "unknown"
        }
    }
}

// MARK: StreamDelegate

// wifi
extension _TestViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if inputStream != nil, aStream == inputStream {
                //   print("\(aStream) hasBytesAvailable")
                readAvailableBytes(stream: aStream as! InputStream)
            }
        case .endEncountered:
            debug("\(aStream) endEncountered")
        case .hasSpaceAvailable:
            // print("\(aStream) hasSpaceAvailable")
            if aStream == outputStream {
                //                print("ready")
                //                print("ready")
                //   debug( "ready")
                // tv.text += ("ready\n")
                // tv.scrollToBottom()
            }
        case .errorOccurred:
            debug("\(aStream) errorOccurred \(aStream.streamError?.localizedDescription ?? "")")
        case .openCompleted:
            debug("\(aStream) openCompleted")
        default:
            debug("\(aStream) unknown event \(eventCode.rawValue)")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
            if numberOfBytesRead < 0, let error = stream.streamError {
                debug(error.localizedDescription)
                break
            }
            if let s = String(bytesNoCopy: buffer, length: numberOfBytesRead, encoding: .utf8, freeWhenDone: true), s.count > 0 {
                debug("<< '\(s)' (\(s.count))")
                if s.last == ">" || s.last == "\0" || s.last == "\r" || s.last == "\n" {
                    lastRxString += s

                    var reply = ""
                    if lastRxString.last == "\0" {
                        // cansee
                        let a = s.components(separatedBy: ",")
                        reply = a.last ?? s
                    } else {
                        // elm327
                        reply = lastRxString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
                        reply = String(reply.filter { !"\n\t\r".contains($0) })

                        if reply.subString(to: 1) == "1" { // multi frame
                            var finalReply = ""
                            for i in 0 ..< reply.count / 16 {
                                let s1 = reply.subString(from: i * 16 + 2, to: (i + 1) * 16)
                                finalReply.append(s1)
                            }
                            reply = finalReply
                        }

                        if reply != "NO DATA", reply != "CAN ERROR", reply != "", !reply.lowercased().hasPrefix("7f") {
                            reply = reply.subString(from: 2)
                        }
                    }

                    NotificationCenter.default.post(name: Notification.Name("received"), object: ["reply": reply])

                    lastRxString = ""
                } else if s.count > 4, s.subString(from: 2, to: 4).lowercased() == "7f" {
                    let reply = s.subString(from: 2)
                    NotificationCenter.default.post(name: Notification.Name("received"), object: ["reply": reply])
                    lastRxString = ""
                } else {
                    lastRxString += s
                }
            }
        }
    }
}
