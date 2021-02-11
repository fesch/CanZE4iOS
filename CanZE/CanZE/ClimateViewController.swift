//
//  ClimateViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 09/02/21.
//

import Charts
import UIKit

class ClimateViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_EngineFanSpeed: UILabel!
    @IBOutlet var text_EFS: UILabel!
    @IBOutlet var textLabel_climatePower: UILabel!
    @IBOutlet var text_ClimatePower: UILabel!
    @IBOutlet var label_HVCoolingState: UILabel!
    @IBOutlet var text_HCS: UILabel!
    @IBOutlet var label_HVEvaporationTemp: UILabel!
    @IBOutlet var text_HET: UILabel!
    @IBOutlet var label_ACPressure: UILabel!
    @IBOutlet var text_PRE: UILabel!
    @IBOutlet var label_HVBatConditioningMode: UILabel!
    @IBOutlet var text_HCM: UILabel!
    @IBOutlet var label_ClimaLoopMode: UILabel!
    @IBOutlet var text_CLM: UILabel!

    @IBOutlet var label_IH_ClimCompPWRStatus: UILabel!
    @IBOutlet var label_IH_ClimCompPWRStatus1: UILabel!
    @IBOutlet var label_IH_ClimCompPWRStatus2: UILabel!
    @IBOutlet var compChartView: LineChartView!
    var compChartEntries1 = [ChartDataEntry]()
    var compChartEntries2 = [ChartDataEntry]()
    var compChartLine1: LineChartDataSet!
    var compChartLine2: LineChartDataSet!

    @IBOutlet var label_Temperatures: UILabel!
    @IBOutlet var graph_Climatech: UILabel!
    @IBOutlet var graph_Climatech1: UILabel!
    @IBOutlet var graph_Climatech2: UILabel!
    @IBOutlet var graph_Climatech3: UILabel!
    @IBOutlet var graph_Climatech4: UILabel!
    @IBOutlet var tempChartView: LineChartView!
    var tempChartEntries1 = [ChartDataEntry]()
    var tempChartEntries2 = [ChartDataEntry]()
    var tempChartEntries3 = [ChartDataEntry]()
    var tempChartEntries4 = [ChartDataEntry]()
    var tempChartLine1: LineChartDataSet!
    var tempChartLine2: LineChartDataSet!
    var tempChartLine3: LineChartDataSet!
    var tempChartLine4: LineChartDataSet!

    let cooling_Status = Globals.localizableFromPlist?.value(forKey: "list_CoolingStatus") as? [String]
    let conditioning_Status = Globals.localizableFromPlist?.value(forKey: Utils.isPh2() ? "list_ConditioningStatusPh2" : "list_ConditioningStatus") as? [String]
    let climate_Status = Globals.localizableFromPlist?.value(forKey: Utils.isPh2() ? "list_ClimateStatusPh2" : "list_ClimateStatus") as? [String]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_clima_tech", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        label_EngineFanSpeed.text = NSLocalizedString("label_EngineFanSpeed", comment: "")
        text_EFS.text = "-"
        textLabel_climatePower.text = NSLocalizedString(Utils.isPh2() ? "label_ThermalComfortPower" : "label_DcPwr", comment: "")
        text_ClimatePower.text = "-"
        label_HVCoolingState.text = NSLocalizedString("label_HVCoolingState", comment: "")
        text_HCS.text = "-"
        label_HVEvaporationTemp.text = NSLocalizedString("label_HVEvaporationTemp", comment: "")
        text_HET.text = "-"
        label_ACPressure.text = NSLocalizedString("label_ACPressure", comment: "")
        text_PRE.text = "-"
        label_HVBatConditioningMode.text = NSLocalizedString("label_HVBatConditioningMode", comment: "")
        text_HCM.text = "-"
        label_ClimaLoopMode.text = NSLocalizedString("label_ClimaLoopMode", comment: "")
        text_CLM.text = "-"

        label_IH_ClimCompPWRStatus.text = NSLocalizedString("label_IH_ClimCompPWRStatus", comment: "")
        label_IH_ClimCompPWRStatus1.text = "-"
        label_IH_ClimCompPWRStatus2.text = "-"

        label_Temperatures.text = NSLocalizedString("label_Temperatures", comment: "")
        graph_Climatech.text = NSLocalizedString("graph_Climatech", comment: "")
        graph_Climatech1.text = "-"
        graph_Climatech2.text = "-"
        graph_Climatech3.text = "-"
        graph_Climatech4.text = "-"

        initCompChart()
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

        addField(Sid.EngineFanSpeed, intervalMs: 0)
        addField(Sid.HvCoolingState, intervalMs: 0)
        addField(Sid.HvEvaporationTemp, intervalMs: 10000)
        addField(Sid.Pressure, intervalMs: 1000)
        addField(Sid.BatteryConditioningMode, intervalMs: 0)
        addField(Sid.ClimaLoopMode, intervalMs: 0)

        if Utils.isPh2() {
            addField(Sid.ThermalComfortPower, intervalMs: 0)
        } else {
            addField(Sid.DcPowerOut, intervalMs: 0)
        }

        addField("764.6144.107", intervalMs: 0)
        addField("764.6143.86", intervalMs: 0)

        addField("764.6143.110", intervalMs: 10000)
        addField("764.6121.26", intervalMs: 10000)
        addField("800.6105.24", intervalMs: 2000)
        addField(Sid.HvTemp, intervalMs: 10000)

        startQueue2()
    }

    @objc func endQueue2() {
        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let val = Globals.shared.fieldResultsDouble[sid!]

        DispatchQueue.main.async {
            switch sid {
            case Sid.EngineFanSpeed:
                self.text_EFS.text = String(format: "%.1f", val ?? Double.nan)
            case Sid.DcPowerOut:
                self.text_ClimatePower.text = String(format: "%.1f", val ?? Double.nan)
            case Sid.HvCoolingState:
                let i = Int(val!)
                if i >= 0, i < self.cooling_Status!.count {
                    self.text_HCS.text = self.cooling_Status![i]
                }
            case Sid.HvEvaporationTemp:
                self.text_HET.text = String(format: "%.1f", val ?? Double.nan)
            case Sid.Pressure:
                self.text_PRE.text = String(format: "%.1f", val ?? Double.nan)
            case Sid.BatteryConditioningMode:
                let i = Int(val!)
                if i >= 0, i < self.conditioning_Status!.count {
                    self.text_HCM.text = self.conditioning_Status![i]
                }
            case Sid.ClimaLoopMode:
                let i = Int(val!)
                if i >= 0, i < self.climate_Status!.count {
                    self.text_CLM.text = self.climate_Status![i]
                }
            case Sid.ThermalComfortPower:
                self.text_ClimatePower.text = String(format: "%.1f", val ?? Double.nan)
                     // case Sid.PtcRelay1:
                     //    value = (int) field.getValue();
                     //    tv = findViewById(R.id.text_PTC1);
                     //    if (tv != null && ptc_Relay != null && value >= 0 && value < ptc_Relay.length)
                     //        tv.setText(ptc_Relay[value]);
                     //    tv = null;
                     //    break;
                     // case Sid.PtcRelay2:
                     //    value = (int) field.getValue();
                     //    tv = findViewById(R.id.text_PTC2);
                     //    if (tv != null && ptc_Relay != null && value >= 0 && value < ptc_Relay.length)
                     //        tv.setText(ptc_Relay[value]);
                     //    tv = null;
                     //    break;
                     // case Sid.PtcRelay3:
                     //    value = (int) field.getValue();
                     //    tv = findViewById(R.id.text_PTC3);
                     //    if (tv != null && ptc_Relay != null && value >= 0 && value < ptc_Relay.length)
                     //        tv.setText(ptc_Relay[value]);
                     //    tv = null;
                     //    break;

            default:
                print("?")
            }
        }
    }

    func initCompChart() {
        compChartView.legend.enabled = false
        compChartView.rightAxis.enabled = false

        let xAxis = compChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0

        let yAxis = compChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 7000

        compChartLine1 = LineChartDataSet(entries: compChartEntries1, label: nil)
        compChartLine1.colors = [.red]
        compChartLine1.drawCirclesEnabled = false
        compChartLine1.drawValuesEnabled = false

        compChartLine2 = LineChartDataSet(entries: compChartEntries2, label: nil)
        compChartLine2.colors = [.blue]
        compChartLine2.drawCirclesEnabled = false
        compChartLine2.drawValuesEnabled = false

        compChartView.data = LineChartData(dataSets: [compChartLine1, compChartLine2])
    }

    func initTempChart() {
        tempChartView.legend.enabled = false
        tempChartView.rightAxis.enabled = false

        let xAxis = tempChartView.xAxis
        // xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 10.0)
        xAxis.labelTextColor = .red
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0
        // xAxis.enabled = false
        xAxis.drawLabelsEnabled = false

        let yAxis = tempChartView.leftAxis
        // yAxis.drawLabelsEnabled = true
        yAxis.axisMinimum = -10
        yAxis.axisMaximum = 40

        tempChartLine1 = LineChartDataSet(entries: tempChartEntries1, label: nil)
        tempChartLine1.drawCirclesEnabled = false
        tempChartLine1.drawValuesEnabled = false
        tempChartLine1.colors = [.red]

        tempChartLine2 = LineChartDataSet(entries: tempChartEntries2, label: nil)
        tempChartLine2.drawCirclesEnabled = false
        tempChartLine2.drawValuesEnabled = false
        tempChartLine2.colors = [.green]

        tempChartLine3 = LineChartDataSet(entries: tempChartEntries3, label: nil)
        tempChartLine3.drawCirclesEnabled = false
        tempChartLine3.drawValuesEnabled = false
        tempChartLine3.colors = [.blue]

        tempChartLine4 = LineChartDataSet(entries: tempChartEntries4, label: nil)
        tempChartLine4.drawCirclesEnabled = false
        tempChartLine4.drawValuesEnabled = false
        tempChartLine4.colors = [.yellow]

        tempChartView.data = LineChartData(dataSets: [tempChartLine1, tempChartLine2, tempChartLine3, tempChartLine4])
    }

    func updateCompChart() {
        compChartLine1.replaceEntries(compChartEntries1)
        compChartLine2.replaceEntries(compChartEntries2)
        compChartView.data = LineChartData(dataSets: [compChartLine1, compChartLine2])
    }

    func updateTempChart() {
        tempChartLine1.replaceEntries(tempChartEntries1)
        tempChartLine2.replaceEntries(tempChartEntries2)
        tempChartLine3.replaceEntries(tempChartEntries3)
        tempChartLine4.replaceEntries(tempChartEntries4)
        tempChartView.data = LineChartData(dataSets: [tempChartLine1, tempChartLine2, tempChartLine3, tempChartLine4])
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
