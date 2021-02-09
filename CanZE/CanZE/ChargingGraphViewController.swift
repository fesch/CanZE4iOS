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
    var pilotPowerChartLine1 = LineChartDataSet()
    var pilotPowerChartLine2 = LineChartDataSet()

    @IBOutlet var graph_PilotPower1: UILabel!
    @IBOutlet var graph_PilotPower2: UILabel!

    @IBOutlet var graph_MaxRealChPwr: UILabel!
    @IBOutlet var maxRealChPwrView: LineChartView!
    var maxRealChPwrChartEntries1 = [ChartDataEntry]()
    var maxRealChPwrChartEntries2 = [ChartDataEntry]()
    @IBOutlet var graph_MaxRealChPwr1: UILabel!
    @IBOutlet var graph_MaxRealChPwr2: UILabel!
    var maxRealChPwrChartLine1 = LineChartDataSet()
    var maxRealChPwrChartLine2 = LineChartDataSet()

    @IBOutlet var graph_EnergyTemperature: UILabel!
    @IBOutlet var energyTemperatureView: LineChartView!
    var energyTemperatureChartEntries1 = [ChartDataEntry]()
    var energyTemperatureChartEntries2 = [ChartDataEntry]()
    @IBOutlet var graph_EnergyTemperature1: UILabel!
    @IBOutlet var graph_EnergyTemperature2: UILabel!
    var energyTemperatureChartLine1 = LineChartDataSet()
    var energyTemperatureChartLine2 = LineChartDataSet()

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

        addField(Sid.ACPilot, intervalMs: 10000)
        addField(Sid.AvailableChargingPower, intervalMs: 10000)

        addField(Sid.MaxCharge, intervalMs: 10000)
        addField(Sid.DcPowerIn, intervalMs: 10000)

        addField(Sid.AvailableEnergy, intervalMs: 10000)
        addField(Sid.HvTemp, intervalMs: 10000)

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
        pilotPowerView.rightAxis.enabled = false

        let xAxis = pilotPowerView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0

        let yAxis = pilotPowerView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 64

        pilotPowerChartLine1 = LineChartDataSet(entries: pilotPowerChartEntries1, label: nil)
        pilotPowerChartLine1.colors = [.red]
        pilotPowerChartLine1.drawCirclesEnabled = false
        pilotPowerChartLine1.drawValuesEnabled = false

        pilotPowerChartLine2 = LineChartDataSet(entries: pilotPowerChartEntries2, label: nil)
        pilotPowerChartLine2.colors = [.blue]
        pilotPowerChartLine2.drawCirclesEnabled = false
        pilotPowerChartLine2.drawValuesEnabled = false

        pilotPowerView.data = LineChartData(dataSets: [pilotPowerChartLine1, pilotPowerChartLine2])
    }

    func initMaxRealChPwrChart() {
        maxRealChPwrView.legend.enabled = false
        maxRealChPwrView.rightAxis.enabled = false

        let xAxis = maxRealChPwrView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0

        let yAxis = maxRealChPwrView.leftAxis
        yAxis.axisMinimum = 0
//        yAxis.axisMaximum = 100

        maxRealChPwrChartLine1 = LineChartDataSet(entries: maxRealChPwrChartEntries1, label: nil)
        maxRealChPwrChartLine1.colors = [.red]
        maxRealChPwrChartLine1.drawCirclesEnabled = false
        maxRealChPwrChartLine1.drawValuesEnabled = false

        maxRealChPwrChartLine2 = LineChartDataSet(entries: maxRealChPwrChartEntries2, label: nil)
        maxRealChPwrChartLine2.colors = [.blue]
        maxRealChPwrChartLine2.drawCirclesEnabled = false
        maxRealChPwrChartLine2.drawValuesEnabled = false

        maxRealChPwrView.data = LineChartData(dataSets: [maxRealChPwrChartLine1, maxRealChPwrChartLine2])
    }

    func initEnergyTemperatureChart() {
        energyTemperatureView.legend.enabled = false
        energyTemperatureView.rightAxis.enabled = false

        let xAxis = energyTemperatureView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
//        xAxis.labelRotationAngle = -45.0

        let yAxis = energyTemperatureView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 40

        energyTemperatureChartLine1 = LineChartDataSet(entries: energyTemperatureChartEntries1, label: nil)
        energyTemperatureChartLine1.colors = [.red]
        energyTemperatureChartLine1.drawCirclesEnabled = false
        energyTemperatureChartLine1.drawValuesEnabled = false

        energyTemperatureChartLine2 = LineChartDataSet(entries: energyTemperatureChartEntries2, label: nil)
        energyTemperatureChartLine2.colors = [.blue]
        energyTemperatureChartLine2.drawCirclesEnabled = false
        energyTemperatureChartLine2.drawValuesEnabled = false

        energyTemperatureView.data = LineChartData(dataSets: [energyTemperatureChartLine1, energyTemperatureChartLine2])
    }

    func updatePilotPowerChart() {
        pilotPowerChartLine1.replaceEntries(pilotPowerChartEntries1)
        pilotPowerChartLine2.replaceEntries(pilotPowerChartEntries2)
        pilotPowerView.data = LineChartData(dataSets: [pilotPowerChartLine1, pilotPowerChartLine2])
    }

    func updateMaxRealChPwrChart() {
        maxRealChPwrChartLine1.replaceEntries(maxRealChPwrChartEntries1)
        maxRealChPwrChartLine2.replaceEntries(maxRealChPwrChartEntries2)
        maxRealChPwrView.data = LineChartData(dataSets: [maxRealChPwrChartLine1, maxRealChPwrChartLine2])
    }

    func updateEnergyTemperatureChart() {
        energyTemperatureChartLine1.replaceEntries(energyTemperatureChartEntries1)
        energyTemperatureChartLine2.replaceEntries(energyTemperatureChartEntries2)
        energyTemperatureView.data = LineChartData(dataSets: [energyTemperatureChartLine1, energyTemperatureChartLine2])
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
