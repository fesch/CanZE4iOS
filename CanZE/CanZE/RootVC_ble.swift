//
//  RootVC_ble.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import CoreBluetooth
import Foundation

extension RootViewController {
    // ELM327 BLE
    // ELM327 BLE
    // ELM327 BLE
    func connectBle() {
        Globals.shared.peripheralsDic = [:]
        // peripheralsArray = []
        Globals.shared.selectedPeripheral = nil
        if Globals.shared.blePhase == .DISCOVERED {
            Globals.shared.timeoutTimerBle = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
                if Globals.shared.selectedPeripheral == nil {
                    // timeout
                    Globals.shared.centralManager.stopScan()
                    timer.invalidate()
                    self.disconnect(showToast: false)
                    DispatchQueue.main.async { [self] in
                        view.hideAllToasts()
                        view.makeToast("_can't connect to ble device: TIMEOUT")
                    }
                }
            })
        }
        Globals.shared.centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func disconnectBle() {
        if Globals.shared.selectedPeripheral != nil, Globals.shared.selectedPeripheral.blePeripheral != nil {
            if Globals.shared.centralManager != nil {
                Globals.shared.centralManager.cancelPeripheralConnection(Globals.shared.selectedPeripheral.blePeripheral)
            }
            Globals.shared.selectedPeripheral.blePeripheral = nil
            Globals.shared.selectedService = nil
            Globals.shared.selectedReadCharacteristic = nil
            Globals.shared.selectedWriteCharacteristic = nil
        }
    }

    func writeBle(s: String) {
        if Globals.shared.selectedWriteCharacteristic != nil {
            let ss = s.appending("\r")
            if let data = ss.data(using: .utf8) {
                if Globals.shared.selectedWriteCharacteristic.properties.contains(.write) {
                    Globals.shared.selectedPeripheral.blePeripheral.writeValue(data, for: Globals.shared.selectedWriteCharacteristic, type: .withResponse)
                    debug("> \(s)")
                } else if Globals.shared.selectedWriteCharacteristic.properties.contains(.writeWithoutResponse) {
                    Globals.shared.selectedPeripheral.blePeripheral.writeValue(data, for: Globals.shared.selectedWriteCharacteristic, type: .withoutResponse)
                    debug("> \(s)")
                } else {
                    debug("can't write to characteristic")
                }
            } else {
                debug("data is nil")
            }
        }
    }
}

// MARK: CBCentralManagerDelegate

extension RootViewController: CBCentralManagerDelegate {
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
            p.blePeripheral.delegate = self
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

extension RootViewController: CBPeripheralDelegate {
    // Services
    // Services
    // Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
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
//                    print(c.uuid.uuidString)
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
                        deviceConnected()
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
            print("error didWriteValueFor \(characteristic.uuid.uuidString) \(error!.localizedDescription)")
            return
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        } else if characteristic.uuid.uuidString == Globals.shared.selectedReadCharacteristic.uuid.uuidString {
            let s = String(data: characteristic.value!, encoding: .utf8)
            if s?.last == ">" {
                Globals.shared.lastRxString += s!

                var reply = Globals.shared.lastRxString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines.inverted)
                reply = String(reply.filter { !" \n\t\r".contains($0) })

                if reply.subString(to: 1) == "1" { // multi frame
                    var finalReply = ""
                    for i in 0 ..< reply.count / 16 {
                        let s1 = reply.subString(from: i * 16 + 2, to: (i + 1) * 16)
                        finalReply.append(s1)
                    }
                    reply = finalReply.subString(from: 2)
                }

                let dic: [String: String] = ["reply": reply]
                NotificationCenter.default.post(name: Notification.Name("received"), object: dic)

                Globals.shared.lastRxString = ""

            } else {
                Globals.shared.lastRxString += s ?? ""
            }
        } else {
            print("received dati da char sconosciuta \(characteristic.uuid.uuidString)")
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
