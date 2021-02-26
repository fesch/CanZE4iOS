//
//  _Test_CentralManager.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import CoreBluetooth

extension _TestViewController {
    func connectBle() {
        peripheralsDic = [:]
        peripheralsArray = []
        selectedPeripheral = nil
        if blePhase == .DISCOVERED {
            timeoutTimerBle = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false, block: { timer in
                if self.selectedPeripheral == nil {
                    // timeout
                    self.centralManager.stopScan()
                    timer.invalidate()
                    self.view.hideAllToasts()
                    self.view.makeToast("can't connect to ble device: TIMEOUT")
                }
            })
        }
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func disconnectBle() {
        if selectedPeripheral != nil, selectedPeripheral.blePeripheral != nil {
            centralManager.cancelPeripheralConnection(selectedPeripheral.blePeripheral)
            selectedPeripheral.blePeripheral = nil
            selectedService = nil
            selectedReadCharacteristic = nil
            selectedWriteCharacteristic = nil
        }
    }

    func writeBle(s: String) {
        if selectedWriteCharacteristic != nil {
            let ss = s.appending("\r")
            if let data = ss.data(using: .utf8) {
                if selectedWriteCharacteristic.properties.contains(.write) {
                    selectedPeripheral.blePeripheral.writeValue(data, for: selectedWriteCharacteristic, type: .withResponse)
                    debug2("> \(s)")
                } else if selectedWriteCharacteristic.properties.contains(.writeWithoutResponse) {
                    selectedPeripheral.blePeripheral.writeValue(data, for: selectedWriteCharacteristic, type: .withoutResponse)
                    debug2("> \(s)")
                } else {
                    debug2("can't write to characteristic")
                }
            } else {
                debug2("data is nil")
            }
        }
    }
}

// MARK: CBCentralManagerDelegate

extension _TestViewController: CBCentralManagerDelegate {
    // CentralManager
    // CentralManager
    // CentralManager
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            debug2("central.state is .unknown")
        case .resetting:
            debug2("central.state is .resetting")
        case .unsupported:
            debug2("central.state is .unsupported")
        case .unauthorized:
            debug2("central.state is .unauthorized")
        case .poweredOff:
            debug2("central.state is .poweredOff")
        case .poweredOn:
            debug2("central.state is .poweredOn")
            //            centralManager.scanForPeripherals(withServices: [serviceCBUUID])
            centralManager.scanForPeripherals(withServices: [])
        @unknown default:
            debug2("central.state is unknown")
        }
    }

    // Peripheral
    // Peripheral
    // Peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let p = BlePeripheral()
        p.blePeripheral = peripheral
        p.rssi = RSSI
        peripheralsDic[peripheral.identifier.uuidString] = p

        if blePhase == .DISCOVER {
            pickerView.alpha = 1
            btn_PickerDone.setTitle("select peripheral", for: .normal)

            var trovato = false
            for pp in peripheralsArray {
                if pp.blePeripheral.identifier.uuidString == p.blePeripheral.identifier.uuidString {
                    trovato = true
                    break
                }
            }
            if !trovato {
                debug2("discovered \(peripheral.name ?? "?")")
                peripheralsArray.append(p)
                picker.reloadAllComponents()
            }
        }
        //        peripheralsArray.sort { (a:Peripheral, b:Peripheral) -> Bool in
        //            a.peripheral.name ?? "" < b.peripheral.name ?? ""
        //        }

        if blePhase == .DISCOVERED, Globals.shared.deviceBlePeripheralName == p.blePeripheral.name {
            timeoutTimerBle.invalidate()
            centralManager.stopScan()
            p.blePeripheral.delegate = self
            selectedPeripheral = p
            debug2("found selected Peripheral \(selectedPeripheral.blePeripheral.name ?? "")")
            centralManager.connect(selectedPeripheral.blePeripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debug2("didConnect \(peripheral.name ?? "?") \(peripheral.identifier.uuidString)")
        servicesArray = []
        pickerPhase = .SERVICES
        tmpPickerIndex = 0
        //  peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debug2("didFailToConnect \(peripheral) \(error?.localizedDescription ?? "")")
    }

    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        debug2("connectionEventDidOccur \(peripheral)")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debug2("didDisconnectPeripheral \(peripheral.name ?? "")")
    }

    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {}

    //    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    //    }
}

// MARK: CBPeripheralDelegate

extension _TestViewController: CBPeripheralDelegate {
    // Services
    // Services
    // Services
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        }
        //        var i = 0
        //        while i < peripheral.services!.count {
        //            let service = peripheral.services![i]
        //            print(service)
        //            tv.text += ("\n\(service.uuid.uuidString)")
        //            tv.scrollToBottom()
        //            servicesArray.append(service)
        //            i = i + 1
        //        }
        servicesArray.append(contentsOf: peripheral.services ?? [])

        if blePhase == .DISCOVER {
            tmpPickerIndex = 0
            picker.selectRow(tmpPickerIndex, inComponent: 0, animated: true)
            picker.reloadAllComponents()
        }

        if blePhase == .DISCOVERED {
            for s in servicesArray {
                if s.uuid.uuidString == Globals.shared.deviceBleServiceUuid {
                    selectedService = s
                    debug2("found selected service \(selectedService.uuid)")
                    characteristicArray = []
                    selectedPeripheral.blePeripheral.discoverCharacteristics([selectedService.uuid], for: selectedService)
                    break
                }
            }
        }
    }

    //    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
    //        print("\(Date().description(with: Locale.current)) didWriteValueFor \(peripheral.name ?? "") \(descriptor.uuid) \(error?.localizedDescription ?? "")")
    //    }

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
        //        print("didDiscoverCharacteristicsFor ")
        if service.characteristics != nil, service.characteristics!.count > 0 {
            // selectedPeripheral.characteristics = service.characteristics!
            // var ii = 0
            // while ii < service.characteristics!.count {
            //   let characteristic = service.characteristics![ii]
            //  characteristicArray.append(characteristic)
            /*
              let s = "\(characteristic) \(characteristic.properties)"
             print(s)
             tv.text += "\n\(s)"
             tv.scrollToBottom()
             if characteristic.properties.contains(.read) {
                 tv.text += "read "
             }
             if characteristic.properties.contains(.write) {
                 tv.text += "write "
             }
             if characteristic.properties.contains(.writeWithoutResponse) {
                 tv.text += "writeWithoutResponse "
             }
             if characteristic.properties.contains(.notify) {
                 tv.text += "notify"
             }
             tv.text += "\n"
             */
            // ii = ii + 1
            // }
            characteristicArray.append(contentsOf: service.characteristics ?? [])
            if blePhase == .DISCOVER {
                tmpPickerIndex = 0
                picker.selectRow(tmpPickerIndex, inComponent: 0, animated: true)
                picker.reloadAllComponents()
            }

            if blePhase == .DISCOVERED {
                for c in characteristicArray {
//                    print(c.uuid.uuidString)
                    if c.uuid.uuidString == Globals.shared.deviceBleWriteCharacteristicUuid {
                        selectedWriteCharacteristic = c
                        debug2("found selected write characteristic \(c.uuid)")
                        // peripheral.discoverDescriptors(for: characteristics)
                    }
                    if c.uuid.uuidString == Globals.shared.deviceBleReadCharacteristicUuid {
                        selectedReadCharacteristic = c
                        debug2("found selected notify characteristic \(c.uuid)")
                        if c.properties.contains(.notify) {
//                            for c in selectedService.characteristics! {
//                              selectedPeripheral.blePeripheral.setNotifyValue(false, for: c)
//                            }
                            selectedPeripheral.blePeripheral.setNotifyValue(true, for: c)
                        }
                        // peripheral.discoverDescriptors(for: characteristics)
                    }

                    if selectedReadCharacteristic != nil, selectedWriteCharacteristic != nil {
                        debug2("trovati")
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
        } else {
            // print("\(Date().description(with: Locale.current)) didWriteValueFor \(peripheral.name ?? "") \(characteristic.uuid) \(error?.localizedDescription ?? "")")
            // print("didWriteValueFor \(peripheral.name!) \(characteristic.uuid)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // print("\(Date().description(with: Locale.current)) didUpdateValueFor \(characteristic.uuid) \(error?.localizedDescription ?? "")")
        if error != nil {
            print(error?.localizedDescription as Any)
            return
        } else if characteristic.uuid.uuidString == selectedReadCharacteristic.uuid.uuidString {
            let s = String(data: characteristic.value!, encoding: .utf8)
            if s?.last == ">" {
                lastRxString += s!
                var reply = lastRxString.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines.inverted)
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

                lastRxString = ""
            } else {
                lastRxString += s ?? ""
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
            debug2(error!.localizedDescription)
        } else {
            let s = "didDiscoverDescriptorsFor \(characteristic.uuid)"
            debug2(s)
            debug2("characteristic.descriptors \(characteristic.descriptors!)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {}

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            debug2("error didUpdateNotificationStateFor characteristic \(characteristic.uuid.uuidString): \(error?.localizedDescription as Any)")
        } else {
            let s = "didUpdateNotificationStateFor \(characteristic.uuid)"
            debug2(s)
            //   tv.text += "\n\(s)"
            //   tv.scrollToBottom()
        }
    }
}
