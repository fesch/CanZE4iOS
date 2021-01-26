//
//  _Test_CentralManager.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import CoreBluetooth

// MARK: CBCentralManagerDelegate

extension TestViewController: CBCentralManagerDelegate {
    // CentralManager
    // CentralManager
    // CentralManager
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            debug(s: "central.state is .unknown")
        case .resetting:
            debug(s: "central.state is .resetting")
        case .unsupported:
            debug(s: "central.state is .unsupported")
        case .unauthorized:
            debug(s: "central.state is .unauthorized")
        case .poweredOff:
            debug(s: "central.state is .poweredOff")
        case .poweredOn:
            debug(s: "central.state is .poweredOn")
            //            centralManager.scanForPeripherals(withServices: [serviceCBUUID])
            centralManager.scanForPeripherals(withServices: [])
        @unknown default:
            debug(s: "central.state is unknown")
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
                debug(s: "discovered \(peripheral.name ?? "?")")
                peripheralsArray.append(p)
                picker.reloadAllComponents()
            }
        }
        //        peripheralsArray.sort { (a:Peripheral, b:Peripheral) -> Bool in
        //            a.peripheral.name ?? "" < b.peripheral.name ?? ""
        //        }

        if blePhase == .DISCOVERED, AppSettings.shared.deviceBlePeripheralIdentifierUuid == p.blePeripheral.identifier.uuidString {
            timeoutTimerBle.invalidate()
            centralManager.stopScan()
            p.blePeripheral.delegate = self
            selectedPeripheral = p
            debug(s: "found selected Peripheral \(selectedPeripheral.blePeripheral.name ?? "")")
            centralManager.connect(selectedPeripheral.blePeripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debug(s: "didConnect \(peripheral.name ?? "?") \(peripheral.identifier.uuidString)")
        servicesArray = []
        pickerPhase = .SERVICES
        tmpPickerIndex = 0
        //  peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debug(s: "didFailToConnect \(peripheral) \(error?.localizedDescription ?? "")")
    }

    func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
        debug(s: "connectionEventDidOccur \(peripheral)")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debug(s: "didDisconnectPeripheral \(peripheral.name ?? "")")
    }

    func centralManager(_ central: CBCentralManager, didUpdateANCSAuthorizationFor peripheral: CBPeripheral) {}

    //    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    //    }
}
