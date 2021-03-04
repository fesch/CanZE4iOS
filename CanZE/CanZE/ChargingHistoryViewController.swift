//
//  ChargingHistoryViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 06/02/21.
//

import UIKit

class ChargingHistoryViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var header_ChargingHistory: UILabel!

    @IBOutlet var label_distance: UILabel! // textKM1
    @IBOutlet var label_EndOfChargeStatus: UILabel! // textEND1
    @IBOutlet var label_TypeOfCharge: UILabel! // textTYP1
    @IBOutlet var label_EndSoc: UILabel! // textSOC1
    @IBOutlet var label_EndBatteryTemp: UILabel! // textTMP1
    @IBOutlet var label_HistDuration: UILabel! // textDUR1

    @IBOutlet var label_distance_: UILabel! // textKM1
    @IBOutlet var label_EndOfChargeStatus_: UILabel! // textEND1
    @IBOutlet var label_TypeOfCharge_: UILabel! // textTYP1
    @IBOutlet var label_EndSoc_: UILabel! // textSOC1
    @IBOutlet var label_EndBatteryTemp_: UILabel! // textTMP1
    @IBOutlet var label_HistDuration_: UILabel! // textDUR1

    @IBOutlet var header_ChargeSummary: UILabel!

    @IBOutlet var label_TotKwh: UILabel!
    @IBOutlet var textTotKwh: UILabel!

    @IBOutlet var label_TotKwhRegen: UILabel!
    @IBOutlet var textTotKwhRegen: UILabel!

    @IBOutlet var label_CountFull: UILabel!
    @IBOutlet var textCountFull: UILabel!

    @IBOutlet var label_CountPartial: UILabel!
    @IBOutlet var textCountPartial: UILabel!

    var charging_HistEnd: [String] = []
    var charging_HistTyp: [String] = []

    var km: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var end: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var typ: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var soc: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var tmp: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var dur: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_charging_history", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        charging_HistEnd = localizableFromPlist("list_ChargingHistEnd")
        charging_HistTyp = localizableFromPlist("list_ChargingHistTyp")

        header_ChargingHistory.text = NSLocalizedString_("header_ChargingHistory", comment: "")

        label_distance_.text = NSLocalizedString_("label_distance", comment: "")
        label_EndOfChargeStatus_.text = NSLocalizedString_("label_EndOfChargeStatus", comment: "")
        label_TypeOfCharge_.text = NSLocalizedString_("label_TypeOfCharge", comment: "")
        label_EndSoc_.text = NSLocalizedString_("label_EndSoc", comment: "")
        label_EndBatteryTemp_.text = NSLocalizedString_("label_EndBatteryTemp", comment: "")
        label_HistDuration_.text = NSLocalizedString_("label_HistDuration", comment: "")

        header_ChargeSummary.text = NSLocalizedString_("header_ChargeSummary", comment: "")

        label_TotKwh.text = NSLocalizedString_("label_TotKwh", comment: "")
        textTotKwh.text = "-"

        label_TotKwhRegen.text = NSLocalizedString_("label_TotKwhRegen", comment: "")
        textTotKwhRegen.text = "-"

        label_CountFull.text = NSLocalizedString_("label_CountFull", comment: "")
        textCountFull.text = "-"

        label_CountPartial.text = NSLocalizedString_("label_CountPartial", comment: "")
        textCountPartial.text = "-"

        updateDistance()
        updateEndOfChargeStatus()
        updateTypeOfCharge()
        updateEndSoc()
        updateEndBatteryTemp()
        updateDuration()
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

        Globals.shared.queue2 = []
        Globals.shared.lastId = 0

        for i in 0 ..< 10 {
            addField_("\(Sid.Preamble_KM)\(240 - i * 24)", intervalMs: 6000)
            addField_("\(Sid.Preamble_END)\(96 - i * 8)", intervalMs: 6000)
            addField_("\(Sid.Preamble_TYP)\(96 - i * 8)", intervalMs: 6000)
            addField_("\(Sid.Preamble_SOC)\(168 - i * 16)", intervalMs: 6000)
            addField_("\(Sid.Preamble_TMP)\(96 - i * 8)", intervalMs: 6000)
            addField_("\(Sid.Preamble_DUR)\(168 - i * 16)", intervalMs: 6000)
        }
        addField_(Sid.Total_kWh, intervalMs: 6000)
        if Utils.isPh2() {
            addField_(Sid.Total_Regen_kWh, intervalMs: 6000)
        }
        addField_(Sid.Counter_Full, intervalMs: 6000)
        addField_(Sid.Counter_Partial, intervalMs: 6000)

        startQueue2()
    }

    @objc func endQueue2() {
//        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let sidPreamble = sid!.subString(from: 0, to: 11) // 7e4.2233D4.
        let startBit = Int(sid!.subString(from: 11)) // 240 = 0 etc

        let val = Globals.shared.fieldResultsDouble[sid!]
        if val != nil && !val!.isNaN {
            DispatchQueue.main.async { [self] in
                switch sidPreamble {
                case Sid.Preamble_KM:
                    let indice = (264 - startBit!) / 24 - 1
                    km[indice] = val!
                    var s = ""
                    for i in 0 ..< 10 {
                        s += "\(String(format: "%.0f", km[i]))\n"
                    }
                    updateDistance()
                case Sid.Preamble_END:
                    let indice = (104 - startBit!) / 8 - 1
                    end[indice] = (val!.isNaN ? 0 : val)!
                    var s = ""
                    for i in 0 ..< 10 {
                        let ii = Int(end[i])
                        if ii < charging_HistEnd.count {
                            s += "\(charging_HistEnd[ii])\n"
                        } else if i < 10 {
                            s += "\n"
                        }
                    }
                    updateEndOfChargeStatus()
                case Sid.Preamble_TYP:
                    let indice = (104 - startBit!) / 8 - 1
                    typ[indice] = (val!.isNaN ? 0 : val)!
                    var s = ""
                    for i in 0 ..< 10 {
                        let ii = Int(typ[i])
                        if ii < charging_HistTyp.count {
                            s += "\(charging_HistTyp[ii])\n"
                        } else if i < 10 {
                            s += "\n"
                        }
                    }
                    updateTypeOfCharge()
                case Sid.Preamble_SOC:
                    let indice = (184 - startBit!) / 16 - 1
                    soc[indice] = (val!.isNaN ? 0 : val)!
                    var s = ""
                    for i in 0 ..< 10 {
                        s += "\(String(format: "%.0f", soc[i]))\n"
                    }
                    updateEndSoc()
                case Sid.Preamble_TMP:
                    let indice = (104 - startBit!) / 8 - 1
                    tmp[indice] = (val!.isNaN ? 0 : val)!
                    var s = ""
                    for i in 0 ..< 10 {
                        s += "\(String(format: "%.0f", tmp[i]))\n"
                    }
                    updateEndBatteryTemp()
                case Sid.Preamble_DUR:
                    let indice = (184 - startBit!) / 16 - 1
                    dur[indice] = (val!.isNaN ? 0 : val)!
                    var s = ""
                    for i in 0 ..< 10 {
                        s += "\(String(format: "%.0f", dur[i]))\n"
                    }
                    updateDuration()
                default:
                    switch sid {
                    case Sid.Total_kWh:
                        textTotKwh.text = String(format: "%.0f", val!)
                    case Sid.Total_Regen_kWh:
                        textTotKwhRegen.text = String(format: "%.0f", val!)
                    case Sid.Counter_Full:
                        textCountFull.text = String(format: "%.0f", val!)
                    case Sid.Counter_Partial:
                        textCountPartial.text = String(format: "%.0f", val!)
                    default:
                        if let f = Fields.getInstance.fieldsBySid[sid!] {
                            print("unknown sid \(sid!) \(f.name ?? "")")
                        } else {
                            print("unknown sid \(sid!)")
                        }
                    }
                }
            }
        }
    }

    func updateDistance() {
        var s = ""
        for i in 0 ..< 10 {
            s += "\(String(format: "%.0f", km[i]))\n"
        }
        if s.last == "\n" {
            s = s.subString(to: s.count - 1)
        }
        label_distance.text = s
    }

    func updateEndOfChargeStatus() {
        var s = ""
        for i in 0 ..< 10 {
            if Int(end[i]) < charging_HistEnd.count {
                s += "\(charging_HistEnd[Int(end[i])])\n"
            } else {
                s += "\n"
            }
        }
        if s.last == "\n" {
            s = s.subString(to: s.count - 1)
        }
        label_EndOfChargeStatus.text = s
    }

    func updateTypeOfCharge() {
        var s = ""
        for i in 0 ..< 10 {
            if Int(end[i]) < charging_HistTyp.count {
                s += "\(charging_HistTyp[Int(typ[i])])\n"
            } else {
                s += "\n"
            }
        }
        if s.last == "\n" {
            s = s.subString(to: s.count - 1)
        }
        label_TypeOfCharge.text = s
    }

    func updateEndSoc() {
        var s = ""
        for i in 0 ..< 10 {
            s += "\(String(format: "%.0f", soc[i]))\n"
        }
        if s.last == "\n" {
            s = s.subString(to: s.count - 1)
        }
        label_EndSoc.text = s
    }

    func updateEndBatteryTemp() {
        var s = ""
        for i in 0 ..< 10 {
            s += "\(String(format: "%.0f", tmp[i]))\n"
        }
        if s.last == "\n" {
            s = s.subString(to: s.count - 1)
        }
        label_EndBatteryTemp.text = s
    }

    func updateDuration() {
        var s = ""
        for i in 0 ..< 10 {
            s += "\(String(format: "%.0f", dur[i]))\n"
        }
        if s.last == "\n" {
            s = s.subString(to: s.count - 1)
        }
        label_HistDuration.text = s
    }
}
