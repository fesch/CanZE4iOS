//
//  ChargingGraphViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 28/01/21.
//

import Charts
import UIKit

class ChargingGraphViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var graph_PilotPower: UILabel!
    @IBOutlet var pilotPowerView: LineChartView!
    var pilotPowerChartEntries1 = [ChartDataEntry]()
    var pilotPowerChartEntries2 = [ChartDataEntry]()
    @IBOutlet var graph_PilotPower1: UILabel!
    @IBOutlet var graph_PilotPower2: UILabel!

    @IBOutlet var graph_MaxRealChPwr: UILabel!
    @IBOutlet var maxRealChPwrView: LineChartView!
    var maxRealChPwrChartEntries1 = [ChartDataEntry]()
    var maxRealChPwrChartEntries2 = [ChartDataEntry]()
    @IBOutlet var graph_MaxRealChPwr1: UILabel!
    @IBOutlet var graph_MaxRealChPwr2: UILabel!

    @IBOutlet var graph_EnergyTemperature: UILabel!
    @IBOutlet var energyTemperatureView: LineChartView!
    var energyTemperatureChartEntries1 = [ChartDataEntry]()
    var energyTemperatureChartEntries2 = [ChartDataEntry]()
    @IBOutlet var graph_EnergyTemperature1: UILabel!
    @IBOutlet var graph_EnergyTemperature2: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_charging_graph", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        graph_PilotPower.text = NSLocalizedString("graph_PilotPower", comment: "")
        graph_PilotPower1.text = "-"
        graph_PilotPower2.text = "-"

        graph_MaxRealChPwr.text = NSLocalizedString("graph_MaxRealChPwr", comment: "")
        graph_MaxRealChPwr1.text = "-"
        graph_MaxRealChPwr2.text = "-"

        graph_EnergyTemperature.text = NSLocalizedString("graph_EnergyTemperature", comment: "")
        graph_EnergyTemperature1.text = "-"
        graph_EnergyTemperature2.text = "-"

        initPilotPowerChart()
        initMaxRealChPwrChart()
        initEnergyTemperatureChart()
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

        addField(sid: Sid.ACPilot, intervalMs: 10000)
        addField(sid: Sid.AvailableChargingPower, intervalMs: 10000)

        addField(sid: Sid.MaxCharge, intervalMs: 10000)
        addField(sid: Sid.DcPowerIn, intervalMs: 10000)

        addField(sid: Sid.AvailableEnergy, intervalMs: 10000)
        addField(sid: Sid.HvTemp, intervalMs: 10000)

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
            case Sid.ACPilot:
                self.graph_PilotPower1.text = String(format: "%.0f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.pilotPowerChartEntries1.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updatePilotPowerChart()
                }
            case Sid.AvailableChargingPower:
                self.graph_PilotPower2.text = String(format: "%.1f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.pilotPowerChartEntries2.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updatePilotPowerChart()
                }

            case Sid.MaxCharge:
                self.graph_MaxRealChPwr1.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.maxRealChPwrChartEntries1.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateMaxRealChPwrChart()
                }
            case Sid.DcPowerIn:
                self.graph_MaxRealChPwr2.text = String(format: "%.0f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.maxRealChPwrChartEntries2.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateMaxRealChPwrChart()
                }

            case Sid.AvailableEnergy:
                self.graph_EnergyTemperature1.text = String(format: "%.1f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.energyTemperatureChartEntries1.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateEnergyTemperatureChart()
                }
            case Sid.HvTemp:
                self.graph_EnergyTemperature2.text = String(format: "%.0f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
                if self.fieldResultsDouble[sid!] != nil {
                    self.energyTemperatureChartEntries2.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[sid!] ?? Double.nan))
                    self.updateEnergyTemperatureChart()
                }

            default:
                print("?")
            }
        }
    }

    func initPilotPowerChart() {
        pilotPowerView.legend.enabled = false
        let xAxis = pilotPowerView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0
        pilotPowerView.rightAxis.enabled = false
        let yAxis = pilotPowerView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 64
    }

    func initMaxRealChPwrChart() {
        maxRealChPwrView.legend.enabled = false
        let xAxis = maxRealChPwrView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0
        maxRealChPwrView.rightAxis.enabled = false
        let yAxis = maxRealChPwrView.leftAxis
        yAxis.axisMinimum = 0
//        yAxis.axisMaximum = 100
    }

    func initEnergyTemperatureChart() {
        energyTemperatureView.legend.enabled = false
        let xAxis = energyTemperatureView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0
        energyTemperatureView.rightAxis.enabled = false
        let yAxis = energyTemperatureView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 40
    }

    func updatePilotPowerChart() {
        if pilotPowerChartEntries1.count == 0, pilotPowerChartEntries2.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: pilotPowerChartEntries1, label: nil)
        line1.colors = [.red]
        let line2 = LineChartDataSet(entries: pilotPowerChartEntries2, label: nil)
        line2.colors = [.blue]
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false
        pilotPowerView.data = LineChartData(dataSets: [line1, line2])
    }

    func updateMaxRealChPwrChart() {
        if maxRealChPwrChartEntries1.count == 0, maxRealChPwrChartEntries2.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: maxRealChPwrChartEntries1, label: nil)
        line1.colors = [.red]
        let line2 = LineChartDataSet(entries: maxRealChPwrChartEntries2, label: nil)
        line2.colors = [.blue]
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false
        maxRealChPwrView.data = LineChartData(dataSets: [line1, line2])
    }

    func updateEnergyTemperatureChart() {
        if energyTemperatureChartEntries1.count == 0, energyTemperatureChartEntries2.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: energyTemperatureChartEntries1, label: nil)
        line1.colors = [.red]
        let line2 = LineChartDataSet(entries: energyTemperatureChartEntries2, label: nil)
        line2.colors = [.blue]
        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false
        energyTemperatureView.data = LineChartData(dataSets: [line1, line2])
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
