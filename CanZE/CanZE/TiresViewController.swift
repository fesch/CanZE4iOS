//
//  TiresViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 10/02/21.
//

import UIKit

class TiresViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_tires", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///
        /*
         label_ChargingPrediction.text = NSLocalizedString("label_ChargingPrediction", comment: "")
         label_Duration.text = NSLocalizedString("label_Duration", comment: "")
         label_Soc.text = NSLocalizedString("label_Soc", comment: "")
         label_Range.text = NSLocalizedString("label_Range", comment: "")
         label_DcPower.text = NSLocalizedString("label_DcPower", comment: "")

         HeaderDC.text = NSLocalizedString("label_StateAtThisMoment", comment: "")
         label_BatteryTemperature.text = NSLocalizedString("label_BatteryTemperature", comment: "")
         texttemp.text = "-"
         label_ACPower.text = NSLocalizedString("label_ACPower", comment: "")
         textacpwr.text = "-"
         label_StateOfCharge.text = NSLocalizedString("label_StateOfCharge", comment: "")
         textsoc.text = "-"

         battery = Battery()

         // set charger limit
         if Globals.shared.car == AppSettings.CAR_ZOE_R240 || Globals.shared.car == AppSettings.CAR_ZOE_R90 {
             battery.dcPowerLowerLimit = 1.0
             battery.dcPowerUpperLimit = 20.0
         }

         if Globals.shared.car == AppSettings.CAR_ZOE_Q90 || Globals.shared.car == AppSettings.CAR_ZOE_R90 {
             battery.setBatteryType(41)
         } else {
             battery.setBatteryType(22)
         }

         runPrediction()*/
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

        addField(Sid.RangeEstimate, intervalMs: 10000) // 0x08
        addField(Sid.AvailableChargingPower, intervalMs: 10000) // 0x01
        addField(Sid.UserSoC, intervalMs: 10000) // 0x02
        // addField(Sid.ChargingStatusDisplay, 10000);
        addField(Sid.AverageBatteryTemperature, intervalMs: 10000) // 0x04
        addField(Sid.SOH, intervalMs: 10000) // 0x20

        startQueue2()
    }

    @objc func endQueue2() {
        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let val = fieldResultsDouble[sid!]

        if val != nil {
            DispatchQueue.main.async {
                /*   switch sid {
                 case Sid.AvailableChargingPower:
                     self.car_charger_ac_power = val!
                     self.car_status |= 0x01
                     if self.car_charger_ac_power > 1 {
                         self.car_status |= 0x10
                         self.charging_status = 1
                     } else {
                         self.charging_status = 0
                     }
                 case Sid.UserSoC:
                     self.car_soc = val!
                     self.car_status |= 0x02
                 case Sid.AverageBatteryTemperature:
                     self.car_bat_temp = val!
                     self.car_status |= 0x04
                 case Sid.RangeEstimate:
                     self.car_range_est = val!
                     self.car_status |= 0x08
                 // case Sid.ChargingStatusDisplay:
                 //    charging_status = (fieldVal == 3) ? 1 : 0;
                 //    car_status |= 0x10;
                 //    break;
                 case Sid.SOH:
                     self.car_soh = val!
                     self.car_status |= 0x20
                 default:
                     print("?")
                 }
                 if self.car_status == 0x3f {
                     // dropDebugMessage2 (String.format(Locale.getDefault(), "go %02X", car_status));
                     self.runPrediction()
                     self.car_status = 0
                 } // else {
                 // dropDebugMessage2 (String.format(Locale.getDefault(), ".. %02X", car_status));
                 // } */
            }
        }
    }
}
