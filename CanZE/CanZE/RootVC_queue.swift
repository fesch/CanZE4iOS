//
//  RootVC_queue.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import Foundation
import UIKit

extension RootViewController {
    func startQueue2() {
        UIApplication.shared.isIdleTimerDisabled = true
        Globals.shared.indiceCmd = 0
        Globals.shared.lastId = -1
        processQueue2()
    }
 
    func processQueue2() {
        if Globals.shared.queue2.count == 0 {
            print("END queue2")
            UIApplication.shared.isIdleTimerDisabled = false
            NotificationCenter.default.post(name: Notification.Name("endQueue2"), object: nil)
            return
        }
     
        let seq = Globals.shared.queue2.first! as Sequence
     
        if Globals.shared.indiceCmd >= seq.cmd.count {
            //            if seq.frame != nil {
            //                seq.frame.lastRequest = Date().timeIntervalSince1970
            //            }
            if seq.field != nil {
                seq.field.lastRequest = Date().timeIntervalSince1970
            }
            Globals.shared.queue2.removeFirst()
            startQueue2()
            return
        }
        if Globals.shared.indiceCmd == 0, seq.field != nil {
            // new field
            let dic = ["debug": "Debug \(seq.field?.sid ?? "?") \(seq.field.name ?? "?")"]
            NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
            // debug("Debug \(seq.field?.sid ?? "")")
        }
     
        /*
         // cached ?
         if seq.field != nil {
         if let res = Globals.shared.resultsBySid[(seq.field.sid)!] {
         if Date().timeIntervalSince1970 - res.lastTimestamp < 1 { // TEST CACHED
         debug("cached")
      
         let dic = ["debug": "Debug \(seq.field.sid ?? "?") cached"]
         NotificationCenter.default.post(name: Notification.Name("updateDebugLabel"), object: dic)
      
         // notify real field
         var n: [String: String] = [:]
         n["sid"] = seq.field.sid
         NotificationCenter.default.post(name: Notification.Name("decoded"), object: n)
      
         lastId = -1
         queue2.removeFirst()
         startQueue2()
         return
         }
         }
         }
         */
     
        let cmd = seq.cmd[Globals.shared.indiceCmd]
        write(s: cmd)
     
        if Globals.shared.timeoutTimer != nil, Globals.shared.timeoutTimer.isValid {
            Globals.shared.timeoutTimer.invalidate()
            Globals.shared.timeoutTimer = nil
        }
     
        var contatore = 10
        Globals.shared.timeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            contatore -= 1
            print(contatore)
            if contatore < 1 {
                timer.invalidate()
                self.debug("queue2 timeout !!!")
                DispatchQueue.main.async { [self] in
                    disconnect(showToast: false)
                    view.hideAllToasts()
                    view.makeToast("TIMEOUT")
                }
                return
            }
        }
        Globals.shared.timeoutTimer.fire()
    }
 
    func continueQueue2() {
        Globals.shared.indiceCmd += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
            processQueue2()
        }
    }
    
    @objc func startQueue() {
        // stub
    }
}
