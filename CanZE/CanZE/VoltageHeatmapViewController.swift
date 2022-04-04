//
//  VoltageHeatmapViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 03/02/21.
//

import UIKit

class VoltageHeatmapViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    ///

    @IBOutlet var label_CellVoltageTop: UILabel!
    @IBOutlet var text_CellVoltageTop: UILabel!
    @IBOutlet var label_CellVoltageBottom: UILabel!
    @IBOutlet var text_CellVoltageBottom: UILabel!
    @IBOutlet var label_CellVoltageDelta: UILabel!
    @IBOutlet var text_CellVoltageDelta: UILabel!

    let baseColor = UIColor.lightGray.withAlphaComponent(0.5)

    var mean = 0.0
    var lowest = 0.0
    var highest = 0.0
    let lastCell = 96
    var lastVoltage: [Double] = [0, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4]
    var cutoff = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_heatmap_cellvoltage", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        label_CellVoltageTop.text = NSLocalizedString_("label_CellVoltageTop", comment: "")
        text_CellVoltageTop.text = "-"
        label_CellVoltageBottom.text = NSLocalizedString_("label_CellVoltageBottom", comment: "")
        text_CellVoltageBottom.text = "-"
        label_CellVoltageDelta.text = NSLocalizedString_("label_CellVoltageDelta", comment: "")
        text_CellVoltageDelta.text = "-"

        for n in 1001 ..< 1097 {
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

        for i in 1 ..< 63 {
            let sid = "\(Sid.Preamble_CellVoltages1)\(i * 16)" // remember, first is pos 16, i starts s at 1
            addField(sid, intervalMs: 0)
        }
        for i in 63 ..< 97 {
            let sid = "\(Sid.Preamble_CellVoltages2)\((i - 62) * 16)" // remember, first is pos 16, i starts s at 1
            addField(sid, intervalMs: 0)
        }

        startQueue2()
    }

    @objc func endQueue2() {
        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]
        let field = Fields.getInstance.fieldsBySid[sid!]

        let fieldId = sid!
        var cell = 0
        if fieldId.hasPrefix(Sid.Preamble_CellVoltages1) {
            cell = Int(fieldId.components(separatedBy: ".")[2])! / 16 // cell is 1-based
        } else if fieldId.hasPrefix(Sid.Preamble_CellVoltages2) {
            cell = Int(fieldId.components(separatedBy: ".")[2])! / 16 + 62 // cell is 1-based
        }
        if cell > 0, cell <= lastCell {
            let value = field?.getValue()

            DispatchQueue.main.async { [self] in
                if let tv = view.viewWithTag(cell + 1000) {
                    let tv2 = tv as! UILabel
                    tv2.text = String(format: "%.3f", value!)
                }
            }

            lastVoltage[cell] = value!
            if cell == lastCell {
                mean = 0
                lowest = 5
                highest = 3
                // lastVoltage[20] = 3.5; fake for test
                for i in 1 ..< lastCell + 1 {
                    mean += lastVoltage[i]
                    if lastVoltage[i] < lowest {
                        lowest = lastVoltage[i]
                    }
                    if lastVoltage[i] > highest {
                        highest = lastVoltage[i]
                    }
                }
                mean /= Double(lastCell)
                cutoff = lowest < 3.712 ? mean - (highest - mean) * 1.5 : 2

                // the update has to be done in a separate thread
                // otherwise the UI will not be repainted
                for i in 1 ..< lastCell + 1 {
                    DispatchQueue.main.async { [self] in
                        if let tv = view.viewWithTag(i + 1000) {
                            let tv2 = tv as! UILabel
                            // tv.setText(String.format("%.3f", lastVoltage[i]));
//                            if i < lastVoltage.count, lastVoltage[i] != Double.nan {
//                                tv2.text = String(format: "%.3f", lastVoltage[i])
//                            }
                            if !lastVoltage[i].isNaN {
                                let delta = Int(10000 * (lastVoltage[i] - mean)) // color is temp minus mean. 1mV difference is 5 color ticks
                                tv2.backgroundColor = makeColor(delta)
                            }
                        }
                    }
                }

                // Only update the high-low if we have realistic data
                if highest >= lowest {
                    DispatchQueue.main.async { [self] in
                        text_CellVoltageTop.text = String(format: "%.3f", highest)
                        text_CellVoltageBottom.text = String(format: "%.3f", lowest)
                        text_CellVoltageDelta.text = String(format: "%.0f", 1000 * (highest - lowest)) //  Math.round
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
            c.green -= CGFloat(delta) / 224.0
            c.blue -= CGFloat(delta) / 224.0
            let color = UIColor(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
            return color
            // return baseColor - (delta * 0x000101) // one tick is one red
        } else {
            var c = baseColor.rgba
            c.red += CGFloat(delta) / 224.0
            c.green += CGFloat(delta) / 224.0
            let color = UIColor(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
            return color
            // return baseColor+(delta * 0x010100) // one degree below is a 16th blue added
        }
    }
}
