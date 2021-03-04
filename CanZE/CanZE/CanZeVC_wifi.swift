//
//  CanZeVC_wifi.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import Foundation

extension CanZeViewController {
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

        Globals.shared.inputStream.delegate = navigationController as? StreamDelegate
        Globals.shared.outputStream.delegate = navigationController as? StreamDelegate

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
                debug("> '\(s)'")
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
