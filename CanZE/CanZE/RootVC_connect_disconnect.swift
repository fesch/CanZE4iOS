//
//  RootVC_connect_disconnect.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 25/02/21.
//

import Foundation
import UIKit

extension RootViewController {
    @IBAction func btnConnect() {
        if Globals.shared.deviceIsConnected {
            disconnect(showToast: true)
            deviceDisconnected()
        } else {
            startAutoInit()
        }
    }

    func connect() {
        if !deviceIsConnectable() {
            view.hideAllToasts()
            view.makeToast("_please configure")
            return
        }

        print("connecting")

        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        vBG.tag = Globals.K_TAG_vBG
        view.addSubview(vBG)

        view.hideAllToasts()

        var s = ""

        switch Globals.shared.deviceType {
        case .ELM327:
            s += "DEVICE_TYPE_ELM327\n"
        case .CANSEE:
            s += "DEVICE_TYPE_CANSEE\n"
        case .HTTP_GW:
            s += "DEVICE_TYPE_HTTP_GW\n"
        default:
            s += "unknown\n"
        }

        switch Globals.shared.deviceConnection {
        case .BLE:
            s += "DEVICE_CONNECTION_BLE\n"
            switch Globals.shared.deviceBleName {
            case .VGATE:
                s += "VGATE\n"
            case .LELINK:
                s += "LELINK\n"
            default:
                s += "unknown\n"
            }
        case .WIFI:
            s += "DEVICE_CONNECTION_WIFI\n"
            s += Globals.shared.deviceWifiAddress + "\n"
            s += Globals.shared.deviceWifiPort + "\n"
        case .HTTP:
            s += "DEVICE_CONNECTION_HTTP\n"
            s += Globals.shared.deviceHttpAddress + "\n"
        default:
            s += "unknown\n"
        }

        view.makeToast("_connecting, wait for initialize\n\(s)")

        if Globals.shared.deviceIsConnected {
            disconnect(showToast: false)
        }
        switch Globals.shared.deviceConnection {
        case .BLE:
            connectBle()
        case .WIFI:
            connectWifi()
        case .HTTP:
            Globals.shared.deviceIsConnected = true
            Globals.shared.deviceIsInitialized = true
            deviceConnected()
            if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
                vBG.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
        default:
            break
        }
    }

    @objc func connected() {
        Globals.shared.deviceIsConnected = true
        NotificationCenter.default.post(name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("connected"), object: nil)
        if Globals.shared.deviceType == .ELM327 {
            NotificationCenter.default.addObserver(self, selector: #selector(autoInit), name: Notification.Name("autoInit"), object: nil)
            initDeviceELM327()
        } else {
            if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
                vBG.removeFromSuperview()
            }
            view.hideAllToasts()
            view.makeToast("connected")
            Globals.shared.deviceIsInitialized = true
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
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

    func disconnect(showToast: Bool) {
        print("disconnecting")
        Globals.shared.queue2 = []
        Globals.shared.lastId = 0

        if Globals.shared.timeoutTimer != nil {
            if Globals.shared.timeoutTimer.isValid {
                Globals.shared.timeoutTimer.invalidate()
            }
            Globals.shared.timeoutTimer = nil
        }
        if Globals.shared.timeoutTimerBle != nil {
            if Globals.shared.timeoutTimerBle.isValid {
                Globals.shared.timeoutTimerBle.invalidate()
            }
            Globals.shared.timeoutTimerBle = nil
        }
        if Globals.shared.timeoutTimerWifi != nil {
            if Globals.shared.timeoutTimerWifi.isValid {
                Globals.shared.timeoutTimerWifi.invalidate()
            }
            Globals.shared.timeoutTimerWifi = nil
        }

        if showToast {
            DispatchQueue.main.async { [self] in
                view.hideAllToasts()
                view.makeToast("_disconnecting")
            }
        }
        switch Globals.shared.deviceConnection {
        case .BLE:
            disconnectBle()
        case .WIFI:
            disconnectWifi()
        default:
            break
        }

        Globals.shared.deviceIsConnected = false
        Globals.shared.deviceIsInitialized = false
        deviceDisconnected()
        Globals.shared.fieldResultsDouble = [:]
        Globals.shared.fieldResultsString = [:]
        Globals.shared.resultsBySid = [:]

        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }
    }

    @objc func deviceDisconnected() {
        if navigationItem.rightBarButtonItems != nil {
            for b in navigationItem.rightBarButtonItems! {
                if b.title == "deviceConnect" {
                    b.image = UIImage(named: "device_disconnected")
                    break
                }
            }
        }
    }

    func deviceIsConnectable() -> Bool {
        var connectable = false
        if Globals.shared.deviceType == .ELM327 || Globals.shared.deviceType == .CANSEE || Globals.shared.deviceType == .HTTP_GW {
            if Globals.shared.deviceConnection == .BLE, Globals.shared.deviceBlePeripheralName != "", Globals.shared.deviceBlePeripheralUuid != "", Globals.shared.deviceBleServiceUuid != "", Globals.shared.deviceBleReadCharacteristicUuid != "", Globals.shared.deviceBleWriteCharacteristicUuid != "" {
                connectable = true
            } else if Globals.shared.deviceConnection == .WIFI, Globals.shared.deviceWifiAddress != "", Globals.shared.deviceWifiPort != "" {
                connectable = true
            } else if Globals.shared.deviceConnection == .HTTP, Globals.shared.deviceHttpAddress != "" {
                connectable = true
            }
        }
        return connectable
    }

    func write(s: String) {
        Globals.shared.lastReply = ""
        switch Globals.shared.deviceConnection {
        case .BLE:
            writeBle(s: s)
        case .WIFI:
            writeWifi(s: s)
        case .HTTP:
            writeHttp(s: s)
        case .NONE:
            print("device connection unknown")
            return
        }
    }
}
