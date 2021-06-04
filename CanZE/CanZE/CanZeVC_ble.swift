//
//  CanZeVC_ble.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import CoreBluetooth
import Foundation

extension CanZeViewController {
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
                        view.makeToast(NSLocalizedString_("Can't connect to ble device: TIMEOUT", comment: ""))
                    }
                }
            })
        }
        Globals.shared.centralManager = CBCentralManager(delegate: navigationController as? CBCentralManagerDelegate, queue: nil)
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
                    debug("> '\(s)'")
                } else if Globals.shared.selectedWriteCharacteristic.properties.contains(.writeWithoutResponse) {
                    Globals.shared.selectedPeripheral.blePeripheral.writeValue(data, for: Globals.shared.selectedWriteCharacteristic, type: .withoutResponse)
                    debug("> '\(s)'")
                } else {
                    debug("can't write to characteristic")
                }
            } else {
                debug("data is nil")
            }
        }
    }
}
