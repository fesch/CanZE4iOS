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

        title = NSLocalizedString_("title_activity_charging", comment: "")
        lblDebug.text = "Debug"
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        label_AvChPwr.text = NSLocalizedString_("label_AvChPwr", comment: "")
        textAvChPwr.text = "-"

        label_max_charge.text = NSLocalizedString_("label_max_charge", comment: "")
        text_max_charge.text = "-"

        labelDcPwr.text = NSLocalizedString_("label_DcPwr", comment: "")
        textDcPwr.text = "-"

        label_DISTA.text = NSLocalizedString_("label_DISTA", comment: "")
        textKMA.text = "-"

        label_UserSOC.text = NSLocalizedString_("label_UserSOC", comment: "")
        textUserSOC.text = "-"

        label_RealSOC.text = NSLocalizedString_("label_RealSOC", comment: "")
        textRealSOC.text = "-"

        label_SOH.text = NSLocalizedString_("label_SOH", comment: "")
        textSOH.text = "-"

        label_HvTemp.text = NSLocalizedString_("label_HvTemp", comment: "")
        textHvTemp.text = "-"
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

        if Utils.isPh2() {
            addField_(Sid.EVC, intervalMs: 20000) // open EVC
        }
        addField_(Sid.MaxCharge, intervalMs: 5000)
        addField_(Sid.UserSoC, intervalMs: 5000)
        addField_(Sid.RealSoC, intervalMs: 5000)
        addField_(Sid.SOH, intervalMs: 20000) // state of health gives continuous timeouts. This frame is send at a very low rate
        addField_(Sid.RangeEstimate, intervalMs: 5000)
        addField_(Sid.DcPowerIn, intervalMs: 5000)
        addField_(Sid.AvailableChargingPower, intervalMs: 5000)
        addField_(Sid.HvTemp, intervalMs: 5000)

        startQueue2()
    }

    @objc func endQueue2() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [self] in
            startQueue()
        }
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]
        let f = Fields.getInstance.fieldsBySid[sid!]

        let val = Globals.shared.fieldResultsDouble[sid!]
        if val != nil && !val!.isNaN {
            DispatchQueue.main.async { [self] in
                switch sid {
                case Sid.MaxCharge:
                    text_max_charge.text = String(format: "%.\(f?.decimals ?? 2)f", val!)
                    if val! < avChPwr * 0.8, avChPwr < 45.0 {
                        text_max_charge.textColor = .red
                    } else {
                        text_max_charge.textColor = .black
                    }
                case Sid.UserSoC:
                    textUserSOC.text = String(format: "%.2f", val!)
                case Sid.RealSoC:
                    textRealSOC.text = String(format: "%.2f", val!)
                case Sid.SOH:
                    textSOH.text = String(format: "%.2f", val!)
                case Sid.RangeEstimate:
                    if val! >= 1023 {
                        textKMA.text = "---"
                    } else {
                        textKMA.text = String(format: "%.0f", val!)
                    }
                case Sid.DcPowerIn:
                    textDcPwr.text = String(format: "%.2f", val!)
                case Sid.AvailableChargingPower:
                    avChPwr = val!
                    if avChPwr > 45 {
                        textAvChPwr.text = "---"
                    } else {
                        textAvChPwr.text = String(format: "%.2f", val!)
                    }
                case Sid.HvTemp:
                    textHvTemp.text = String(format: "%.2f", val!)
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
