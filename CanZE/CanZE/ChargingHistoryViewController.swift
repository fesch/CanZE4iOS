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

        label_distance.text = NSLocalizedString_("label_distance", comment: "")
        label_EndOfChargeStatus.text = NSLocalizedString_("label_EndOfChargeStatus", comment: "")
        label_TypeOfCharge.text = NSLocalizedString_("label_TypeOfCharge", comment: "")
        label_EndSoc.text = NSLocalizedString_("label_EndSoc", comment: "")
        label_EndBatteryTemp.text = NSLocalizedString_("label_EndBatteryTemp", comment: "")
        label_HistDuration.text = NSLocalizedString_("label_HistDuration", comment: "")

        header_ChargeSummary.text = NSLocalizedString_("header_ChargeSummary", comment: "")

        label_TotKwh.text = NSLocalizedString_("label_TotKwh", comment: "")
        textTotKwh.text = "-"

        label_TotKwhRegen.text = NSLocalizedString_("label_TotKwhRegen", comment: "")
        textTotKwhRegen.text = "-"

        label_CountFull.text = NSLocalizedString_("label_CountFull", comment: "")
        textCountFull.text = "-"

        label_CountPartial.text = NSLocalizedString_("label_CountPartial", comment: "")
        textCountPartial.text = "-"

        var s = "\(NSLocalizedString_("label_distance", comment: "")) \n"
        for i in 0 ..< 10 {
            s += "\(km[i])\n"
        }
        label_distance.text = s.trimmingCharacters(in: .whitespacesAndNewlines)

        s = "\(NSLocalizedString_("label_EndOfChargeStatus", comment: "")) \n"
        for i in 0 ..< 10 {
            s += "\(end[i])\n"
        }
        label_EndOfChargeStatus.text = s.trimmingCharacters(in: .whitespacesAndNewlines)

        s = "\(NSLocalizedString_("label_TypeOfCharge", comment: "")) \n"
        for i in 0 ..< 10 {
            s += "\(typ[i])\n"
        }
        label_TypeOfCharge.text = s.trimmingCharacters(in: .whitespacesAndNewlines)

        s = "\(NSLocalizedString_("label_EndSoc", comment: "")) \n"
        for i in 0 ..< 10 {
            s += "\(soc[i])\n"
        }
        label_EndSoc.text = s.trimmingCharacters(in: .whitespacesAndNewlines)

        s = "\(NSLocalizedString_("label_EndBatteryTemp", comment: "")) \n"
        for i in 0 ..< 10 {
            s += "\(tmp[i])\n"
        }
        label_EndBatteryTemp.text = s.trimmingCharacters(in: .whitespacesAndNewlines)

        s = "\(NSLocalizedString_("label_HistDuration", comment: "")) \n"
        for i in 0 ..< 10 {
            s += "\(dur[i])\n"
        }
        label_HistDuration.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    var s = "\(NSLocalizedString_("label_distance", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(km[i])\n"
                    }
                    label_distance.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_END:
                    let indice = (104 - startBit!) / 8 - 1
                    end[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString_("label_EndOfChargeStatus", comment: "")) \n"
                    for i in 0 ..< 10 {
                        let ii = Int(end[i])
                        if ii < charging_HistEnd.count {
                            s += "\(charging_HistEnd[ii])\n"
                        } else {
                            s += "\n"
                        }
                    }
                    label_EndOfChargeStatus.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_TYP:
                    let indice = (104 - startBit!) / 8 - 1
                    typ[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString_("label_TypeOfCharge", comment: "")) \n"
                    for i in 0 ..< 10 {
                        let ii = Int(typ[i])
                        if ii < charging_HistTyp.count {
                            s += "\(charging_HistTyp[ii])\n"
                        } else {
                            s += "\n"
                        }
                    }
                    label_TypeOfCharge.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_SOC:
                    let indice = (184 - startBit!) / 16 - 1
                    soc[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString_("label_EndSoc", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(soc[i])\n"
                    }
                    label_EndSoc.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_TMP:
                    let indice = (104 - startBit!) / 8 - 1
                    tmp[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString_("label_EndBatteryTemp", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(tmp[i])\n"
                    }
                    label_EndBatteryTemp.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_DUR:
                    let indice = (184 - startBit!) / 16 - 1
                    dur[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString_("label_HistDuration", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(dur[i])\n"
                    }
                    label_HistDuration.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
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
}
