//
//  SpeedControlViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 10/02/21.
//

import UIKit

class SpeedControlViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var title_: UILabel!
    @IBOutlet var speed_: UILabel!
    @IBOutlet var unit: UILabel!
    @IBOutlet var textLog: UILabel!
    @IBOutlet var textDetails: UILabel!

    var timeStart = 0
    var timeLast = 0
    var distanceStart = 0.0
    var distanceEnd = 0.0
    var distanceLast = 0.0
    var distanceInterpolated = 0.0
    var speed = 0.0
    var go = false
    var km = ""
    var mi = ""
    var kmh = ""
    var mih = ""
    let speedformat = "%.0f" // feel free to change back. Experiment to make less jumpy

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_speedcontrol", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        km = NSLocalizedString_("unit_Km", comment: "")
        mi = NSLocalizedString_("unit_Mi", comment: "")
        kmh = NSLocalizedString_("unit_SpeedKm", comment: "")
        mih = NSLocalizedString_("unit_SpeedMi", comment: "")

        title_.text = NSLocalizedString_("label_averageSpeed", comment: "")
        speed_.text = "-"
        unit.text = NSLocalizedString_("label_TapToStart", comment: "")
        textLog.text = ""
        textDetails.text = ""
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(decoded(notification:)), name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endQueue2), name: Notification.Name("endQueue2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(autoInit2), name: Notification.Name("autoInit"), object: nil)

        startQueue()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("endQueue2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("autoInit"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc func updateDebugLabel(notification: Notification) {
        let notificationObject = notification.object as? [String: String]
        DispatchQueue.main.async { [self] in
            lblDebug.text = notificationObject?["debug"]
        }
        debug((notificationObject?["debug"])!)
    }

    override func startQueue() {
        if !Globals.shared.deviceIsConnected || !Globals.shared.deviceIsInitialized {
            DispatchQueue.main.async { [self] in
                view.makeToast("_device not connected")
            }
            return
        }

        queue2 = []

        addField(Sid.TripMeterB, intervalMs: 100)
        addField(Sid.RealSpeed, intervalMs: 100)

        startQueue2()
    }

    @objc func endQueue2() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            startQueue()
        }
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let val = Globals.shared.fieldResultsDouble[sid!]
        if val != nil && !val!.isNaN {
            DispatchQueue.main.async { [self] in
                switch sid {
                case Sid.RealSpeed:
                    speed = val!
                case Sid.TripMeterB:
                    distanceEnd = val!
                    let timeEnd = Date().timeIntervalSince1970
                    // if starting time has been set
                    if go {
                        // speed measuring has been started normally
                        if timeStart != 0 {
                            var speedCalc = 0.0

                            // only update if distance changed ...
                            if distanceLast != distanceEnd {
                                distanceInterpolated = distanceEnd
                                // calculate avg speed
                                let speed = ((distanceEnd - distanceStart) * 3600.0) / (timeEnd - Double(timeStart))
                                // show it
                                speed_.text = String(format: speedformat, speed)
                            } else { // interpolate distance using the speed
                                // get difference in distance
                                let distanceDelta = speed * (timeEnd - Double(timeLast)) / 3600.0
                                // add it to the last interpolated distance
                                distanceInterpolated += distanceDelta

                                // at least 100m should have been driven in order to
                                // avoid "jumping" values
                                if distanceEnd - distanceStart > 0.1 {
                                    // calculate avg speed
                                    speedCalc = ((distanceInterpolated - distanceStart) * 3600.0) / (timeEnd - Double(timeStart))
                                    // show it
                                    speed_.text = String(format: speedformat, speedCalc)
                                }
                            }

                            // clear the clutter
                            #if targetEnvironment(simulator)
                            let x = "\(String(format: "Distance:%.2f", distanceEnd - distanceStart))\(Globals.shared.milesMode ? mi : km)"
                            let y = "Time:\(timeToStr(timeStart)) > \(timeToStr(Int(timeEnd))) = \(timeToStr(Int(timeEnd) - timeStart))"
                            let z1 = "\(String(format: "Speed:%.2f", speed))\(Globals.shared.milesMode ? mih : kmh)"
                            let z2 = "\(String(format: "SpeedCalc:%.2f", speedCalc))\(Globals.shared.milesMode ? mih : kmh)"
                            textDetails.text = "\(x) - \(y) - \(z1) - \(z2)"
                            #else
                            // added to remove "waiting for second value" when on master branch
                            textDetails.text = ""
                            #endif
                            distanceLast = distanceEnd
                            timeLast = Int(timeEnd)
                        } else if distanceLast == 0 {
                            // do nothing ...
                            textDetails.text = NSLocalizedString_("message_gotfirst", comment: "")
                            distanceLast = distanceEnd
                        } else if distanceLast != distanceEnd {
                            // set starting distance as long as starting time is not set
                            distanceStart = distanceEnd
                            distanceLast = distanceEnd
                            distanceInterpolated = distanceEnd
                            // set start time
                            timeStart = Int(timeEnd)
                            timeLast = Int(timeEnd)
                            textDetails.text = NSLocalizedString_("message_gotsecond", comment: "")
                        } else {
                            textDetails.text = NSLocalizedString_("message_waitsecond", comment: "")
                        }
                    }
                default:
                    print("unknown sid \(sid!)")
                }
            }
        }
    }

    func timeToStr(_ time: Int) -> String {
        var r = ""
        let x = secondsToHoursMinutesSeconds(seconds: time)
        r = String(format: "%02d:%02d:%02d", x.0, x.1, x.2)
        return r
    }

    func secondsToHoursMinutesSeconds(seconds: Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }

    @IBAction func oc() {
        // reset
        timeStart = 0
        distanceLast = 0
        go = true
        var speedNow = speed_.text
        speed_.text = "..."
        if speedNow != "-", speedNow != "..." {
            let df = DateFormatter()
            df.dateStyle = .short
            df.timeStyle = .medium
            let time = df.string(from: Date())
            speedNow = "\(time): \(speedNow!) \(Globals.shared.milesMode ? mih : kmh)\n\(textLog.text ?? "")"
            textLog.text = speedNow
        }
        unit.text = Globals.shared.milesMode ? mih : kmh
    }
}
