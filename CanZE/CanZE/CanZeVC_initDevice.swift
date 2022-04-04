//
//  CanZeVC_initDevice.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 25/02/21.
//

import Foundation

extension CanZeViewController {
    func initDeviceELM327() {
        Globals.shared.queueInit = []
        for s in Globals.shared.autoInitElm327 {
            Globals.shared.queueInit.append(s)
        }
        processQueueInit()
    }
    
    @objc func autoInit() {
        Globals.shared.deviceIsInitialized = true
        NotificationCenter.default.removeObserver(self, name: Notification.Name("autoInit"), object: nil)
        
        if let vBG = view.viewWithTag(Globals.K_TAG_vBG) {
            vBG.removeFromSuperview()
        }
        
        view.makeToast(NSLocalizedString_("Connected and initialized", comment: ""))
    }
    
    func processQueueInit() {
        if Globals.shared.queueInit.count == 0 {
            print("END")
            Globals.shared.deviceIsInitialized = true
            NotificationCenter.default.post(name: Notification.Name("autoInit"), object: nil)
            return
        }
        if Globals.shared.timeoutTimer != nil, Globals.shared.timeoutTimer.isValid {
            Globals.shared.timeoutTimer.invalidate()
        }
        write(s: Globals.shared.queueInit.first!)
        Globals.shared.timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { timer in
            print("queue timeout !!!")
            timer.invalidate()
            return
        }
    }
    
    func continueQueueInit() {
        if Globals.shared.queueInit.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Globals.shared.deviceDelay) { [self] in
                Globals.shared.queueInit.remove(at: 0)
                processQueueInit()
            }
        }
    }

    func startAutoInit() {
        disconnect(showToast: false)
        NotificationCenter.default.addObserver(self, selector: #selector(connected), name: Notification.Name("connected"), object: nil)
        connect()
    }
    
    @objc func autoInit2() {
        autoInit()
        startQueue()
    }
}
