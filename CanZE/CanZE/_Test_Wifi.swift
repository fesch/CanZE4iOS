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
            view.makeToast("_Please configure")
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
        debug2("disconnected")
    }

    func writeWifi(s: String) {
        if outputStream != nil, outputStream.streamStatus == .open {
            debug2("> \(s)")
            let s2 = s.appending("\r")
            let data = s2.data(using: .utf8)!
            data.withUnsafeBytes {
                guard let pointer = $0.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                    debug2("Error")
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
            debug2("\(aStream) endEncountered")
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
            debug2("\(aStream) errorOccurred \(aStream.streamError?.localizedDescription ?? "")")
        case .openCompleted:
            debug2("\(aStream) openCompleted")
        default:
            debug2("\(aStream) unknown event \(eventCode.rawValue)")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = inputStream.read(buffer, maxLength: maxReadLength)
            if numberOfBytesRead < 0, let error = stream.streamError {
                debug2(error.localizedDescription)
                break
            }
            if var string = String(bytesNoCopy: buffer, length: numberOfBytesRead, encoding: .utf8,
                                   freeWhenDone: true), string.count > 0
            {
                string = string.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
                string = String(string.filter { !" \n\t\r".contains($0) })
                if string.subString(to: 1) == "1" { // multi frame, first frame
                    incompleteReply = string
                    repliesAddedCounter = 0
                } else if string.subString(to: 1) == "2" { // multi frame, next frames
                    if incompleteReply != "" {
                        incompleteReply += string
                        repliesAddedCounter += 1
                        let replyLen = Int(incompleteReply.subString(from: 1, to: 4), radix: 16)! * 2 // 134
                        if incompleteReply.count >= replyLen + repliesAddedCounter * 2 {
                            var finalReply = ""
                            for i in 0 ..< incompleteReply.count / 16 {
                                let s1 = incompleteReply.subString(from: i * 16 + 2, to: (i + 1) * 16)
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
