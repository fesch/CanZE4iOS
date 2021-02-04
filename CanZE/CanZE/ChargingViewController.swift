//
//  ChargingViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 18/01/21.
//

import UIKit

class ChargingViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

//

    @IBOutlet var label_AvChPwr: UILabel!
    @IBOutlet var textAvChPwr: UILabel!

    @IBOutlet var label_max_charge: UILabel!
    @IBOutlet var text_max_charge: UILabel!

    @IBOutlet var labelDcPwr: UILabel!
    @IBOutlet var textDcPwr: UILabel!

    @IBOutlet var label_DISTA: UILabel!
    @IBOutlet var textKMA: UILabel!

    @IBOutlet var label_UserSOC: UILabel!
    @IBOutlet var textUserSOC: UILabel!

    @IBOutlet var label_RealSOC: UILabel!
    @IBOutlet var textRealSOC: UILabel!

    @IBOutlet var label_SOH: UILabel!
    @IBOutlet var textSOH: UILabel!

    @IBOutlet var label_HvTemp: UILabel!
    @IBOutlet var textHvTemp: UILabel!

    var avChPwr = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_charging", comment: "")
        lblDebug.text = "Debug"
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        label_AvChPwr.text = NSLocalizedString("label_AvChPwr", comment: "")
        textAvChPwr.text = "-"

        label_max_charge.text = NSLocalizedString("label_max_charge", comment: "")
        text_max_charge.text = "-"

        labelDcPwr.text = NSLocalizedString("label_DcPwr", comment: "")
        textDcPwr.text = "-"

        label_DISTA.text = NSLocalizedString("label_DISTA", comment: "")
        textKMA.text = "-"

        label_UserSOC.text = NSLocalizedString("label_UserSOC", comment: "")
        textUserSOC.text = "-"

        label_RealSOC.text = NSLocalizedString("label_RealSOC", comment: "")
        textRealSOC.text = "-"

        label_SOH.text = NSLocalizedString("label_SOH", comment: "")
        textSOH.text = "-"

        label_HvTemp.text = NSLocalizedString("label_HvTemp", comment: "")
        textHvTemp.text = "-"
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

        if Utils.isPh2() {
            addField(sid: "7ec.5003.0", intervalMs: 2000) // open EVC
        }
        addField(sid: Sid.MaxCharge, intervalMs: 5000)
        addField(sid: Sid.UserSoC, intervalMs: 5000)
        addField(sid: Sid.RealSoC, intervalMs: 5000)
        addField(sid: Sid.SOH, intervalMs: 5000) // state of health gives continuous timeouts. This frame is send at a very low rate
        addField(sid: Sid.RangeEstimate, intervalMs: 5000)
        addField(sid: Sid.DcPowerIn, intervalMs: 5000)
        addField(sid: Sid.AvailableChargingPower, intervalMs: 5000)
        addField(sid: Sid.HvTemp, intervalMs: 5000)

        startQueue2()
    }

    @objc func endQueue2() {
        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]
        let f = Fields.getInstance.fieldsBySid[sid!]

        DispatchQueue.main.async {
            switch sid {
            case Sid.MaxCharge:
                self.text_max_charge.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] ?? Double.nan < self.avChPwr * 0.8, self.avChPwr < 45.0 {
                    self.text_max_charge.textColor = .red
                } else {
                    self.text_max_charge.textColor = .black
                }
            case Sid.UserSoC:
                self.textUserSOC.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.RealSoC:
                self.textRealSOC.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.SOH:
                self.textSOH.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.RangeEstimate:
                if self.fieldResultsDouble[sid!] ?? Double.nan >= 1023 {
                    self.textKMA.text = "---"
                } else {
                    self.textKMA.text = String(format: "%.0f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                }
            case Sid.DcPowerIn:
                self.textDcPwr.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.AvailableChargingPower:
                self.avChPwr = self.fieldResultsDouble[sid!] ?? Double.nan
                if self.avChPwr > 45 {
                    self.textAvChPwr.text = "---"
                } else {
                    self.textAvChPwr.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                }
            case Sid.HvTemp:
                self.textHvTemp.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            default:
                print("?")
            }
        }
    }
}
