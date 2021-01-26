//
//  _Test2.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import UIKit

extension TestViewController: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tmpPickerIndex = row
    }
}

// MARK: UIPickerViewDataSource

extension TestViewController: UIPickerViewDataSource {
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerPhase == .PERIPHERAL {
            return peripheralsArray.count
        } else if pickerPhase == .SERVICES {
            return servicesArray.count
        } else if pickerPhase == .READ_CHARACTERISTIC || pickerPhase == .WRITE_CHARACTERISTIC {
            return characteristicArray.count
        } else {
            return 0
        }
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerPhase == .PERIPHERAL {
            let p = peripheralsArray[row]
            return "\(p.blePeripheral.name ?? "?") \(p.rssi ?? 0)"
        } else if pickerPhase == .SERVICES {
            let p = servicesArray[row]
//            return "\(p.uuid) \(p.characteristics?.count ?? 0) characteristics"
            return "\(p.uuid)"
        } else if pickerPhase == .READ_CHARACTERISTIC || pickerPhase == .WRITE_CHARACTERISTIC {
            let p = characteristicArray[row]
            var properties = ""
            if p.properties.contains(.read) {
                if properties.count > 0 {
                    properties += ","
                }
                properties += "read"
            }
            if p.properties.contains(.write) {
                if properties.count > 0 {
                    properties += ","
                }
                properties += "write"
            }
            if p.properties.contains(.writeWithoutResponse) {
                if properties.count > 0 {
                    properties += ","
                }
                properties += "writeWithoutResponse"
            }
            if p.properties.contains(.notify) {
                if properties.count > 0 {
                    properties += ","
                }
                properties += "notify"
            }
            return "\(p.uuid) \(properties)"
        } else {
            return ""
        }
    }
}
