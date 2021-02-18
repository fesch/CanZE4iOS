//
//  RangeViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 09/02/21.
//

import Charts
import UIKit

class RangeViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var label_RangeRemaining: UILabel!
    @IBOutlet var carRange: UILabel!
    @IBOutlet var label_RangeRemainingCanZE: UILabel!
    @IBOutlet var canzeRange: UILabel!
    @IBOutlet var label_EstimatedDrivingStyleLoss: UILabel!

    @IBOutlet var slider: UISlider!
    @IBOutlet var lossView: UILabel!

    @IBOutlet var graph_DistanceEnergy: UILabel!
    @IBOutlet var text_DistanceEnergy1: UILabel!
    @IBOutlet var text_DistanceEnergy2: UILabel!

    @IBOutlet var distanceEnergyChartView: LineChartView!
    var distanceEnergyEntries1 = [ChartDataEntry]()
    var distanceEnergyEntries2 = [ChartDataEntry]()
    var distanceEnergyLine1: LineChartDataSet!
    var distanceEnergyLine2: LineChartDataSet!

    var distance = 0.0
    var range = 0.0
    var rangeWorst = 0.0
    var rangeBest = 0.0
    var energy = 0.0
    var consumption = 1.0
    var consumptionWorst = 1.0
    var consumptionBest = 1.0

    var loss = 0.1

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_range", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        label_RangeRemaining.text = NSLocalizedString("label_RangeRemaining", comment: "")
        carRange.text = "-"
        label_RangeRemainingCanZE.text = NSLocalizedString("label_RangeRemainingCanZE", comment: "")
        canzeRange.text = "-"
        label_EstimatedDrivingStyleLoss.text = NSLocalizedString("label_EstimatedDrivingStyleLoss", comment: "")

        lossView.text = "%"

        graph_DistanceEnergy.text = NSLocalizedString("graph_DistanceEnergy", comment: "")
        text_DistanceEnergy1.text = "-"
        text_DistanceEnergy1.textColor = .red
        text_DistanceEnergy2.text = "-"
        text_DistanceEnergy2.textColor = .blue

        initChart()

        if ud.exists(key: "loss") {
            loss = Double(ud.integer(forKey: "loss")) / 100.0
        } else {
            loss = 60.0
        }

        let progressPosition = loss
        slider.value = Float(progressPosition)
        updateSeekBar()
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

        addField_(Sid.RangeEstimate, intervalMs: 2000)
        addField_(Sid.AvailableEnergy, intervalMs: 2000)
        addField_(Sid.AverageConsumption, intervalMs: 2000)
        addField_(Sid.WorstAverageConsumption, intervalMs: 8000)
        addField_(Sid.BestAverageConsumption, intervalMs: 8000)

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
                case Sid.RangeEstimate:
                    self.distance = val!
                    self.carRange.text = String(format: "%.1f", self.distance)
                    self.text_DistanceEnergy1.text = String(format: "%.1f", val!)
                case Sid.AvailableEnergy:
                    self.energy = val!
                    self.range = self.energy / self.consumption * 100
                    self.rangeWorst = self.energy / self.consumptionWorst * 100
                    self.rangeBest = self.energy / self.consumptionBest * 100
                    self.updateRange()
                    self.text_DistanceEnergy2.text = String(format: "%.1f", val!)
                case Sid.AverageConsumption:
                    self.consumption = val!
                    self.range = self.energy / self.consumption * 100
                    self.updateRange()
                case Sid.WorstAverageConsumption:
                    self.consumptionWorst = val!
                    self.rangeWorst = self.energy / self.consumptionWorst * 100
                    self.updateRange()
                case Sid.BestAverageConsumption:
                    self.consumptionBest = val!
                    self.rangeBest = self.energy / self.consumptionBest * 100
                    self.updateRange()
                default:
                    print("unknown sid \(sid!)")
                }
            }
        }
    }

    func initChart() {
        distanceEnergyChartView.legend.enabled = false

        let xAxis = distanceEnergyChartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelFont = UIFont.systemFont(ofSize: 8.0)
        xAxis.labelTextColor = .black
        xAxis.drawAxisLineEnabled = true
        xAxis.drawGridLinesEnabled = false
        xAxis.valueFormatter = TimestampAxis()
        // xAxis.labelRotationAngle = -45.0

        let yAxis = distanceEnergyChartView.leftAxis
        yAxis.axisMinimum = 0
        yAxis.axisMaximum = 180

        distanceEnergyLine1 = LineChartDataSet(entries: distanceEnergyEntries1, label: nil)
        distanceEnergyLine1.colors = [.red]
        distanceEnergyLine1.drawCirclesEnabled = false
        distanceEnergyLine1.drawValuesEnabled = false

        let yAxisRight = distanceEnergyChartView.rightAxis
        yAxisRight.axisMinimum = 0
        yAxisRight.axisMaximum = 30

        distanceEnergyLine2 = LineChartDataSet(entries: distanceEnergyEntries2, label: nil)
        distanceEnergyLine2.axisDependency = .right
        distanceEnergyLine2.colors = [.blue]
        distanceEnergyLine2.drawCirclesEnabled = false
        distanceEnergyLine2.drawValuesEnabled = false

        distanceEnergyChartView.data = LineChartData(dataSets: [distanceEnergyLine1, distanceEnergyLine2])
    }

    func updateChart() {
        distanceEnergyLine1.replaceEntries(distanceEnergyEntries1)
        distanceEnergyLine2.replaceEntries(distanceEnergyEntries2)
        distanceEnergyChartView.data = LineChartData(dataSets: [distanceEnergyLine1, distanceEnergyLine2])
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

    @IBAction func sliderValue() {
        updateSeekBar()
        // save value
        ud.setValue(slider.value * 100, forKey: "loss")
        ud.synchronize()
    }

    func updateSeekBar() {
        let progressPosition = Double(slider.value)
        loss = (progressPosition - 50.0)
        lossView.text = String(format: "%.0f%%", progressPosition - 50.0)
        updateRange()
    }

    func updateRange() {
        canzeRange.text = String(format: "%.1f - %.1f - %.1f", rangeWorst, range * (1 - loss), rangeBest)
        /*
         ((TextView) findViewById(R.id.canzeRange)).setText(
         (Math.floor(rangeWorst*100))/100. +" > "+
         (Math.floor(range*100*(1-loss)))/100.+" > "+
         (Math.floor(rangeBest*100))/100.
         ); */
    }
}
