//
//  AuxBatteryViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 03/02/21.
//

import Charts
import UIKit

class AuxBatteryViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_12V: UILabel!
    @IBOutlet var text12V: UILabel!
    @IBOutlet var label_12A: UILabel!
    @IBOutlet var text12A: UILabel!
    @IBOutlet var label_DcLoad: UILabel!
    @IBOutlet var textDcLoad: UILabel!
    @IBOutlet var label_vehiclestate: UILabel!
    @IBOutlet var text_vehicle_state: UILabel!
    @IBOutlet var label_VoltageUnderLoad: UILabel!
    @IBOutlet var textVoltageUnderLoad: UILabel!
    @IBOutlet var label_CurrentUnderLoad: UILabel!
    @IBOutlet var textCurrentUnderLoad: UILabel!
    @IBOutlet var label_AuxStatus: UILabel!
    @IBOutlet var textAuxStatus: UILabel!

    @IBOutlet var lblGraphTitle: UILabel!
    @IBOutlet var lblVoltage: UILabel!
    @IBOutlet var lblVehicleState: UILabel!
    @IBOutlet var chartView: LineChartView!
    var chartEntries = [ChartDataEntry]()

    let aux_Status = Globals.localizableFromPlist?.value(forKey: "list_AuxStatus") as? [String]
    let vehicle_Status = Globals.localizableFromPlist?.value(forKey: Utils.isPh2() ? "list_VehicleStatePh2" : "list_VehicleState") as? [String]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_auxbatt", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        label_12V.text = NSLocalizedString("label_12V", comment: "")
        text12V.text = "-"
        label_12A.text = NSLocalizedString("label_12A", comment: "")
        text12A.text = "-"
        label_DcLoad.text = NSLocalizedString("label_DcLoad", comment: "")
        textDcLoad.text = "-"
        label_vehiclestate.text = NSLocalizedString("label_vehiclestate", comment: "")
        text_vehicle_state.text = "-"
        label_VoltageUnderLoad.text = NSLocalizedString("label_VoltageLoad", comment: "")
        textVoltageUnderLoad.text = "-"
        label_CurrentUnderLoad.text = NSLocalizedString("label_CurrentUnderLoad", comment: "")
        textCurrentUnderLoad.text = "-"
        label_AuxStatus.text = NSLocalizedString("label_AuxStatus", comment: "")
        textAuxStatus.text = "-"

        lblGraphTitle.text = "_Voltage, Vehicle state"
        lblVoltage.text = "-"
        lblVehicleState.text = "-"

        initChart()
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

        addField(sid: Sid.Aux12V, intervalMs: 2000)
        addField(sid: Sid.Aux12A, intervalMs: 1000)
        addField(sid: Sid.DcLoad, intervalMs: 1000)
        addField(sid: Sid.AuxStatus, intervalMs: 1000)
        addField(sid: Sid.VehicleState, intervalMs: 99999)
        // addField(Sid.ChargingStatusDisplay, 1000)
        addField(sid: Sid.VoltageUnderLoad, intervalMs: 6000)
        addField(sid: Sid.CurrentUnderLoad, intervalMs: 6000)

        startQueue2()
    }

    @objc func endQueue2() {
        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        DispatchQueue.main.async {
            switch sid {
            case Sid.Aux12V:
                self.text12V.text = String(format: "%.1f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                self.lblVoltage.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.chartEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateChart()
                }
            case Sid.Aux12A:
                self.text12A.text = String(format: "%.1f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.DcLoad:
                self.textDcLoad.text = String(format: "%.1f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.AuxStatus:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.aux_Status!.count {
                        self.textAuxStatus.text = self.aux_Status![Int(val!)]
                    }
                }
            case Sid.VehicleState:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.vehicle_Status!.count {
                        self.text_vehicle_state.text = self.vehicle_Status![Int(val!)]
                    }
                }
            case Sid.VoltageUnderLoad:
                self.textVoltageUnderLoad.text = String(format: "%.1f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.CurrentUnderLoad:
                self.textCurrentUnderLoad.text = String(format: "%.1f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            default:
                print("?")
            }
        }
    }

    func initChart() {
        chartView.legend.enabled = false
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0
        chartView.rightAxis.enabled = false
        let yAxis = chartView.leftAxis
        yAxis.axisMinimum = 9
        yAxis.axisMaximum = 15
    }

    func updateChart() {
        if chartEntries.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: chartEntries, label: nil)

//        line1.colors = [.red]
        line1.lineWidth = 0
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false

        let gradientColors = [ChartColorTemplates.colorFromString("#5050ff").cgColor,
                              ChartColorTemplates.colorFromString("#50ff50").cgColor,
                              ChartColorTemplates.colorFromString("#ff5050").cgColor]
//        let colorLocations: [CGFloat] = [0.0, 9.0, 12.0, 14.0, 99.0]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)
        line1.fill = Fill.fillWithLinearGradient(gradient!, angle: 90)
        line1.fillAlpha = 1
        line1.drawFilledEnabled = true

        chartView.data = LineChartData(dataSets: [line1])
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
