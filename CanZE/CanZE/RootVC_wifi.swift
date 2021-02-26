//
//  RootVC_wifi.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import Foundation

extension RootViewController {
    // ELM327 WIFI
    // ELM327 WIFI
    // ELM327 WIFI
    func connectWifi() {
        if Globals.shared.inputStream != nil || Globals.shared.outputStream != nil {
            disconnectWifi()
        }

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

        Globals.shared.inputStream.schedule(in: RunLoop.main, forMode: .common)
        Globals.shared.outputStream.schedule(in: RunLoop.main, forMode: .common)

        Globals.shared.inputStream.open()
        Globals.shared.outputStream.open()

        print("inputStream \(decodeStatus(status: Globals.shared.inputStream.streamStatus))")
        print("outputStream \(decodeStatus(status: Globals.shared.outputStream.streamStatus))")

        var contatore = 5
        #if targetEnvironment(simulator)
        contatore = 10
        #endif
        Globals.shared.timeoutTimerWifi = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [self] _ in
            print(contatore)

            if Globals.shared.inputStream != nil, Globals.shared.outputStream != nil, Globals.shared.inputStream.streamStatus == .open, Globals.shared.outputStream.streamStatus == .open {
                // connesso, disabilita timer timeout connessione
                if Globals.shared.timeoutTimerWifi != nil {
                    if Globals.shared.timeoutTimerWifi.isValid {
                        Globals.shared.timeoutTimerWifi.invalidate()
                    }
                    Globals.shared.timeoutTimerWifi = nil
                }
                Globals.shared.deviceIsConnected = true
                deviceConnected()
                NotificationCenter.default.post(name: Notification.Name("connected"), object: nil)
            }

            if contatore < 1 {
                // NON connesso
                if Globals.shared.timeoutTimerWifi != nil {
                    if Globals.shared.timeoutTimerWifi.isValid {
                        Globals.shared.timeoutTimerWifi.invalidate()
                    }
                    Globals.shared.timeoutTimerWifi = nil
                }
                disconnectWifi()
                DispatchQueue.main.async { [self] in
                    disconnect(showToast: false)
                    view.hideAllToasts()
                    view.makeToast("TIMEOUT")
                }
                Globals.shared.deviceIsConnected = false
                deviceDisconnected()
            }

            contatore -= 1

        })
    }

    func disconnectWifi() {
        if Globals.shared.inputStream != nil {
            Globals.shared.inputStream.close()
            Globals.shared.inputStream.delegate = nil
            Globals.shared.inputStream.remove(from: RunLoop.main, forMode: .common)
            Globals.shared.inputStream = nil
        }
        if Globals.shared.outputStream != nil {
            Globals.shared.outputStream.close()
            Globals.shared.outputStream.delegate = nil
            Globals.shared.outputStream.remove(from: RunLoop.main, forMode: .common)
            Globals.shared.outputStream = nil
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
}

// MARK: StreamDelegate

// wifi
extension RootViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if aStream == Globals.shared.inputStream, aStream.streamStatus == .open {
                readAvailableBytes(stream: aStream as! InputStream)
            }
        case .endEncountered:
            debug("\(aStream) endEncountered")
        case .hasSpaceAvailable:
            break
        case .errorOccurred:
            debug("\(aStream) errorOccurred")
            disconnect(showToast: true)
        case .openCompleted:
            debug("\(aStream) openCompleted")
        default:
            debug("\(aStream) \(eventCode.rawValue)")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Globals.shared.maxReadLength)

        while stream.hasBytesAvailable {
            let numberOfBytesRead = stream.read(buffer, maxLength: Globals.shared.maxReadLength)
            if numberOfBytesRead < 0, let error = stream.streamError {
                debug(error.localizedDescription)
                break
            }
            if var string = String(bytesNoCopy: buffer, length: numberOfBytesRead, encoding: .utf8, freeWhenDone: true), string.count > 0 {
                if Globals.shared.deviceType == .CANSEE {
                    let a = string.components(separatedBy: ",")
                    if a.count > 0 {
                        string = a.last!
                        let dic: [String: String] = ["reply": string]
                        NotificationCenter.default.post(name: Notification.Name("didReceiveFromWifiDongle"), object: dic)
                        return
                    }
                }
                string = string.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
                string = String(string.filter { !" \n\t\r".contains($0) })
                if string.subString(to: 1) == "1" { // multi frame, first frame
                    Globals.shared.incompleteReply = string
                    Globals.shared.repliesAddedCounter = 0
                } else if string.subString(to: 1) == "2" { // multi frame, next frames
                    if Globals.shared.incompleteReply != "" {
                        Globals.shared.incompleteReply += string
                        Globals.shared.repliesAddedCounter += 1
                        let replyLen = Int(Globals.shared.incompleteReply.subString(from: 1, to: 4), radix: 16)! * 2 // 134
                        if Globals.shared.incompleteReply.count >= replyLen + Globals.shared.repliesAddedCounter * 2 {
                            var finalReply = ""
                            for i in 0 ..< Globals.shared.incompleteReply.count / 16 {
                                let s1 = Globals.shared.incompleteReply.subString(from: i * 16 + 2, to: (i + 1) * 16)
                                finalReply.append(s1)
                            }
                            finalReply = finalReply.subString(from: 2)
                            let dic: [String: String] = ["reply": finalReply]
                            NotificationCenter.default.post(name: Notification.Name("didReceiveFromWifiDongle"), object: dic)
                        }
                    }
                } else { // single frame
                    let dic: [String: String] = ["reply": string]
                    NotificationCenter.default.post(name: Notification.Name("didReceiveFromWifiDongle"), object: dic)
                }
            }
        }
    }
}
