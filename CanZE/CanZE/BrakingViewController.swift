//
//  BrakingViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 09/02/21.
//

import Charts
import UIKit

class BrakingViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_driver_torque_request: UILabel!
    @IBOutlet var text_driver_torque_request: UILabel!
    @IBOutlet var torqueRequestChartView: BarChartView!
    var torqueRequestChartEntries = [ChartDataEntry]()
    var torqueRequestChartLine: BarChartDataSet!
    @IBOutlet var torqueRequestChartView2: BarChartView!
    var torqueRequestChartEntries2 = [ChartDataEntry]()
    var torqueRequestChartLine2: BarChartDataSet!

    @IBOutlet var label_ElecBrakeWheelsTorqueApplied: UILabel!
    @IBOutlet var text_ElecBrakeWheelsTorqueApplied: UILabel!
    @IBOutlet var torqueAppliedChartView: BarChartView!
    var torqueAppliedChartEntries = [ChartDataEntry]()
    var torqueAppliedChartLine: BarChartDataSet!

    @IBOutlet var label_diff_friction_torque: UILabel!
    @IBOutlet var text_diff_friction_torque: UILabel!
    @IBOutlet var diffFrictionTorqueChartView: BarChartView!
    var diffFrictionTorqueChartEntries = [ChartDataEntry]()
    var diffFrictionTorqueChartLine: BarChartDataSet!

    @IBOutlet var help_AllTorques: UILabel!

    var frictionTorque = 0.0
    var elecBrakeTorque = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = NSLocalizedString("title_activity_braking", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        label_driver_torque_request.text = NSLocalizedString("label_driver_torque_request", comment: "")
        text_driver_torque_request.text = "-"

        label_ElecBrakeWheelsTorqueApplied.text = NSLocalizedString("label_ElecBrakeWheelsTorqueApplied", comment: "")
        text_ElecBrakeWheelsTorqueApplied.text = "-"

        label_diff_friction_torque.text = NSLocalizedString("label_diff_friction_torque", comment: "")
        text_diff_friction_torque.text = "-"

        help_AllTorques.text = NSLocalizedString("help_AllTorques", comment: "")

        initTorqueRequestChart()
        initTorqueRequestChart2()
        initTorqueAppliedChart()
        initDiffFrictionTorqueChart()
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

        addField(Sid.TotalPotentialResistiveWheelsTorque, intervalMs: 0)
        addField(Sid.FrictionTorque, intervalMs: 0)
        addField(Sid.ElecBrakeTorque, intervalMs: 0)

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
                case Sid.TotalPotentialResistiveWheelsTorque: // bluebar
                    let tprwt = -val!
                    self.torqueRequestChartEntries2 = [BarChartDataEntry(x: 1, y: tprwt < 2047 ? tprwt : 0.0)]
                    self.updateTorqueRequestChart2()
                case Sid.FrictionTorque:
                    self.frictionTorque = val!
                    self.diffFrictionTorqueChartEntries = [BarChartDataEntry(x: 1, y: val!)]
                    self.updateDiffFrictionTorqueChart()
                    let um = NSLocalizedString("string.unit_Nm", comment: "")
                    self.text_diff_friction_torque.text = String(format: "%.0f \(um)", val!)
                    self.torqueRequestChartEntries = [BarChartDataEntry(x: 1, y: self.frictionTorque + self.elecBrakeTorque)]
                    self.updateTorqueRequestChart()
                    self.text_driver_torque_request.text = String(format: "%.0f \(um)", self.frictionTorque + self.elecBrakeTorque)
                case Sid.ElecBrakeTorque:
                    self.elecBrakeTorque = val!
                    self.torqueAppliedChartEntries = [BarChartDataEntry(x: 1, y: val!)]
                    self.updateTorqueAppliedChart()
                    let um = NSLocalizedString("string.unit_Nm", comment: "")
                    self.text_ElecBrakeWheelsTorqueApplied.text = String(format: "%.0f \(um)", val!)
                    self.torqueRequestChartEntries = [BarChartDataEntry(x: 1, y: self.frictionTorque + self.elecBrakeTorque)]
                    self.updateTorqueRequestChart()
                    self.text_driver_torque_request.text = String(format: "%.0f \(um)", self.frictionTorque + self.elecBrakeTorque)
                default:
                    print("unknown sid \(sid!)")
                }
            }
        }
    }

    func initTorqueRequestChart() {
        torqueRequestChartView.legend.enabled = false
        torqueRequestChartView.xAxis.enabled = false
        torqueRequestChartView.rightAxis.enabled = false
        torqueRequestChartView.drawValueAboveBarEnabled = false
        torqueRequestChartView.fitBars = true

        let xAxis = torqueRequestChartView.xAxis
        xAxis.enabled = false

        let leftAxis = torqueRequestChartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 2048
        leftAxis.enabled = false

        torqueRequestChartLine = BarChartDataSet(entries: torqueRequestChartEntries, label: nil)
        torqueRequestChartLine.drawValuesEnabled = false

        torqueRequestChartLine.colors = [.brown]
    }

    func initTorqueRequestChart2() {
        torqueRequestChartView2.legend.enabled = false
        torqueRequestChartView2.xAxis.enabled = false
        torqueRequestChartView2.rightAxis.enabled = false
        torqueRequestChartView2.drawValueAboveBarEnabled = false
        torqueRequestChartView2.fitBars = true

        let xAxis = torqueRequestChartView2.xAxis
        xAxis.enabled = false

        let leftAxis = torqueRequestChartView2.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 2048
        leftAxis.enabled = false

        torqueRequestChartLine2 = BarChartDataSet(entries: torqueRequestChartEntries2, label: nil)
        torqueRequestChartLine2.drawValuesEnabled = false

        torqueRequestChartLine2.colors = [.red]
    }

    func initTorqueAppliedChart() {
        torqueAppliedChartView.legend.enabled = false
        torqueAppliedChartView.xAxis.enabled = false
        torqueAppliedChartView.rightAxis.enabled = false
        torqueAppliedChartView.drawValueAboveBarEnabled = false
        torqueAppliedChartView.fitBars = true

        let xAxis = torqueAppliedChartView.xAxis
        xAxis.enabled = false

        let leftAxis = torqueAppliedChartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 2048
        leftAxis.enabled = false

        torqueAppliedChartLine = BarChartDataSet(entries: torqueAppliedChartEntries, label: nil)
        torqueAppliedChartLine.drawValuesEnabled = false

        torqueAppliedChartLine.colors = [.brown]
    }

    func initDiffFrictionTorqueChart() {
        diffFrictionTorqueChartView.legend.enabled = false
        diffFrictionTorqueChartView.xAxis.enabled = false
        diffFrictionTorqueChartView.rightAxis.enabled = false
        diffFrictionTorqueChartView.drawValueAboveBarEnabled = false
        diffFrictionTorqueChartView.fitBars = true

        let xAxis = diffFrictionTorqueChartView.xAxis
        xAxis.enabled = false

        let leftAxis = diffFrictionTorqueChartView.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.axisMaximum = 2048
        leftAxis.enabled = false

        diffFrictionTorqueChartLine = BarChartDataSet(entries: torqueRequestChartEntries, label: nil)
        diffFrictionTorqueChartLine.drawValuesEnabled = false

        diffFrictionTorqueChartLine.colors = [.brown]
    }

    func updateTorqueRequestChart() {
        torqueRequestChartLine.replaceEntries(torqueRequestChartEntries)
        let data = BarChartData(dataSet: torqueRequestChartLine)
        data.barWidth = 50.0
        torqueRequestChartView.data = data
    }

    func updateTorqueRequestChart2() {
        torqueRequestChartLine2.replaceEntries(torqueRequestChartEntries2)
        let data = BarChartData(dataSet: torqueRequestChartLine2)
        data.barWidth = 10.0
        torqueRequestChartView2.data = data
    }

    func updateTorqueAppliedChart() {
        torqueAppliedChartLine.replaceEntries(torqueAppliedChartEntries)
        let data = BarChartData(dataSet: torqueAppliedChartLine)
        data.barWidth = 50.0
        torqueAppliedChartView.data = data
    }

    func updateDiffFrictionTorqueChart() {
        diffFrictionTorqueChartLine.replaceEntries(diffFrictionTorqueChartEntries)
        let data = BarChartData(dataSet: diffFrictionTorqueChartLine)
        data.barWidth = 50.0
        diffFrictionTorqueChartView.data = data
    }

    class TimestampAxis: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            var s = ""
            let df = DateFormatter()
            df.dateStyle = .none
            df.timeStyle = .short
            let d = Date(timeIntervalSince1970: value)
            s = df.string(from: d)
            return s
        }
    }
}
