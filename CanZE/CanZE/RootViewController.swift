//
//  RootViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/02/21.
//

import CoreBluetooth
import UIKit

class RootViewController: UIViewController {
    let ud = UserDefaults.standard

    // init elm327
    let autoInitElm327: [String] = ["ate0", "ats0", "ath0", "atl0", "atal", "atcaf0", "atfcsh77b", "atfcsd300000", "atfcsm1", "atsp6"]

    var timeoutTimer: Timer!

    // queue
    //var queue: [String] = []
    var queueInit: [String] = []
    var queue2: [Sequence] = []
    var indiceCmd = 0
    var lastRxString = ""
    var lastId = -1
    var lastDebugMessage = ""

    var pickerTitles: [String]? = []
    var pickerValues: [Any]? = []
    enum PickerPhase: String {
        case PERIPHERAL
        case SERVICES
        case WRITE_CHARACTERISTIC
        case READ_CHARACTERISTIC
    }

    var pickerPhase: PickerPhase = .PERIPHERAL

    // WIFI
    var timeoutTimerWifi: Timer!
    let maxReadLength = 4096

    // BLE
    var centralManager: CBCentralManager!
    var timeoutTimerBle: Timer!
    enum BlePhase: String {
        case DISCOVER
        case DISCOVERED
    }

    var blePhase: BlePhase = .DISCOVERED

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    func debug(_ s: String) {
        print(s)
        if Globals.shared.useSdCard {
            Globals.shared.logger.add(s)
        }
    }

    @objc func deviceConnected() {
        if navigationItem.rightBarButtonItems != nil {
            for b in navigationItem.rightBarButtonItems! {
                if b.title == "deviceConnect" {
                    b.image = UIImage(named: "device_connected")
                    break
                }
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
            if aStream == Globals.shared.inputStream {
                readAvailableBytes(stream: aStream as! InputStream)
            }
        case .endEncountered:
            debug("\(aStream) endEncountered")
        case .hasSpaceAvailable:
            //  if aStream == Globals.shared.outputStream {}
            print("")
        case .errorOccurred:
            debug("\(aStream) errorOccurred")
        case .openCompleted:
            debug("\(aStream) openCompleted")
        default:
            debug("\(aStream) \(eventCode.rawValue)")
        }
    }

    private func readAvailableBytes(stream: InputStream) {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxReadLength)
        while stream.hasBytesAvailable {
            let numberOfBytesRead = Globals.shared.inputStream.read(buffer, maxLength: maxReadLength)
            if numberOfBytesRead < 0, let error = stream.streamError {
                debug(error.localizedDescription)
                break
            }
            var string = String(
                bytesNoCopy: buffer,
                length: numberOfBytesRead,
                encoding: .utf8,
                freeWhenDone: true)
            if string != nil, string!.count > 0 {
                string = string!.trimmingCharacters(in: .whitespacesAndNewlines)
                string = String(string!.filter { !">".contains($0) })
                string = String(string!.filter { !"\r".contains($0) })

                if Globals.shared.deviceType == .CANSEE {
                    let a = string!.components(separatedBy: ",")
                    if a.count > 0 {
                        string = a.last!
                    }
                }

                if string!.count > 0 {
                    let dic: [String: String] = ["reply": string!]
                    NotificationCenter.default.post(name: Notification.Name("didReceiveFromWifiDongle"), object: dic)
                }
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
            centralManager.scanForPeripherals(withServices: [])
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

        if blePhase == .DISCOVERED, Globals.shared.deviceBlePeripheralName == p.blePeripheral.name {
            if timeoutTimerBle != nil {
                if timeoutTimerBle.isValid {
                    timeoutTimerBle.invalidate()
                }
                timeoutTimerBle = nil
            }
            centralManager.stopScan()
            p.blePeripheral.delegate = self
            Globals.shared.selectedPeripheral = p
            debug("found selected Peripheral \(Globals.shared.selectedPeripheral.blePeripheral.name ?? "")")
            centralManager.connect(Globals.shared.selectedPeripheral.blePeripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debug("didConnect \(peripheral.name ?? "?") \(peripheral.identifier.uuidString)")
        Globals.shared.servicesArray = []
        pickerPhase = .SERVICES
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

        if blePhase == .DISCOVERED {
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

            if blePhase == .DISCOVERED {
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
                lastRxString += s!

                var reply = lastRxString.trimmingCharacters(in: .whitespacesAndNewlines)
                reply = String(reply.filter { !">".contains($0) })
                reply = String(reply.filter { !"\r".contains($0) })

                NotificationCenter.default.post(name: Notification.Name("received"), object: ["reply": reply])
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
