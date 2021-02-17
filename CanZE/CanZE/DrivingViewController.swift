//
//  DrivingViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 05/02/21.
//

import Charts
import UIKit

class DrivingViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_pedal: UILabel!
    @IBOutlet var label_wheel_torque: UILabel!
    @IBOutlet var textRealSpeed: UILabel!
    @IBOutlet var textSpeedUnit: UILabel!
    @IBOutlet var textConsumption: UILabel!
    @IBOutlet var textConsumptionUnit: UILabel!
    @IBOutlet var LabelDistToDest: UILabel!
    @IBOutlet var textDistToDest: UILabel!
    @IBOutlet var label_DistAvailAtDest: UILabel!
    @IBOutlet var textDistAVailAtDest: UILabel!
    @IBOutlet var LabelTripConsumption: UILabel!
    @IBOutlet var textTripConsumption: UILabel!
    @IBOutlet var label_TripDistance: UILabel!
    @IBOutlet var textTripDistance: UILabel!
    @IBOutlet var label_TripEnergy: UILabel!
    @IBOutlet var textTripEnergy: UILabel!
    @IBOutlet var label_UserSOC: UILabel!
    @IBOutlet var textSOC: UILabel!

//    @IBOutlet var pedalChartView: HorizontalBarChartView!
//    var pedalChartEntries = [BarChartDataEntry]()
//    var pedalLine: BarChartDataSet!

    @IBOutlet var pedalBar: UIProgressView!

    @IBOutlet var pb_driver_torque_request: UIProgressView!
    @IBOutlet var MeanEffectiveAccTorque: UIProgressView!
    @IBOutlet var MaxBrakeTorque: UIProgressView!

    var odo = 0.0
    var destOdo = 0.0 // have to init from save file
    var tripBdistance = -1.0
    var tripBenergy = -1.0
    var startBdistance = -1.0
    var startBenergy = -1.0
    var tripDistance = -1.0
    var tripEnergy = -1.0
    var savedTripStart = 0.0
    var realSpeed = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_driving", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        label_pedal.text = NSLocalizedString("label_pedal", comment: "")

        label_wheel_torque.text = NSLocalizedString("label_wheel_torque", comment: "")

        textRealSpeed.text = "-"
        var s = NSLocalizedString(Globals.shared.milesMode ? "unit_SpeedMi" : "unit_SpeedKm", comment: "")
        s = s.replacingOccurrences(of: "u0020", with: " ")
        textSpeedUnit.text = s

        textConsumption.text = "-"
        s = NSLocalizedString(Globals.shared.milesMode ? "unit_ConsumptionMiAlt" : "unit_ConsumptionKm", comment: "")
        s = s.replacingOccurrences(of: "u0020", with: " ")
        textConsumptionUnit.text = s

        LabelDistToDest.text = NSLocalizedString("label_DistToDest", comment: "")
        textDistToDest.text = ""

        label_DistAvailAtDest.text = NSLocalizedString("label_DistAvailAtDest", comment: "")
        textDistAVailAtDest.text = "0"

        LabelTripConsumption.text = NSLocalizedString("label_TripConsumption", comment: "")
        textTripConsumption.text = "0"

        label_TripDistance.text = NSLocalizedString("label_TripDistance", comment: "")
        textTripDistance.text = "-"

        label_TripEnergy.text = NSLocalizedString("label_TripEnergy", comment: "")
        textTripEnergy.text = "-"

        label_UserSOC.text = NSLocalizedString("label_UserSOC", comment: "")
        textSOC.text = "-"

        // init progressview
        pedalBar.trackImage = UIImage(view: GradientView(frame: pedalBar.bounds)).withHorizontallyFlippedOrientation()
        pedalBar.transform = CGAffineTransform(scaleX: -1.0, y: -1.0)
        pedalBar.progressTintColor = view.backgroundColor
        pedalBar.setProgress(1, animated: false)

        pb_driver_torque_request.trackImage = UIImage(view: GradientViewDecel(frame: pb_driver_torque_request.bounds))
        pb_driver_torque_request.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        pb_driver_torque_request.progressTintColor = view.backgroundColor
        pb_driver_torque_request.setProgress(1, animated: false)

        MeanEffectiveAccTorque.trackImage = UIImage(view: GradientViewAccel(frame: MeanEffectiveAccTorque.bounds)).withHorizontallyFlippedOrientation()
        MeanEffectiveAccTorque.transform = CGAffineTransform(scaleX: -1.0, y: -1.0)
        MeanEffectiveAccTorque.progressTintColor = view.backgroundColor
        MeanEffectiveAccTorque.setProgress(1, animated: false)

        MaxBrakeTorque.trackImage = UIImage(view: GradientViewDecelAim(frame: MaxBrakeTorque.bounds))
        MaxBrakeTorque.transform = CGAffineTransform(scaleX: 1.0, y: -1.0)
        MaxBrakeTorque.progressTintColor = view.backgroundColor
        MaxBrakeTorque.setProgress(1, animated: false)

        getDestOdo()
        getSavedTripStart()

        // TEST
        /*
         var t: Float = 0.0
         var senso = "su"
         Timer.scheduledTimer(withTimeInterval: 0.075, repeats: true) { _ in

             if t > 1 {
                 senso = "giu"
                 t = 1.0
             }
             if t < 0 {
                 senso = "su"
                 t = 0.0
             }

             if senso == "su" {
                 t += 0.0125
             } else {
                 t -= 0.0125
             }

             self.pb_driver_torque_request.setProgress(1.0 - t, animated: false)
             self.MaxBrakeTorque.setProgress(1.0 - t, animated: false)
             self.pedalBar.setProgress(1.0 - t, animated: false)
             self.MeanEffectiveAccTorque.setProgress(1.0 - t, animated: false)
         }
         */
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

        addField(Sid.DcPowerOut, intervalMs: 0)
        addField(Sid.Pedal, intervalMs: 0)
        // addField(Sid.DriverBrakeWheel_Torque_Request, 0)
        // addField(Sid.ElecBrakeWheelsTorqueApplied, 0)
        // addField(Sid.Coasting_Torque, 0)
        addField(Sid.TotalPositiveTorque, intervalMs: 0)
        addField(Sid.TotalNegativeTorque, intervalMs: 0)
        addField(Sid.TotalPotentialResistiveWheelsTorque, intervalMs: 0)
        addField(Sid.RealSpeed, intervalMs: 0)
        addField_(Sid.SoC, intervalMs: 7200)
        addField_(Sid.RangeEstimate, intervalMs: 7200)
        addField_(Sid.EVC_Odometer, intervalMs: 6000)
        addField_(Sid.TripMeterB, intervalMs: 6000)
        addField_(Sid.TripEnergyB, intervalMs: 6000)

        startQueue2()
    }

    @objc func endQueue2() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
            self.startQueue()
//        }
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let val = Globals.shared.fieldResultsDouble[sid!]
        if val != nil && !val!.isNaN {
            DispatchQueue.main.async {
                switch sid {
                case Sid.SoC:
                    self.textSOC.text = String(format: "%.1f", val!)
                case Sid.Pedal:
                    let progress = Float(val!) / 125.0
                    self.pedalBar.setProgress(1 - progress, animated: false)
                case Sid.TotalPositiveTorque:
                    let progress = Float(val!) / 2048.0
                    self.MeanEffectiveAccTorque.setProgress(1 - progress, animated: false)
                case Sid.EVC_Odometer:
                    self.odo = val!
                case Sid.TripMeterB:
                    self.tripBdistance = val!
                    self.tripDistance = self.tripBdistance - self.startBdistance
                    self.displayTripData()
                case Sid.TripEnergyB:
                    self.tripBenergy = val!
                    self.tripEnergy = self.tripBenergy - self.startBenergy
                    self.displayTripData()
//            case Sid.MaxCharge: NOT USED !
//                self.text_max_charge.text = String(format: "%.1f", val)
                case Sid.RealSpeed:
                    self.realSpeed = val!
                    self.textRealSpeed.text = String(format: "%.1f", val!)
                case Sid.DcPowerOut:
                    if let dcPwr = val {
                        if !Globals.shared.milesMode, self.realSpeed > 5 {
                            self.textConsumption.text = String(format: "%.1f", 100.0 * dcPwr / self.realSpeed)
                        } else if Globals.shared.milesMode, dcPwr != 0 {
                            // real speed has already been returned in miles, so no conversions should be done
                            self.textConsumption.text = String(format: "%.2f", self.realSpeed / dcPwr)
                        }
                    } else {
                        self.textConsumption.text = "-"
                    }
                case Sid.RangeEstimate:
                    // int rangeInBat = (int) Utils.kmOrMiles(field.getValue());
                    let rangeInBat = Int(val!)
                    if rangeInBat > 0, self.odo > 0, self.destOdo > 0 { // we update only if there are no weird values
                        if self.destOdo > self.odo {
                            self.displayDistToDest(distance1: Int(self.destOdo - self.odo), distance2: Int(Double(rangeInBat) - self.destOdo + self.odo))
                        } else {
                            self.displayDistToDest(distance1: 0, distance2: 0)
                        }
                    } else {
                        self.displayDistToDest()
                    }
                case Sid.TotalPotentialResistiveWheelsTorque: // blue bar
                    let tprwt = -Int(val!)
                    let progress = tprwt < 2047 ? Float(tprwt) : 10 / 1536.0
                    self.MaxBrakeTorque.setProgress(1 - progress, animated: false)
                case Sid.TotalNegativeTorque:
                    let progress = Float(val!) / 1536.0
                    self.pb_driver_torque_request.setProgress(1 - progress, animated: false)

                // case Sid.DriverBrakeWheel_Torque_Request:
                //    driverBrakeWheel_Torque_Request = field.getValue() + coasting_Torque;
                //    pb = findViewById(R.id.pb_driver_torque_request);
                //    if (pb != null) pb.setProgress((int) driverBrakeWheel_Torque_Request);
                //    tv = null;
                //    break;
                // case Sid.Coasting_Torque:
                //    coasting_Torque = field.getValue() * MainActivity.reduction; // this torque is given in motor torque, not in wheel torque
                //    break;

                default:
                    print("unknown sid \(sid!)")
                }
            }
        }
    }

    func setDistanceToDestination() {
        // don't react if we do not have a live odo yet
        if odo == 0 {
            return
        }

        let alertController = UIAlertController(title: NSLocalizedString("prompt_Distance", comment: ""), message: NSLocalizedString("prompt_SetDistance", comment: ""), preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = ""
        }

        let confirmAction = UIAlertAction(title: NSLocalizedString("default_Ok", comment: ""), style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            if let i = Int(textField.text ?? "") {
                self.saveDestOdo(d: self.odo + Double(i))
            }
        }
        alertController.addAction(confirmAction)

        let doubleAction = UIAlertAction(title: NSLocalizedString("button_Double", comment: ""), style: .default) { [weak alertController] _ in
            guard let alertController = alertController, let textField = alertController.textFields?.first else { return }
            let i = Int(textField.text ?? "")
            if i != nil {
                self.saveDestOdo(d: self.odo + 2.0 * Double(i!))
            }
        }
        alertController.addAction(doubleAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    func saveDestOdo(d: Double) {
        if !d.isNaN {
            ud.setValue(d, forKey: "destOdo")
            ud.synchronize()
            destOdo = d
            displayDistToDest()
        }
    }

    func getDestOdo() {
        destOdo = 0
        if ud.exists(key: "destOdo") {
            destOdo = ud.value(forKey: "destOdo") as! Double
        }
        displayDistToDest()
    }

    func displayDistToDest(distance1: Int, distance2: Int) {
        textDistToDest.text = "\(distance1)"
        textDistAVailAtDest.text = "\(distance2)"
    }

    func displayDistToDest() {
        textDistToDest.text = "-"
        textDistAVailAtDest.text = "-"
    }

    func setSavedTripStart() {
        if !odo.isNaN, odo != 0, !tripBdistance.isNaN, tripBdistance != -1, !tripBenergy.isNaN, tripBenergy != -1 {
            savedTripStart = odo - tripBdistance
            startBdistance = tripBdistance
            startBenergy = tripBenergy
            ud.setValue(savedTripStart, forKey: "savedTripStart")
            ud.setValue(startBdistance, forKey: "startBdistance")
            ud.setValue(startBenergy, forKey: "startBenergy")
            ud.synchronize()
            displayTripData()
        }
    }

    func getSavedTripStart() {
        if ud.exists(key: "savedTripStart") {
            savedTripStart = ud.value(forKey: "savedTripStart") as! Double
        } else {
            savedTripStart = 0
        }
        if ud.exists(key: "startBdistance") {
            startBdistance = ud.value(forKey: "startBdistance") as! Double
        } else {
            startBdistance = 0
        }
        if ud.exists(key: "startBenergy") {
            startBenergy = ud.value(forKey: "startBenergy") as! Double
        } else {
            startBenergy = 0
        }
    }

    func displayTripData() {
        if (odo - tripBdistance - 1) > savedTripStart {
            textTripConsumption.text = NSLocalizedString("default_Reset", comment: "")
            textTripDistance.text = ""
            textTripEnergy.text = ""
            textTripConsumption.text = ""
        } else if tripEnergy <= 0 || tripDistance <= 0 {
            textTripConsumption.text = "..."
            textTripDistance.text = "..."
            textTripEnergy.text = "..."
        } else {
            textTripConsumption.text = String(format: "%.1f", Globals.shared.milesMode ? tripDistance / tripEnergy : tripEnergy * 100.0 / tripDistance)
            textTripDistance.text = String(format: "%.1f", tripDistance)
            textTripEnergy.text = String(format: "%.1f", tripEnergy)
        }
    }

    @IBAction func btnDistToDest() {
        setDistanceToDestination()
    }

    @IBAction func btnTripConsumption() {
        setSavedTripStart()
    }
}
