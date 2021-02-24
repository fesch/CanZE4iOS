//
//  _Test_Wifi.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import Foundation

// MARK: StreamDelegate

// wifi
extension _TestViewController: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            if aStream == inputStream {
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
            debug2("\(aStream) errorOccurred")
        case .openCompleted:
            debug2("\(aStream) openCompleted")
        default:
            debug2("\(aStream) \(eventCode.rawValue)")
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
            var string = String(
                bytesNoCopy: buffer,
                length: numberOfBytesRead,
                encoding: .utf8,
                freeWhenDone: true)
            if string != nil, string!.count > 0 {
                string = string?.trimmingCharacters(in: .whitespacesAndNewlines)
                string = String(string!.filter { !">".contains($0) })
                string = String(string!.filter { !"\r".contains($0) })
                let dic: [String: String] = ["reply": string!]
                NotificationCenter.default.post(name: Notification.Name("didReceiveFromWifiDongle"), object: dic)
            }
        }
    }
}
