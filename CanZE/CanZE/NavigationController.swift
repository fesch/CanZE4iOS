//
//  NavigationController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import CoreBluetooth
import UIKit

class NavigationController: UINavigationController, CBCentralManagerDelegate, CBPeripheralDelegate, StreamDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("NavigationController")

        // Do any additional setup after loading the view.
    }

    func debug(_ s: String) {
        print(s)
        if Globals.shared.useSdCard {
            Globals.shared.logger.add(s)
        }
    }
}

// MARK: CBCentralManagerDelegate

extension NavigationController {
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
            Globals.shared.centralManager.scanForPeripherals(withServices: [])
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

        if Globals.shared.blePhase == .DISCOVERED, Globals.shared.deviceBlePeripheralName == p.blePeripheral.name {
            if Globals.shared.timeoutTimerBle != nil {
                if Globals.shared.timeoutTimerBle.isValid {
                    Globals.shared.timeoutTimerBle.invalidate()
                }
                Globals.shared.timeoutTimerBle = nil
            }
            Globals.shared.centralManager.stopScan()
            p.blePeripheral.delegate = self as CBPeripheralDelegate
            Globals.shared.selectedPeripheral = p
            debug("found selected Peripheral \(Globals.shared.selectedPeripheral.blePeripheral.name ?? "")")
            Globals.shared.centralManager.connect(Globals.shared.selectedPeripheral.blePeripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debug("didConnect \(peripheral.name ?? "?") \(peripheral.identifier.uuidString)")
        Globals.shared.servicesArray = []
        Globals.shared.pickerPhase = .SERVICES
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

extension NavigationController {
    // Services
    // Services
    // Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            debug(error?.localizedDescription ?? "")
            return
        }
        Globals.shared.servicesArray.append(contentsOf: peripheral.services ?? [])

        if Globals.shared.blePhase == .DISCOVERED {
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

            if Globals.shared.blePhase == .DISCOVERED {
                for c in Globals.shared.characteristicArray {
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
                        NotificationCenter.default.post(name: Notification.Name("deviceConnected"), object: nil)
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
            debug("error didWriteValueFor \(characteristic.uuid.uuidString) \(error!.localizedDescription)")
            return
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            debug(error?.localizedDescription ?? "")
            return
        } else if characteristic.uuid.uuidString == Globals.shared.selectedReadCharacteristic.uuid.uuidString {
            let s = String(data: characteristic.value!, encoding: .utf8)
            debug("<< '\(s!)' (\(s!.count))")
            if s?.last == ">" {
                Globals.shared.lastRxString += s!

                var reply = Globals.shared.lastRxString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
                reply = String(reply.filter { !"\n\t\r".contains($0) })

                if reply.subString(to: 1) == "1" { // multi frame
                    var finalReply = ""
                    for i in 0 ..< reply.count / 16 {
                        let s1 = reply.subString(from: i * 16 + 2, to: (i + 1) * 16)
                        finalReply.append(s1)
                    }
                    reply = finalReply
                }

                if reply != "NO DATA" && reply != "CAN ERROR" && reply != "" && !reply.starts(with: "7F") {
                    reply = reply.subString(from: 2)
                }

                let dic: [String: String] = ["reply": reply]
                NotificationCenter.default.post(name: Notification.Name("received"), object: dic)

                Globals.shared.lastRxString = ""

            } else {
                Globals.shared.lastRxString += s ?? ""
            }
        } else {
            debug("received dati da char sconosciuta \(characteristic.uuid.uuidString)")
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

// MARK: StreamDelegate

// wifi
extension NavigationController {
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
            // disconnect(showToast: true)
            NotificationCenter.default.post(name: Notification.Name("deviceDisconnected"), object: nil)
        case .openCompleted:
            debug("\(aStream) openCompleted")
        default:
            debug("\(aStream) \(eventCode.rawValue)")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: Globals.shared.maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = Globals.shared.inputStream.read(buffer, maxLength: Globals.shared.maxReadLength)
            if numberOfBytesRead < 0, let error = stream.streamError {
                debug(error.localizedDescription)
                break
            }
            if let s = String(bytesNoCopy: buffer, length: numberOfBytesRead, encoding: .utf8, freeWhenDone: true), s.count > 0 {
                debug("<< '\(s)' (\(s.count))")
                Globals.shared.lastRxString += s
                if Globals.shared.lastRxString.last == ">" || Globals.shared.lastRxString.last == "\0" {
                    var reply = ""
                    if Globals.shared.lastRxString.last == "\0" {
                        // cansee
                        let a = s.components(separatedBy: ",")
                        reply = a.last ?? s
                    } else {
                        // elm327
                        reply = Globals.shared.lastRxString.trimmingCharacters(in: NSCharacterSet.alphanumerics.inverted)
                        reply = String(reply.filter { !"\n\t\r".contains($0) })

                        if reply.subString(to: 1) == "1" { // multi frame
                            var finalReply = ""
                            for i in 0 ..< reply.count / 16 {
                                let s1 = reply.subString(from: i * 16 + 2, to: (i + 1) * 16)
                                finalReply.append(s1)
                            }
                            reply = finalReply
                        }

                        if reply != "NO DATA" && reply != "CAN ERROR" && reply != "" && !reply.starts(with: "7F") {
                            reply = reply.subString(from: 2)
                        }
                    }

                    let dic: [String: String] = ["reply": reply]
                    NotificationCenter.default.post(name: Notification.Name("didReceiveFromWifiDongle"), object: dic)

                    Globals.shared.lastRxString = ""
                }
            }
        }
    }
}
