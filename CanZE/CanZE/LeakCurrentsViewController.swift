//
//  LeakCurrentsViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 09/02/21.
//

import Charts
import UIKit

class LeakCurrentsViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_LeakCurrentDc: UILabel!
    @IBOutlet var text_LeakCurrentDc: UILabel!
    @IBOutlet var leakCurrentDcChartView: LineChartView!
    var leakCurrentDcEntries = [ChartDataEntry]()
    var leakCurrentDcLine: LineChartDataSet!

    @IBOutlet var label_LeakCurrentLf: UILabel!
    @IBOutlet var text_LeakCurrentLf: UILabel!
    @IBOutlet var leakCurrentLfChartView: LineChartView!
    var leakCurrentLfEntries = [ChartDataEntry]()
    var leakCurrentLfLine: LineChartDataSet!

    @IBOutlet var label_LeakCurrentHf: UILabel!
    @IBOutlet var text_LeakCurrentHf: UILabel!
    @IBOutlet var leakCurrentHfChartView: LineChartView!
    var leakCurrentHfEntries = [ChartDataEntry]()
    var leakCurrentHfLine: LineChartDataSet!

    @IBOutlet var label_LeakCurrentEhf: UILabel!
    @IBOutlet var text_LeakCurrentEhf: UILabel!
    @IBOutlet var leakCurrentEhfChartView: LineChartView!
    var leakCurrentEhfEntries = [ChartDataEntry]()
    var leakCurrentEhfLine: LineChartDataSet!

    var doneOneTimeOnly = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_leakCurrents", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        label_LeakCurrentDc.text = NSLocalizedString("label_LeakCurrentDc", comment: "")
        text_LeakCurrentDc.text = "-"

        label_LeakCurrentLf.text = NSLocalizedString("label_LeakCurrentLf", comment: "")
        text_LeakCurrentLf.text = "-"

        label_LeakCurrentHf.text = NSLocalizedString("label_LeakCurrentHf", comment: "")
        text_LeakCurrentHf.text = "-"

        label_LeakCurrentEhf.text = NSLocalizedString("label_LeakCurrentEhf", comment: "")
        text_LeakCurrentEhf.text = "-"

        initLeakCurrentDcChart()
        initLeakCurrentLfChart()
        initLeakCurrentHfChart()
        initLeakCurrentEhfChart()
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

        if !doneOneTimeOnly {
            addField(Sid.BcbTesterInit, intervalMs: 0)
            doneOneTimeOnly = true
        }
        addField(Sid.BcbTesterAwake, intervalMs: 1500)

        addField("793.625057.24", intervalMs: 0)
        addField("793.62505a.24", intervalMs: 0)

        addField("793.625059.24", intervalMs: 0)
        addField("793.625058.24", intervalMs: 0)

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
                switch sid {
                case "793.625057.24":
                    self.text_LeakCurrentDc.text = String(format: "%.1f", val ?? Double.nan)
                    self.leakCurrentDcEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    self.updateLeakCurrentDcChart()
                case "793.62505a.24":
                    self.text_LeakCurrentLf.text = String(format: "%.1f", val ?? Double.nan)
                    self.leakCurrentLfEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    self.updateLeakCurrentLfChart()
                case "793.625059.24":
                    self.text_LeakCurrentHf.text = String(format: "%.1f", val ?? Double.nan)
                    self.leakCurrentHfEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    self.updateLeakCurrentHfChart()
                case "793.625058.24":
                    self.text_LeakCurrentEhf.text = String(format: "%.1f", val ?? Double.nan)
                    self.leakCurrentEhfEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    self.updateLeakCurrentEhfChart()
                default:
                    print("?")
                }
            }
        }
    }

    func initLeakCurrentDcChart() {
        leakCurrentDcChartView.legend.enabled = false
        leakCurrentDcChartView.rightAxis.enabled = false

        let xAxis = leakCurrentDcChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0

        let yAxis = leakCurrentDcChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 5

        leakCurrentDcLine = LineChartDataSet(entries: leakCurrentDcEntries, label: nil)
        leakCurrentDcLine.colors = [.red]
        leakCurrentDcLine.drawCirclesEnabled = false
        leakCurrentDcLine.drawValuesEnabled = false

        leakCurrentDcChartView.data = LineChartData(dataSet: leakCurrentDcLine)
    }

    func initLeakCurrentLfChart() {
        leakCurrentLfChartView.legend.enabled = false
        leakCurrentLfChartView.rightAxis.enabled = false

        let xAxis = leakCurrentLfChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0

        let yAxis = leakCurrentLfChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 10

        leakCurrentLfLine = LineChartDataSet(entries: leakCurrentLfEntries, label: nil)
        leakCurrentLfLine.colors = [.red]
        leakCurrentLfLine.drawCirclesEnabled = false
        leakCurrentLfLine.drawValuesEnabled = false

        leakCurrentLfChartView.data = LineChartData(dataSet: leakCurrentLfLine)
    }

    func initLeakCurrentHfChart() {
        leakCurrentHfChartView.legend.enabled = false
        leakCurrentHfChartView.rightAxis.enabled = false

        let xAxis = leakCurrentHfChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0

        let yAxis = leakCurrentHfChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 500

        leakCurrentHfLine = LineChartDataSet(entries: leakCurrentHfEntries, label: nil)
        leakCurrentHfLine.colors = [.red]
        leakCurrentHfLine.drawCirclesEnabled = false
        leakCurrentHfLine.drawValuesEnabled = false

        leakCurrentHfChartView.data = LineChartData(dataSet: leakCurrentHfLine)
    }

    func initLeakCurrentEhfChart() {
        leakCurrentEhfChartView.legend.enabled = false
        leakCurrentEhfChartView.rightAxis.enabled = false

        let xAxis = leakCurrentEhfChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0

        let yAxis = leakCurrentEhfChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 200

        leakCurrentEhfLine = LineChartDataSet(entries: leakCurrentEhfEntries, label: nil)
        leakCurrentEhfLine.colors = [.red]
        leakCurrentEhfLine.drawCirclesEnabled = false
        leakCurrentEhfLine.drawValuesEnabled = false

        leakCurrentEhfChartView.data = LineChartData(dataSet: leakCurrentEhfLine)
    }

    func updateLeakCurrentDcChart() {
        leakCurrentDcLine.replaceEntries(leakCurrentDcEntries)
        leakCurrentDcChartView.data = LineChartData(dataSet: leakCurrentDcLine)
    }

    func updateLeakCurrentLfChart() {
        leakCurrentLfLine.replaceEntries(leakCurrentLfEntries)
        leakCurrentLfChartView.data = LineChartData(dataSet: leakCurrentLfLine)
    }

    func updateLeakCurrentHfChart() {
        leakCurrentHfLine.replaceEntries(leakCurrentHfEntries)
        leakCurrentHfChartView.data = LineChartData(dataSet: leakCurrentHfLine)
    }

    func updateLeakCurrentEhfChart() {
        leakCurrentEhfLine.replaceEntries(leakCurrentEhfEntries)
        leakCurrentEhfChartView.data = LineChartData(dataSet: leakCurrentEhfLine)
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
