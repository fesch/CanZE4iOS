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
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label: UILabel
        if let view = view as? UILabel { label = view }
        else { label = UILabel() }

        var title = ""
        if pickerPhase == .PERIPHERAL {
            let p = peripheralsArray[row]
            title = "\(p.blePeripheral.name ?? "?") \(p.rssi ?? 0)"
        } else if pickerPhase == .SERVICES {
            let p = servicesArray[row]
//            return "\(p.uuid) \(p.characteristics?.count ?? 0) characteristics"
            title = "\(p.uuid)"
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
            title = "\(p.uuid) \(properties)"
        } else {
            title = ""
        }

        label.text = title
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15)
        label.adjustsFontSizeToFitWidth = false
        label.numberOfLines = 0
        label.lineBreakMode = .byCharWrapping
        label.minimumScaleFactor = 0.15
        label.frame = CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 1000)

        return label
    }

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
}
