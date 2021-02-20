//
//  _Test_Peripheral.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import CoreBluetooth

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
                    debug( "found selected service \(selectedService.uuid)")
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
                        debug( "found selected write characteristic \(c.uuid)")
                        // peripheral.discoverDescriptors(for: characteristics)
                    }
                    if c.uuid.uuidString == Globals.shared.deviceBleReadCharacteristicUuid {
                        selectedReadCharacteristic = c
                        debug( "found selected notify characteristic \(c.uuid)")
                        if c.properties.contains(.notify) {
//                            for c in selectedService.characteristics! {
//                              selectedPeripheral.blePeripheral.setNotifyValue(false, for: c)
//                            }
                            selectedPeripheral.blePeripheral.setNotifyValue(true, for: c)
                        }
                        // peripheral.discoverDescriptors(for: characteristics)
                    }

                    if selectedReadCharacteristic != nil, selectedWriteCharacteristic != nil {
                        debug( "trovati")
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

                var reply = lastRxString.trimmingCharacters(in: .whitespacesAndNewlines)
                reply = String(reply.filter { !">".contains($0) })
                reply = String(reply.filter { !"\r".contains($0) })

                let dic: [String: String] = ["reply": reply]

//                var ss = String(lastRxString.filter { !"\r".contains($0) })
//                ss = String(ss.filter { !"\n".contains($0) })
//                ss = String(ss.filter { !">".contains($0) })
                //  ss = ss.trimmingCharacters(in: .whitespacesAndNewlines)

                NotificationCenter.default.post(name: Notification.Name("received"), object: dic)
                lastRxString = ""
//                if queue.count > 0, timeoutTimer != nil, timeoutTimer.isValid {
//                    timeoutTimer.invalidate()
                // print("reply ricevuta")
//                    continueQueue()
//                }
            } else {
                lastRxString += s ?? ""
                // print(".")
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
            debug( error!.localizedDescription)
        } else {
            let s = "didDiscoverDescriptorsFor \(characteristic.uuid)"
            debug( s)
            debug( "characteristic.descriptors \(characteristic.descriptors!)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {}

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            debug( "error didUpdateNotificationStateFor characteristic \(characteristic.uuid.uuidString): \(error?.localizedDescription as Any)")
        } else {
            let s = "didUpdateNotificationStateFor \(characteristic.uuid)"
            debug( s)
            //   tv.text += "\n\(s)"
            //   tv.scrollToBottom()
        }
    }
}
