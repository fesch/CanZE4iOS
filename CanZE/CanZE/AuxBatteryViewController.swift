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
    var chartEntries1 = [ChartDataEntry]()
    var chartEntries2 = [ChartDataEntry]()
    var line1: LineChartDataSet!
    var line2: LineChartDataSet!

    var aux_Status: [String] = []
    var vehicle_Status: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_auxbatt", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        aux_Status = localizableFromPlist("list_AuxStatus")
        vehicle_Status = localizableFromPlist(Utils.isPh2() ? "list_VehicleStatePh2" : "list_VehicleState")

        label_12V.text = NSLocalizedString_("label_12V", comment: "")
        text12V.text = "-"
        label_12A.text = NSLocalizedString_("label_12A", comment: "")
        text12A.text = "-"
        label_DcLoad.text = NSLocalizedString_("label_DcLoad", comment: "")
        textDcLoad.text = "-"
        label_vehiclestate.text = NSLocalizedString_("label_vehiclestate", comment: "")
        text_vehicle_state.text = "-"
        label_VoltageUnderLoad.text = NSLocalizedString_("label_VoltageLoad", comment: "")
        textVoltageUnderLoad.text = "-"
        label_CurrentUnderLoad.text = NSLocalizedString_("label_CurrentUnderLoad", comment: "")
        textCurrentUnderLoad.text = "-"
        label_AuxStatus.text = NSLocalizedString_("label_AuxStatus", comment: "")
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

        queue2 = []
        lastId = 0

        addField_(Sid.Aux12V, intervalMs: 2000)
        addField_(Sid.Aux12A, intervalMs: 1000)
        addField_(Sid.DcLoad, intervalMs: 1000)
        addField_(Sid.AuxStatus, intervalMs: 1000)
        addField_(Sid.VehicleState, intervalMs: 1000)
        // addField(Sid.ChargingStatusDisplay, 1000)
        addField_(Sid.VoltageUnderLoad, intervalMs: 6000)
        addField_(Sid.CurrentUnderLoad, intervalMs: 6000)

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

        let val = Globals.shared.fieldResultsDouble[sid!]
        if val != nil && !val!.isNaN {
            DispatchQueue.main.async { [self] in
                switch sid {
                case Sid.Aux12V:
                    text12V.text = String(format: "%.1f", val!)
                    lblVoltage.text = String(format: "%.2f", val!)
                    chartEntries1.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    updateChart()
                case Sid.Aux12A:
                    text12A.text = String(format: "%.1f", val!)
                case Sid.DcLoad:
                    textDcLoad.text = String(format: "%.1f", val!)
                case Sid.AuxStatus:
                    let i = Int(val!)
                    if i >= 0, i < aux_Status.count {
                        textAuxStatus.text = aux_Status[i]
                    }
                case Sid.VehicleState:
                    let i = Int(val!)
                    if i >= 0, i < vehicle_Status.count {
                        text_vehicle_state.text = vehicle_Status[i]
                        chartEntries2.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: Double(i)))
                        updateChart()
                    }
                case Sid.VoltageUnderLoad:
                    textVoltageUnderLoad.text = String(format: "%.1f", val!)
                case Sid.CurrentUnderLoad:
                    textCurrentUnderLoad.text = String(format: "%.1f", val!)
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

    func initChart() {
        chartView.legend.enabled = false
        chartView.rightAxis.enabled = false

        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0

        let yAxis = chartView.leftAxis
        yAxis.axisMinimum = 9
        yAxis.axisMaximum = 15

        line1 = LineChartDataSet(entries: chartEntries1, label: nil)

        line1.lineWidth = 0
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false

        let gradientColors1 = [ChartColorTemplates.colorFromString("#5050ff").cgColor,
                               ChartColorTemplates.colorFromString("#50ff50").cgColor,
                               ChartColorTemplates.colorFromString("#ff5050").cgColor]
        let gradient1 = CGGradient(colorsSpace: nil, colors: gradientColors1 as CFArray, locations: [0.0, 0.75, 1.0])
        line1.fill = Fill.fillWithLinearGradient(gradient1!, angle: 90)
        line1.fillAlpha = 1
        line1.drawFilledEnabled = true

        line2 = LineChartDataSet(entries: chartEntries2, label: nil)
        line2.lineWidth = 0
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false

        let gradientColors2 = [ChartColorTemplates.colorFromString("#ff0000").cgColor,
                               ChartColorTemplates.colorFromString("#00ff00").cgColor,
                               ChartColorTemplates.colorFromString("#0000ff").cgColor,
                               ChartColorTemplates.colorFromString("#ffff00").cgColor,
                               ChartColorTemplates.colorFromString("#00ffff").cgColor,
                               ChartColorTemplates.colorFromString("#ff00ff").cgColor,
                               ChartColorTemplates.colorFromString("#000000").cgColor,
                               ChartColorTemplates.colorFromString("#808080").cgColor]
        let gradient2 = CGGradient(colorsSpace: nil, colors: gradientColors2 as CFArray, locations: [0.0, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0])
        line2.fill = Fill.fillWithLinearGradient(gradient2!, angle: 90)
        line2.fillAlpha = 1
        line2.drawFilledEnabled = true
    }

    func updateChart() {
        line1.replaceEntries(chartEntries1)
        line2.replaceEntries(chartEntries2)
        chartView.data = LineChartData(dataSets: [line1, line2])
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
