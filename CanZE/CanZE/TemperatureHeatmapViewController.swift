//
//  TemperatureHeatmapViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 03/02/21.
//

import UIKit

class TemperatureHeatmapViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    ///

    var mean = 0.0
    let lastCell = 12
    var lastVal: [Double] = [0, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15]

    let baseColor = UIColor.lightGray.withAlphaComponent(0.5)

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_heatmap_bat", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        for n in 1001 ..< 1013 {
            if let v = view.viewWithTag(n) {
                let vv = v as! UILabel
                vv.text = "-"
                vv.backgroundColor = baseColor
            } else {
                print("view not found")
            }
        }
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
                view.makeToast(NSLocalizedString_("Device not connected", comment: ""))
            }
            return
        }

        Globals.shared.queue2 = []
        Globals.shared.lastId = 0

        for i in 1 ..< lastCell+1 {
            let sid = "\(Sid.Preamble_CompartmentTemperatures)\(8+i * 24)" // remember, first is pos 16, i starts s at 1
            addField(sid, intervalMs: 99999)
        }

        startQueue2()
    }

    @objc func endQueue2() {
        // startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]
        let field = Fields.getInstance.fieldsBySid[sid!]

        let fieldId = sid!
        var cell = 0
        if fieldId.hasPrefix(Sid.Preamble_CompartmentTemperatures) {
            cell = (Int(fieldId.components(separatedBy: ".")[2])! - 8)/24 // cell is 1-based
            let value = field?.getValue()
            if value != nil, !value!.isNaN {
                if cell < lastVal.count {
                    DispatchQueue.main.async { [self] in
                        if let tv = view.viewWithTag(cell+1000) {
                            let tv2 = tv as! UILabel
                            tv2.text = String(format: "%.1f", value!)
                        }
                    }

                    lastVal[cell] = value!
                    if cell == lastCell {
                        for i in 1 ..< lastCell+1 {
                            mean += lastVal[i]
                        }
                        mean /= Double(lastCell)

                        // the update has to be done in a separate thread
                        // otherwise the UI will not be repainted
                        for i in 1 ..< lastCell+1 {
                            DispatchQueue.main.async { [self] in
                                if let tv = view.viewWithTag(i+1000) {
                                    let tv2 = tv as! UILabel
                                    // tv.setText(String.format("%.3f", lastVoltage[i]));
                                    //                                tv2.text = String(format: "%.1f", lastVal[i])
                                    let delta = Int(50 * (lastVal[i] - mean)) // color is temp minus mean
                                    tv2.backgroundColor = makeColor(delta)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func makeColor(_ delta2: Int) -> UIColor {
        var delta = delta2

        if delta > 62 {
            delta = 62
        } else if delta < -62 {
            delta = -62
        }

        if delta > 0 {
            var c = baseColor.rgba
            c.green -= CGFloat(delta)/224.0
            c.blue -= CGFloat(delta)/224.0
            let color = UIColor(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
            return color
            // return baseColor - (delta * 0x000101) // one tick is one red
        } else {
            var c = baseColor.rgba
            c.red += CGFloat(delta)/224.0
            c.green += CGFloat(delta)/224.0
            let color = UIColor(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
            return color
            // return baseColor+(delta * 0x010100) // one degree below is a 16th blue added
        }
    }
}
