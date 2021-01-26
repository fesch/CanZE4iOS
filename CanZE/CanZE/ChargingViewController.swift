//
//  ChargingViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 18/01/21.
//

import UIKit

class ChargingViewController: CanZeViewController {
    @IBOutlet var lblAvailableChargingPowerTitle: UILabel!
    @IBOutlet var lblAvailableChargingPower: UILabel!

    @IBOutlet var lblMaxBatteryChargeRegenTitle: UILabel!
    @IBOutlet var lblMaxBatteryChargeRegen: UILabel!

    @IBOutlet var lblDCPowerTitle: UILabel!
    @IBOutlet var lblDCPower: UILabel!

    @IBOutlet var lblAvailableRangeTitle: UILabel!
    @IBOutlet var lblAvailableRange: UILabel!

    @IBOutlet var lblUsableStateOfChargeTitle: UILabel!
    @IBOutlet var lblUsableStateOfCharge: UILabel!
    @IBOutlet var lblRealStateOfChargeTitle: UILabel!
    @IBOutlet var lblRealStateOfCharge: UILabel!
    @IBOutlet var lblStateOfHealthTitle: UILabel!
    @IBOutlet var lblStateOfHealth: UILabel!
    @IBOutlet var lblMeanBatteryTemperatureTitle: UILabel!
    @IBOutlet var lblMeanBatteryTemperature: UILabel!

    @IBOutlet var lblDebug: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_charging", comment: "")

        lblAvailableChargingPowerTitle.text = NSLocalizedString("label_AvChPwr", comment: "")
        lblAvailableChargingPower.text = "-"

        lblMaxBatteryChargeRegenTitle.text = NSLocalizedString("label_max_charge", comment: "")
        lblMaxBatteryChargeRegen.text = "-"

        lblDCPowerTitle.text = NSLocalizedString("label_DcPwr", comment: "")
        lblDCPower.text = "-"

        lblAvailableRangeTitle.text = NSLocalizedString("label_DISTA", comment: "")
        lblAvailableRange.text = "-"

        lblUsableStateOfChargeTitle.text = NSLocalizedString("label_UserSOC", comment: "")
        lblUsableStateOfCharge.text = "-"

        lblRealStateOfChargeTitle.text = NSLocalizedString("label_RealSOC", comment: "")
        lblRealStateOfCharge.text = "-"

        lblStateOfHealthTitle.text = NSLocalizedString("label_SOH", comment: "")
        lblStateOfHealth.text = "-"

        lblMeanBatteryTemperatureTitle.text = NSLocalizedString("label_HvTemp", comment: "")
        lblMeanBatteryTemperature.text = "-"

        lblDebug.text = "Debug"

        //NotificationCenter.default.addObserver(self, selector: #selector(ricevuto2(notification:)), name: Notification.Name("ricevuto2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(decodificato), name: Notification.Name("decodificato"), object: nil)

        coda2 = []

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

        if AppSettings.shared.deviceIsConnected, AppSettings.shared.deviceIsInitialized {
            iniziaCoda2()
        } else {
            view.makeToast("_device not connected")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decodificato"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ricevuto2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc func updateDebugLabel(notification: Notification) {
        let dic = notification.object as? [String: String]
        DispatchQueue.main.async {
            self.lblDebug.text = dic?["debug"]
        }
    }

    @objc func decodificato() {
        DispatchQueue.main.async {
            var f = Fields.getInstance.fieldsBySid[Sid.MaxCharge]
            self.lblMaxBatteryChargeRegen.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            f = Fields.getInstance.fieldsBySid[Sid.UserSoC]
            self.lblUsableStateOfCharge.text = String(format: "%.2f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            f = Fields.getInstance.fieldsBySid[Sid.RealSoC]
            self.lblRealStateOfCharge.text = String(format: "%.2f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            f = Fields.getInstance.fieldsBySid[Sid.SOH]
            self.lblStateOfHealth.text = String(format: "%.2f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            f = Fields.getInstance.fieldsBySid[Sid.RangeEstimate]
            self.lblAvailableRange.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            f = Fields.getInstance.fieldsBySid[Sid.DcPowerIn]
            self.lblDCPower.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            f = Fields.getInstance.fieldsBySid[Sid.AvailableChargingPower]
            self.lblAvailableChargingPower.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            f = Fields.getInstance.fieldsBySid[Sid.HvTemp]
            self.lblMeanBatteryTemperature.text = String(format: "%.2f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
