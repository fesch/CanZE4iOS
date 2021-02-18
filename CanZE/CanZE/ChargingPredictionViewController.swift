//
//  ChargingPredictionViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 09/02/21.
//

import UIKit

class ChargingPredictionViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_ChargingPrediction: UILabel!
    @IBOutlet var label_Duration: UILabel!
    @IBOutlet var label_Soc: UILabel!
    @IBOutlet var label_Range: UILabel!
    @IBOutlet var label_DcPower: UILabel!

    @IBOutlet var HeaderDC: UILabel!
    @IBOutlet var label_BatteryTemperature: UILabel!
    @IBOutlet var texttemp: UILabel!
    @IBOutlet var label_ACPower: UILabel!
    @IBOutlet var textacpwr: UILabel!
    @IBOutlet var label_StateOfCharge: UILabel!
    @IBOutlet var textsoc: UILabel!

    var battery: Battery!

    var car_soc = 5.0
    var car_soh = 100.0
    var car_bat_temp = 10.0
    var car_charger_ac_power = 22.0
    var car_status = 0
    var charging_status = 0
    var seconds_per_tick = 288 // time 100 iterations = 8 hours
    var car_range_est = 1.0

    var tim_: [String] = ["", "", "", "", "", "", "", "", "", ""]
    var soc_: [String] = ["", "", "", "", "", "", "", "", "", ""]
    var ran_: [String] = ["", "", "", "", "", "", "", "", "", ""]
    var pow_: [String] = ["", "", "", "", "", "", "", "", "", ""]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_prediction", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

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

        runPrediction()
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
        let dic = notification.object as? [String: String]
        DispatchQueue.main.async {
            self.lblDebug.text = dic?["debug"]
        }
        debug((dic?["debug"])!)
    }

    override func startQueue() {
        if !Globals.shared.deviceIsConnected || !Globals.shared.deviceIsInitialized {
            DispatchQueue.main.async {
                self.view.makeToast("_device not connected")
            }
            return
        }

        queue2 = []

        addField_(Sid.RangeEstimate, intervalMs: 10000) // 0x08
        addField_(Sid.AvailableChargingPower, intervalMs: 10000) // 0x01
        addField_(Sid.UserSoC, intervalMs: 10000) // 0x02
        // addField(Sid.ChargingStatusDisplay, 10000);
        addField_(Sid.AverageBatteryTemperature, intervalMs: 10000) // 0x04
        addField_(Sid.SOH, intervalMs: 10000) // 0x20

        startQueue2()
    }

    @objc func endQueue2() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.startQueue()
        }
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let val = Globals.shared.fieldResultsDouble[sid!]
        if val != nil && !val!.isNaN {
            DispatchQueue.main.async {
                switch sid {
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
                    print("unknown sid \(sid!)")
                }

                if self.car_status == 0x3f {
                    // dropDebugMessage2 (String.format(Locale.getDefault(), "go %02X", car_status));
                    self.runPrediction()
                    self.car_status = 0
                } // else {
                // dropDebugMessage2 (String.format(Locale.getDefault(), ".. %02X", car_status));
                // }
            }
        }
    }

    func runPrediction() {
        DispatchQueue.main.async {
            self.texttemp.text = "\(Int(self.car_bat_temp))°C"
            self.textsoc.text = "\(Int(self.car_soc))%"
        }
        // if there is no charging going on, erase all fields in the table
        if charging_status == 0 {
            DispatchQueue.main.async {
                self.textacpwr.text = "Not charging"
            }
            for t in 0 ..< 10 {
                tim_[t] = "00:00"
                soc_[t] = "-"
                ran_[t] = "-"
                pow_[t] = "-"
                updatePrediction()
            }
            return
        }

        // set the battery object to an initial state equal to the real battery (
        battery.secondsRunning = 0

        // set the State of Health
        battery.setStateOfHealth(car_soh)

        // set the internal battery temperature
        battery.setTemperature(car_bat_temp)

        // set the internal state of charge
        battery.setStateOfChargePerc(car_soc)

        // set the external maximum charger capacity

        DispatchQueue.main.async {
            self.textacpwr.text = "\(Int(self.car_charger_ac_power * 10) / 10) kW)"
        }

        battery.setChargerPower(car_charger_ac_power)

        // now start iterating over time
        var iter_at_99 = 100 // tick when the battery is full
        for t in 1 ..< 101 { // 100 ticks
            battery.iterateCharging(seconds_per_tick)
            let soc = battery.getStateOfChargePerc()
            // save the earliest tick when the battery is full
            if soc >= 99, t < iter_at_99 {
                iter_at_99 = t
            }
            // optimization
            if (t % 10) == 0 {
                tim_[t / 10] = formatTime(battery.secondsRunning)
                soc_[t / 10] = "\(Int(soc)))"
                if car_soc > 0.0 {
                    ran_[t / 10] = "\(Int(car_range_est * soc / car_soc))"
                }
                pow_[t / 10] = String(format: "%.1f", battery.getDcPower())
                updatePrediction()
            }
        }

        // adjust the tick time if neccesary. Note that this is
        // effective on th next iteration

        if iter_at_99 == 100, seconds_per_tick < 288 {
            // if we were unable to go to 99% and below 8 hours, double tick step
            seconds_per_tick *= 2
        } else if iter_at_99 > 50 {
            // if we were full after half the table size
            // do nothing
            // seconds_per_tick *= 1;
        } else if iter_at_99 > 25, seconds_per_tick > 18 {
            // if we were full after a quarter of the table size
            // and over half an hour, half the tick step
            seconds_per_tick /= 2
        } else if seconds_per_tick > 18 {
            // if we were full before or equal a quarter of the table size
            // and over half an hour, quarter the tick step
            seconds_per_tick /= 4
        }
    }

    func updatePrediction() {
        var tim = "\(NSLocalizedString("label_Duration", comment: ""))\n"
        var soc = "\(NSLocalizedString("label_Soc", comment: ""))\n"
        var ran = "\(NSLocalizedString("label_Range", comment: ""))\n"
        var pow = "\(NSLocalizedString("label_DcPower", comment: ""))\n"

        for t in 0 ..< 10 {
            tim.append("\(tim_[t])\n")
            soc.append("\(soc_[t])\n")
            ran.append("\(ran_[t])\n")
            pow.append("\(pow_[t])\n")
        }

        DispatchQueue.main.async {
            self.label_Duration.text = tim.trimmingCharacters(in: .whitespacesAndNewlines)
            self.label_Soc.text = soc.trimmingCharacters(in: .whitespacesAndNewlines)
            self.label_Range.text = ran.trimmingCharacters(in: .whitespacesAndNewlines)
            self.label_DcPower.text = pow.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    func formatTime(_ t2: Int) -> String {
        // t is in seconds
        var t = t2
        t /= 60
        // t is in minutes
        return "" + format2Digit(t / 60) + ":" + format2Digit(t % 60)
    }

    func format2Digit(_ t: Int) -> String {
        return ("00\(t)").subString(from: t > 9 ? 2 : 1)
    }

    /*
     public void dropDebugMessage (final String msg) {}

     public void dropDebugMessage2 (final String msg) {
         runOnUiThread(new Runnable() {
             @Override
             public void run() {
                 TextView tv = findViewById(R.id.textDebug);
                 if (tv != null) tv.setText(msg);
             }
         });
     }
     */
}
