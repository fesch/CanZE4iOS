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

    var cooling_Status: [String] = []
    var conditioning_Status: [String] = []
    var climate_Status: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_clima_tech", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        cooling_Status = localizableFromPlist("list_CoolingStatus")
        conditioning_Status = localizableFromPlist(Utils.isPh2() ? "list_ConditioningStatusPh2" : "list_ConditioningStatus")
        climate_Status = localizableFromPlist(Utils.isPh2() ? "list_ClimateStatusPh2" : "list_ClimateStatus")

        label_EngineFanSpeed.text = NSLocalizedString_("label_EngineFanSpeed", comment: "")
        text_EFS.text = "-"
        textLabel_climatePower.text = NSLocalizedString_(Utils.isPh2() ? "label_ThermalComfortPower" : "label_DcPwr", comment: "")
        text_ClimatePower.text = "-"
        label_HVCoolingState.text = NSLocalizedString_("label_HVCoolingState", comment: "")
        text_HCS.text = "-"
        label_HVEvaporationTemp.text = NSLocalizedString_("label_HVEvaporationTemp", comment: "")
        text_HET.text = "-"
        label_ACPressure.text = NSLocalizedString_("label_ACPressure", comment: "")
        text_PRE.text = "-"
        label_HVBatConditioningMode.text = NSLocalizedString_("label_HVBatConditioningMode", comment: "")
        text_HCM.text = "-"
        label_ClimaLoopMode.text = NSLocalizedString_("label_ClimaLoopMode", comment: "")
        text_CLM.text = "-"

        label_IH_ClimCompPWRStatus.text = NSLocalizedString_("label_IH_ClimCompPWRStatus", comment: "")
        label_IH_ClimCompPWRStatus1.text = "-"
        label_IH_ClimCompPWRStatus2.text = "-"

        label_Temperatures.text = NSLocalizedString_("label_Temperatures", comment: "")
        graph_Climatech.text = NSLocalizedString_("graph_Climatech", comment: "")
        graph_Climatech1.text = "-"
        graph_Climatech1.textColor = .red
        graph_Climatech2.text = "-"
        graph_Climatech1.textColor = .blue
        graph_Climatech3.text = "-"
        graph_Climatech1.textColor = .green
        graph_Climatech4.text = "-"
        graph_Climatech1.textColor = .brown

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

        addField(Sid.EngineFanSpeed, intervalMs: 0)
        addField(Sid.HvCoolingState, intervalMs: 0)
        addField_(Sid.HvEvaporationTemp, intervalMs: 10000)
        addField_(Sid.Pressure, intervalMs: 1000)
        addField(Sid.BatteryConditioningMode, intervalMs: 0)
        addField(Sid.ClimaLoopMode, intervalMs: 0)

        if Utils.isPh2() {
            addField(Sid.ThermalComfortPower, intervalMs: 0)
        } else {
            addField(Sid.DcPowerOut, intervalMs: 0)
        }

        // graph data
        addField("764.6144.107", intervalMs: 0)
        addField("764.6143.86", intervalMs: 0)

        addField_("764.6143.110", intervalMs: 10000)
        addField_("764.6121.26", intervalMs: 10000)
        addField_("800.6105.24", intervalMs: 2000)
        addField_(Sid.HvTemp, intervalMs: 10000)

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
                case Sid.EngineFanSpeed:
                    text_EFS.text = String(format: "%.1f", val!)
                case Sid.DcPowerOut:
                    text_ClimatePower.text = String(format: "%.1f", val!)
                case Sid.HvCoolingState:
                    let i = Int(val!)
                    if i >= 0, i < cooling_Status.count {
                        text_HCS.text = cooling_Status[i]
                    }
                case Sid.HvEvaporationTemp:
                    text_HET.text = String(format: "%.1f", val!)
                case Sid.Pressure:
                    text_PRE.text = String(format: "%.1f", val!)
                case Sid.BatteryConditioningMode:
                    let i = Int(val!)
                    if i >= 0, i < conditioning_Status.count {
                        text_HCM.text = conditioning_Status[i]
                    }
                case Sid.ClimaLoopMode:
                    let i = Int(val!)
                    if i >= 0, i < climate_Status.count {
                        text_CLM.text = climate_Status[i]
                    }
                case Sid.ThermalComfortPower:
                    text_ClimatePower.text = String(format: "%.1f", val!)
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

                case "764.6143.110":
                    graph_Climatech1.text = String(format: "%.1f", val!)
                    tempChartEntries4.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    updateTempChart()
                case "764.6121.26":
                    graph_Climatech2.text = String(format: "%.1f", val!)
                    tempChartEntries3.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    updateTempChart()
                case "800.6105.24":
                    graph_Climatech3.text = String(format: "%.1f", val!)
                    tempChartEntries2.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    updateTempChart()
                case Sid.HvTemp:
                    graph_Climatech4.text = String(format: "%.2f", val!)
                    tempChartEntries1.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    updateTempChart()

                case "764.6144.107":
                    label_IH_ClimCompPWRStatus1.text = String(format: "%.0f", val!)
                    compChartEntries1.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    updateCompChart()
                case "764.6143.86":
                    label_IH_ClimCompPWRStatus2.text = String(format: "%.0f", val!)
                    compChartEntries2.append(ChartDataEntry(x: Date().timeIntervalSince1970, y: val!))
                    updateCompChart()

                default:
                    print("unknown sid \(sid!)")
                }
            }
        }
    }

    func initCompChart() {
        compChartView.legend.enabled = false
        // compChartView.rightAxis.enabled = false

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

        let yAxisRight = compChartView.rightAxis
        yAxisRight.axisMinimum = 0
        yAxisRight.axisMaximum = 1
        yAxisRight.granularity = 1
        yAxisRight.valueFormatter = IntFormatter()

        compChartLine2 = LineChartDataSet(entries: compChartEntries2, label: nil)
        compChartLine2.axisDependency = .right
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
        xAxis.labelTextColor = .black
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0
        // xAxis.enabled = false
        // xAxis.drawLabelsEnabled = false

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
        tempChartLine4.colors = [.brown]

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

    class IntFormatter: IAxisValueFormatter {
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return String(format: "%.0f", value)
        }
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
