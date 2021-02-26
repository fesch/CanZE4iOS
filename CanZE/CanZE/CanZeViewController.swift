//
//  CanZeViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/12/20.
//

import CoreBluetooth
import UIKit

class CanZeViewController: RootViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print("CanZeViewController")

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(deviceConnected), name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deviceDisconnected), name: Notification.Name("deviceDisconnected"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveFromWifiDongle(notification:)), name: Notification.Name("didReceiveFromWifiDongle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(received(notification:)), name: Notification.Name("received"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(received2(notification:)), name: Notification.Name("received2"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Globals.shared.deviceIsConnected {
            deviceConnected()
        } else {
            deviceDisconnected()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Globals.shared.queue2 = []
        Globals.shared.lastId = 0
        
        if Globals.shared.timeoutTimer != nil {
            if Globals.shared.timeoutTimer.isValid {
                Globals.shared.timeoutTimer.invalidate()
            }
            Globals.shared.timeoutTimer = nil
            //            disconnect(showToast: true)
        }
        if Globals.shared.timeoutTimerBle != nil {
            if Globals.shared.timeoutTimerBle.isValid {
                Globals.shared.timeoutTimerBle.invalidate()
            }
            Globals.shared.timeoutTimerBle = nil
            //            disconnect(showToast: true)
        }
        if Globals.shared.timeoutTimerWifi != nil {
            if Globals.shared.timeoutTimerWifi.isValid {
                Globals.shared.timeoutTimerWifi.invalidate()
            }
            Globals.shared.timeoutTimerWifi = nil
            //            disconnect(showToast: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceConnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("deviceDisconnected"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("didReceiveFromWifiDongle"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
    }
}
