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

    let charging_HistEnd = Globals.localizableFromPlist?.value(forKey: "list_ChargingHistEnd") as? [String]
    let charging_HistTyp = Globals.localizableFromPlist?.value(forKey: "list_ChargingHistTyp") as? [String]

    var km: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var end: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var typ: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var soc: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var tmp: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    var dur: [Double] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_charging_history", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        header_ChargingHistory.text = NSLocalizedString("header_ChargingHistory", comment: "")

        label_distance.text = NSLocalizedString("label_distance", comment: "")
        label_EndOfChargeStatus.text = NSLocalizedString("label_EndOfChargeStatus", comment: "")
        label_TypeOfCharge.text = NSLocalizedString("label_TypeOfCharge", comment: "")
        label_EndSoc.text = NSLocalizedString("label_EndSoc", comment: "")
        label_EndBatteryTemp.text = NSLocalizedString("label_EndBatteryTemp", comment: "")
        label_HistDuration.text = NSLocalizedString("label_HistDuration", comment: "")

        header_ChargeSummary.text = NSLocalizedString("header_ChargeSummary", comment: "")

        label_TotKwh.text = NSLocalizedString("label_TotKwh", comment: "")
        textTotKwh.text = "-"

        label_TotKwhRegen.text = NSLocalizedString("label_TotKwhRegen", comment: "")
        textTotKwhRegen.text = "-"

        label_CountFull.text = NSLocalizedString("label_CountFull", comment: "")
        textCountFull.text = "-"

        label_CountPartial.text = NSLocalizedString("label_CountPartial", comment: "")
        textCountPartial.text = "-"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(decoded(notification:)), name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endQueue2), name: Notification.Name("endQueue2"), object: nil)

        startQueue()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("endQueue2"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc func updateDebugLabel(notification: Notification) {
        let dic = notification.object as? [String: String]
        DispatchQueue.main.async {
            self.lblDebug.text = dic?["debug"]
        }
        debug((dic?["debug"])!)
    }

    func startQueue() {
        if !Globals.shared.deviceIsConnected || !Globals.shared.deviceIsInitialized {
            DispatchQueue.main.async {
                self.view.makeToast("_device not connected")
            }
            return
        }

        queue2 = []

        for i in 0 ..< 10 {
            addField("\(Sid.Preamble_KM)\(240 - i * 24)", intervalMs: 6000)
            addField("\(Sid.Preamble_END)\(96 - i * 8)", intervalMs: 6000)
            addField("\(Sid.Preamble_TYP)\(96 - i * 8)", intervalMs: 6000)
            addField("\(Sid.Preamble_SOC)\(168 - i * 16)", intervalMs: 6000)
            addField("\(Sid.Preamble_TMP)\(96 - i * 8)", intervalMs: 6000)
            addField("\(Sid.Preamble_DUR)\(168 - i * 16)", intervalMs: 6000)
        }
        addField(Sid.Total_kWh, intervalMs: 6000)
        addField(Sid.Counter_Full, intervalMs: 6000)
        addField(Sid.Counter_Partial, intervalMs: 6000)

        if Utils.isPh2() {
            addField(Sid.Total_Regen_kWh, intervalMs: 6000)
        }

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
        if val != nil {
            DispatchQueue.main.async {
                switch sidPreamble {
                case Sid.Preamble_KM:
                    let indice = (264 - startBit!) / 24 - 1
                    self.km[indice] = val!
                    var s = "\(NSLocalizedString("label_distance", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(self.km[i])\n"
                    }
                    self.label_distance.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_END:
                    let indice = (104 - startBit!) / 8 - 1
                    self.end[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString("label_EndOfChargeStatus", comment: "")) \n"
                    for i in 0 ..< 10 {
                        let ii = Int(self.end[i])
                        if ii < self.charging_HistEnd!.count {
                            s += "\(self.charging_HistEnd![ii])\n"
                        } else {
                            s += "\n"
                        }
                    }
                    self.label_EndOfChargeStatus.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_TYP:
                    let indice = (104 - startBit!) / 8 - 1
                    self.typ[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString("label_TypeOfCharge", comment: "")) \n"
                    for i in 0 ..< 10 {
                        let ii = Int(self.typ[i])
                        if ii < self.charging_HistTyp!.count {
                            s += "\(self.charging_HistTyp![ii])\n"
                        } else {
                            s += "\n"
                        }
                    }
                    self.label_TypeOfCharge.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_SOC:
                    let indice = (184 - startBit!) / 16 - 1
                    self.soc[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString("label_EndSoc", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(self.soc[i])\n"
                    }
                    self.label_EndSoc.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_TMP:
                    let indice = (104 - startBit!) / 8 - 1
                    self.tmp[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString("label_EndBatteryTemp", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(self.tmp[i])\n"
                    }
                    self.label_EndBatteryTemp.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                case Sid.Preamble_DUR:
                    let indice = (184 - startBit!) / 16 - 1
                    self.dur[indice] = (val!.isNaN ? 0.0 : val)!
                    var s = "\(NSLocalizedString("label_HistDuration", comment: "")) \n"
                    for i in 0 ..< 10 {
                        s += "\(self.dur[i])\n"
                    }
                    self.label_HistDuration.text = s.trimmingCharacters(in: .whitespacesAndNewlines)
                default:
                    switch sid {
                    case Sid.Total_kWh:
                        self.textTotKwh.text = String(format: "%.0f", val!)
                    case Sid.Total_Regen_kWh:
                        self.textTotKwhRegen.text = String(format: "%.0f", val!)
                    case Sid.Counter_Full:
                        self.textCountFull.text = String(format: "%.0f", val!)
                    case Sid.Counter_Partial:
                        self.textCountPartial.text = String(format: "%.0f", val!)
                    default:
                        print("unknown sid")
                    }
                }
            }
        }
    }
}
