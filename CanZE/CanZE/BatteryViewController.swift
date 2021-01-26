//
//  BatteryViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 09/01/21.
//

import Charts
import UIKit

class BatteryViewController: CanZeViewController {
    @IBOutlet var socChartView: LineChartView!
    var realSocChartEntries = [ChartDataEntry]()
    var userSocChartEntries = [ChartDataEntry]()

    @IBOutlet var cellVoltView: LineChartView!
    @IBOutlet var cellTempView: LineChartView!

    @IBOutlet var lblGraph_SOH_title: UILabel!
    @IBOutlet var lblGraph_SOH: UILabel!

    @IBOutlet var lblGraph_RealIndicatedSoc_title: UILabel!
    @IBOutlet var lblGraph_RealIndicatedSoc: UILabel!
    @IBOutlet var lblGraph_UserIndicatedSoc: UILabel!

    @IBOutlet var lblHelp_QA: UILabel!

    @IBOutlet var lblGraph_CellVoltages: UILabel!
    @IBOutlet var lblGraph_ModuleTemperatures_title: UILabel!

    @IBOutlet var lblBatterySerial: UILabel!

    @IBOutlet var lblDebug: UILabel!

    var timer: Timer!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_battery", comment: "")

        lblGraph_SOH_title.text = NSLocalizedString("graph_SOH", comment: "")
        lblGraph_SOH.text = "-"

        lblGraph_RealIndicatedSoc_title.text = NSLocalizedString("graph_RealIndicatedSoc", comment: "")
        lblGraph_RealIndicatedSoc.text = "-"
        lblGraph_RealIndicatedSoc.textColor = .red
        lblGraph_UserIndicatedSoc.text = "-"
        lblGraph_UserIndicatedSoc.textColor = .blue

        lblHelp_QA.attributedText = NSLocalizedString("help_QA", comment: "").htmlToAttributedString

        lblGraph_CellVoltages.text = NSLocalizedString("graph_CellVoltages", comment: "")
        lblGraph_ModuleTemperatures_title.text = NSLocalizedString("graph_ModuleTemperatures", comment: "")

        lblBatterySerial.text = "Serial:"
        lblDebug.text = ""

        // NotificationCenter.default.addObserver(self, selector: #selector(ricevuto2(notification:)), name: Notification.Name("ricevuto2"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(decodificato), name: Notification.Name("decodificato"), object: nil)

        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in

            self.coda2 = []

            if Utils.isPh2() {
                self.addField(sid: "7ec.5003.0", intervalMs: 2000) // open EVC
            }
            self.addField(sid: Sid.BatterySerial, intervalMs: 5000)
            self.addField(sid: Sid.UserSoC, intervalMs: 5000)
            self.addField(sid: Sid.RealSoC, intervalMs: 5000)

            self.addField(sid: Sid.SOH, intervalMs: 5000) // state of health gives continuous timeouts. This frame is send at a very low rate
            /* addField(sid: Sid.RangeEstimate, intervalMs: 5000)
             addField(sid: Sid.DcPowerIn, intervalMs: 5000)
             addField(sid: Sid.AvailableChargingPower, intervalMs: 5000)
             addField(sid: Sid.HvTemp, intervalMs: 5000)
             */
            if AppSettings.shared.deviceIsConnected, AppSettings.shared.deviceIsInitialized {
                self.iniziaCoda2()
            } else {
                self.view.makeToast("_device not connected")
                timer.invalidate()
            }
        }
        timer.fire()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decodificato"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("ricevuto2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
        timer.invalidate()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc func updateDebugLabel(notification: Notification) {
        let dic = notification.object as? [String: String]
        DispatchQueue.main.async {
            self.lblDebug.text = dic?["debug"]
        }
    }

    @objc func decodificato() {
        print("decodificato")
        DispatchQueue.main.async {
            var f = Fields.getInstance.fieldsBySid[Sid.BatterySerial]
            self.lblBatterySerial.text = "Serial: \(self.fieldResultsString[f!.sid] ?? "")"

            f = Fields.getInstance.fieldsBySid[Sid.RealSoC]
            self.lblGraph_RealIndicatedSoc.text = String(format: "%.2f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)
            if self.fieldResultsDouble[f!.sid] != nil {
                self.realSocChartEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[f!.sid] ?? Double.nan))
            }

            f = Fields.getInstance.fieldsBySid[Sid.UserSoC]
            self.lblGraph_UserIndicatedSoc.text = String(format: "%.2f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)
            if self.fieldResultsDouble[f!.sid] != nil {
                self.userSocChartEntries.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: self.fieldResultsDouble[f!.sid] ?? Double.nan))
            }

            f = Fields.getInstance.fieldsBySid[Sid.SOH]
            self.lblGraph_SOH.text = String(format: "%.0f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

            /*
                        f = Fields.getInstance.fieldsBySid[Sid.RangeEstimate]
                        self.lblAvailableRange.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

                        f = Fields.getInstance.fieldsBySid[Sid.DcPowerIn]
                        self.lblDCPower.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

                        f = Fields.getInstance.fieldsBySid[Sid.AvailableChargingPower]
                        self.lblAvailableChargingPower.text = String(format: "%.\(f?.decimals ?? 2)f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)

                        f = Fields.getInstance.fieldsBySid[Sid.HvTemp]
                        self.lblMeanBatteryTemperature.text = String(format: "%.2f", (self.fieldResultsDouble[f!.sid] ?? Double.nan) as Double)
             */

            self.updateSocChart()
        }
    }

    func updateSocChart() {
        if realSocChartEntries.count == 0 {
            return
        }
        let line1 = LineChartDataSet(entries: realSocChartEntries, label: nil)
        line1.colors = [.red]
        let line2 = LineChartDataSet(entries: userSocChartEntries, label: nil)
        line2.colors = [.blue]

        socChartView.legend.enabled = false

        line1.drawCirclesEnabled = false
        line1.drawValuesEnabled = false
        line2.drawCirclesEnabled = false
        line2.drawValuesEnabled = false

        let xAxis = socChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 10.0)
        xAxis.labelTextColor = .red
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        xAxis.labelRotationAngle = -45.0

        socChartView.rightAxis.enabled = false

        let yAxis = socChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 100

        let data = LineChartData()
        data.addDataSet(line1)
        data.addDataSet(line2)
        socChartView.data = data
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

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
     }
     */
}
