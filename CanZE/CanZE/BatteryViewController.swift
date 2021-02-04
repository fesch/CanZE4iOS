//
//  BatteryViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 09/01/21.
//

import Charts
import UIKit

class BatteryViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var cellVoltView: LineChartView!
    @IBOutlet var cellTempView: LineChartView!

    @IBOutlet var lblGraph_SOH_title: UILabel!
    @IBOutlet var lblGraph_SOH: UILabel!

    @IBOutlet var lblGraph_RealIndicatedSoc_title: UILabel!
    @IBOutlet var lblGraph_RealIndicatedSoc: UILabel!
    @IBOutlet var lblGraph_UserIndicatedSoc: UILabel!
    @IBOutlet var socChartView: LineChartView!
    var realSocChartEntries = [ChartDataEntry]()
    var userSocChartEntries = [ChartDataEntry]()

    @IBOutlet var lblHelp_QA: UILabel!

    @IBOutlet var lblGraph_CellVoltages_title: UILabel!
    @IBOutlet var voltChartView: LineChartView!
    var voltChartEntries = [ChartDataEntry]()

    @IBOutlet var lblGraph_ModuleTemperatures_title: UILabel!
    @IBOutlet var tempChartView: LineChartView!
    var tempChartEntries = [ChartDataEntry]()

    @IBOutlet var lblBatterySerial: UILabel!

    var doneOneTimeOnly = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_battery", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        lblGraph_SOH_title.text = NSLocalizedString("graph_SOH", comment: "")
        lblGraph_SOH.text = "-"

        lblGraph_RealIndicatedSoc_title.text = NSLocalizedString("graph_RealIndicatedSoc", comment: "")
        lblGraph_RealIndicatedSoc.text = "-"
        lblGraph_RealIndicatedSoc.textColor = .red
        lblGraph_UserIndicatedSoc.text = "-"
        lblGraph_UserIndicatedSoc.textColor = .blue

        lblHelp_QA.attributedText = NSLocalizedString("help_QA", comment: "").htmlToAttributedString

        lblGraph_CellVoltages_title.text = NSLocalizedString("graph_CellVoltages", comment: "")
        lblGraph_ModuleTemperatures_title.text = NSLocalizedString("graph_ModuleTemperatures", comment: "")

        lblBatterySerial.text = "Serial:"

        initSocChart()
        initVoltChart()
        initTempChart()
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
        addField(sid: "658.33", intervalMs: 5000) // state of health gives continuous timeouts. This frame is send at a very low rate

        addField(sid: Sid.UserSoC, intervalMs: 5000)
        addField(sid: Sid.RealSoC, intervalMs: 5000)

        // 7bb.6141.16,7bb.6141.32,7bb.6141.48,7bb.6141.64,7bb.6141.80,7bb.6141.96,7bb.6141.112,7bb.6141.128,7bb.6141.144,7bb.6141.160,7bb.6141.176,7bb.6141.192,7bb.6141.208,7bb.6141.224,7bb.6141.240,7bb.6141.256,7bb.6141.272,7bb.6141.288,7bb.6141.304,7bb.6141.320,7bb.6141.336,7bb.6141.352,7bb.6141.368,7bb.6141.384,7bb.6141.400,7bb.6141.416,7bb.6141.432,7bb.6141.448,7bb.6141.464,7bb.6141.480,7bb.6141.496,7bb.6141.512,7bb.6141.528,7bb.6141.544,7bb.6141.560,7bb.6141.576,7bb.6141.592,7bb.6141.608,7bb.6141.624,7bb.6141.640,7bb.6141.656,7bb.6141.672,7bb.6141.688,7bb.6141.704,7bb.6141.720,7bb.6141.736,7bb.6141.752,7bb.6141.768,7bb.6141.784,7bb.6141.800,7bb.6141.816,7bb.6141.832,7bb.6141.848,7bb.6141.864,7bb.6141.880,7bb.6141.896,7bb.6141.912,7bb.6141.928,7bb.6141.944,7bb.6141.960,7bb.6141.976,7bb.6141.992,7bb.6142.16,7bb.6142.32,7bb.6142.48,7bb.6142.64,7bb.6142.80,7bb.6142.96,7bb.6142.112,7bb.6142.128,7bb.6142.144,7bb.6142.160,7bb.6142.176,7bb.6142.192,7bb.6142.208,7bb.6142.224,7bb.6142.240,7bb.6142.256,7bb.6142.272,7bb.6142.288,7bb.6142.304,7bb.6142.320,7bb.6142.336,7bb.6142.352,7bb.6142.368,7bb.6142.384,7bb.6142.400,7bb.6142.416,7bb.6142.432,7bb.6142.448,7bb.6142.464,7bb.6142.480,7bb.6142.496,7bb.6142.512,7bb.6142.528,7bb.6142.544"

        // 7bb.6104.32,7bb.6104.56,7bb.6104.80,7bb.6104.104,7bb.6104.128,7bb.6104.152,7bb.6104.176,7bb.6104.200,7bb.6104.224,7bb.6104.248,7bb.6104.272,7bb.6104.296

        if !doneOneTimeOnly {
            addField(sid: Sid.BatterySerial, intervalMs: 5000)
            doneOneTimeOnly = true
        }

        addField(sid: "7bb.6141.16", intervalMs: 5000) // cell 1 volt

        addField(sid: "7bb.6104.32", intervalMs: 5000) // cell 1 temp

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
            case "658.33":
                self.lblGraph_SOH.text = String(format: "%.0f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.RealSoC:
                self.lblGraph_RealIndicatedSoc.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.realSocChartEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateSocChart()
                }
            case Sid.UserSoC:
                self.lblGraph_UserIndicatedSoc.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.userSocChartEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateSocChart()
                }
            case "7bb.6141.16":
                if self.fieldResultsDouble[sid!] != nil {
                    self.voltChartEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateVoltChart()
                }
            case "7bb.6104.32":
                if self.fieldResultsDouble[sid!] != nil {
                    self.tempChartEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateTempChart()
                }
            case Sid.BatterySerial:
                self.lblBatterySerial.text = "Serial: \(self.fieldResultsString[sid!] ?? "")"
            default:
                print("?")
            }
        }
    }

    func initSocChart() {
        socChartView.legend.enabled = false
        let xAxis = socChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0
        socChartView.rightAxis.enabled = false
        let yAxis = socChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 100
    }

    func initVoltChart() {
        voltChartView.legend.enabled = false
        let xAxis = voltChartView.xAxis
//        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        /*        xAxis.labelPosition = .bottom
         xAxis.labelFont = UIFont.systemFont(ofSize: 10.0)
         xAxis.labelTextColor = .red
         xAxis.valueFormatter = TimestampAxis()
         xAxis.labelRotationAngle = -45.0*/
//        xAxis.enabled = false
        xAxis.drawLabelsEnabled = false
        voltChartView.rightAxis.enabled = false
        let yAxis = voltChartView.leftAxis
        yAxis.drawLabelsEnabled = false
        yAxis.axisMinimum = 3
        yAxis.axisMaximum = 5
    }

    func initTempChart() {
        tempChartView.legend.enabled = false
        let xAxis = tempChartView.xAxis
//        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        /*        xAxis.labelPosition = .bottom
         xAxis.labelFont = UIFont.systemFont(ofSize: 10.0)
         xAxis.labelTextColor = .red
         xAxis.valueFormatter = TimestampAxis()
         xAxis.labelRotationAngle = -45.0*/
//        xAxis.enabled = false
        xAxis.drawLabelsEnabled = false
        tempChartView.rightAxis.enabled = false
        let yAxis = tempChartView.leftAxis
        yAxis.drawLabelsEnabled = false
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 50
    }

    func updateSocChart() {
        if realSocChartEntries.count == 0, userSocChartEntries.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: realSocChartEntries, label: nil)
        line1.colors = [.red]
        let line2 = LineChartDataSet(entries: userSocChartEntries, label: nil)
        line2.colors = [.blue]
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false
        socChartView.data = LineChartData(dataSets: [line1, line2])
    }

    func updateVoltChart() {
        if voltChartEntries.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: voltChartEntries, label: nil)
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line1.colors = [.red]
        voltChartView.data = LineChartData(dataSet: line1)
    }

    func updateTempChart() {
        if tempChartEntries.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: tempChartEntries, label: nil)
        line1.colors = [.red]
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        tempChartView.data = LineChartData(dataSet: line1)
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
