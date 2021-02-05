//
//  ChargingTechViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 27/01/21.
//

import UIKit

class ChargingTechViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    //

    @IBOutlet var sv: UIScrollView!
    @IBOutlet var cv: UIView!

    @IBOutlet var lbl_header_Charging: UILabel!
    @IBOutlet var lbl_label_Plug: UILabel!
    @IBOutlet var lbl_textPlug: UILabel!
    @IBOutlet var lbl_label_max_pilot: UILabel!
    @IBOutlet var lbl_text_max_pilot: UILabel!
    @IBOutlet var lbl_label_AvChPwr: UILabel!
    @IBOutlet var lbl_textAvChPwr: UILabel!
    @IBOutlet var lbl_header_Battery: UILabel!
    @IBOutlet var lbl_label_UserSOC: UILabel!
    @IBOutlet var lbl_textUserSOC: UILabel!
    @IBOutlet var lbl_label_RealSOC: UILabel!
    @IBOutlet var lbl_textRealSOC: UILabel!
    @IBOutlet var lbl_label_max_charge: UILabel!
    @IBOutlet var lbl_text_max_charge: UILabel!
    @IBOutlet var lbl_label_AvEner: UILabel!
    @IBOutlet var lbl_textAvEner: UILabel!
    @IBOutlet var lbl_label_ETF: UILabel!
    @IBOutlet var lbl_textETF: UILabel!
    @IBOutlet var lbl_label_DcPwr: UILabel!
    @IBOutlet var lbl_textDcPwr: UILabel!
    @IBOutlet var lbl_label_Amps: UILabel!
    @IBOutlet var lbl_textAmps: UILabel!
    @IBOutlet var lbl_label_Volt: UILabel!
    @IBOutlet var lbl_textVolt: UILabel!
    @IBOutlet var lbl_label_SOH: UILabel!
    @IBOutlet var lbl_textSOH: UILabel!
    @IBOutlet var lbl_label_HKM: UILabel!
    @IBOutlet var lbl_textHKM: UILabel!
    @IBOutlet var lbl_header_DrivingCh: UILabel!
    @IBOutlet var lbl_label_DISTA: UILabel!
    @IBOutlet var lbl_textKMA: UILabel!
    @IBOutlet var lbl_header_CompTemp: UILabel!
    @IBOutlet var lbl_text_comp_1_temp: UILabel!
    @IBOutlet var lbl_text_comp_2_temp: UILabel!
    @IBOutlet var lbl_text_comp_3_temp: UILabel!
    @IBOutlet var lbl_text_comp_4_temp: UILabel!
    @IBOutlet var lbl_text_comp_5_temp: UILabel!
    @IBOutlet var lbl_text_comp_6_temp: UILabel!
    @IBOutlet var lbl_text_comp_7_temp: UILabel!
    @IBOutlet var lbl_text_comp_8_temp: UILabel!
    @IBOutlet var lbl_text_comp_9_temp: UILabel!
    @IBOutlet var lbl_text_comp_10_temp: UILabel!
    @IBOutlet var lbl_text_comp_11_temp: UILabel!
    @IBOutlet var lbl_text_comp_12_temp: UILabel!
    @IBOutlet var lbl_unit_Celsius: UILabel!
    @IBOutlet var lbl_text_bala_1_temp: UILabel!
    @IBOutlet var lbl_text_bala_2_temp: UILabel!
    @IBOutlet var lbl_text_bala_3_temp: UILabel!
    @IBOutlet var lbl_text_bala_4_temp: UILabel!
    @IBOutlet var lbl_text_bala_5_temp: UILabel!
    @IBOutlet var lbl_text_bala_6_temp: UILabel!
    @IBOutlet var lbl_text_bala_7_temp: UILabel!
    @IBOutlet var lbl_text_bala_8_temp: UILabel!
    @IBOutlet var lbl_text_bala_9_temp: UILabel!
    @IBOutlet var lbl_text_bala_10_temp: UILabel!
    @IBOutlet var lbl_text_bala_11_temp: UILabel!
    @IBOutlet var lbl_text_bala_12_temp: UILabel!
    @IBOutlet var lbl_header_GridParameters: UILabel!
    @IBOutlet var lbl_label_MainsCurrentType: UILabel!
    @IBOutlet var lbl_textMainsCurrentType: UILabel!
    @IBOutlet var lbl_label_phaseCurrent: UILabel!
    @IBOutlet var lbl_textPhase1CurrentRMS: UILabel!
    @IBOutlet var lbl_textPhase2CurrentRMS: UILabel!
    @IBOutlet var lbl_textPhase3CurrentRMS: UILabel!
    @IBOutlet var lbl_label_PhaseVoltage: UILabel!
    @IBOutlet var lbl_textPhaseVoltage1: UILabel!
    @IBOutlet var lbl_textPhaseVoltage2: UILabel!
    @IBOutlet var lbl_textPhaseVoltage3: UILabel!
    @IBOutlet var lbl_label_InterPhaseVoltage: UILabel!
    @IBOutlet var lbl_textInterPhaseVoltage12: UILabel!
    @IBOutlet var lbl_textInterPhaseVoltage23: UILabel!
    @IBOutlet var lbl_textInterPhaseVoltage31: UILabel!
    @IBOutlet var lbl_label_MainsActivePowerConsumed: UILabel!
    @IBOutlet var lbl_textMainsActivePower: UILabel!
    @IBOutlet var lbl_label_GroundResistanceOhm: UILabel!
    @IBOutlet var lbl_textGroundResistance: UILabel!
    @IBOutlet var lbl_label_SupervisorState: UILabel!
    @IBOutlet var lbl_textSupervisorState: UILabel!
    @IBOutlet var lbl_label_CompletionStatus: UILabel!
    @IBOutlet var lbl_textCompletionStatus: UILabel!
    @IBOutlet var lbl_header_EVSEParameters: UILabel!
    @IBOutlet var lbl_EVSEStatus: UILabel!
    @IBOutlet var lbl_textEVSEStatus: UILabel!
    @IBOutlet var lbl_EVSEFailureStatus: UILabel!
    @IBOutlet var lbl_textEVSEFailureStatus: UILabel!
    @IBOutlet var lbl_EVReady: UILabel!
    @IBOutlet var lbl_textEVReady: UILabel!
    @IBOutlet var lbl_CPLCComStatus: UILabel!
    @IBOutlet var lbl_textCPLCComStatus: UILabel!
    @IBOutlet var lbl_EVRequestState: UILabel!
    @IBOutlet var lbl_textEVRequestState: UILabel!
    @IBOutlet var lbl_EVSEState: UILabel!
    @IBOutlet var lbl_textEVSEState: UILabel!
    @IBOutlet var lbl_EVSEMaxPower: UILabel!
    @IBOutlet var lbl_textEVSEMaxPower: UILabel!
    @IBOutlet var lbl_EVSEPowerLimitReached: UILabel!
    @IBOutlet var lbl_textEVSEPowerLimitReached: UILabel!
    @IBOutlet var lbl_EVSEMaxVoltage: UILabel!
    @IBOutlet var lbl_textEVSEMaxVoltage: UILabel!
    @IBOutlet var lbl_EVSEPresentVoltage: UILabel!
    @IBOutlet var lbl_textEVSEPresentVoltage: UILabel!
    @IBOutlet var lbl_EVSEVoltageLimitReached: UILabel!
    @IBOutlet var lbl_textEVSEVoltageLimitReached: UILabel!
    @IBOutlet var lbl_EVSEMaxCurrent: UILabel!
    @IBOutlet var lbl_textEVSEMaxCurrent: UILabel!
    @IBOutlet var lbl_EVSEPresentCurrent: UILabel!
    @IBOutlet var lbl_textEVSEPresentCurrent: UILabel!
    @IBOutlet var lbl_EVSECurrentLimitReached: UILabel!
    @IBOutlet var lbl_textEVSECurrentLimitReached: UILabel!

    let DefaultFormatTemperature = "%3.0f"
    let DefaultFormatBalancing = "%02X"

    var dcVolt = 0.0 // holds the DC voltage, so we can calculate the power when the amps come in
    var pilot = 0.0
    var usoc = 0.0

    let plug_Status = Globals.localizableFromPlist?.value(forKey: "list_PlugStatus") as? [String]
    let mains_Current_Type = Globals.localizableFromPlist?.value(forKey: "list_MainsCurrentType") as? [String]
    let supervisor_State = Utils.isPh2() ? Globals.localizableFromPlist?.value(forKey: "list_SupervisorStatePh2") as? [String] : Globals.localizableFromPlist?.value(forKey: "list_SupervisorState") as? [String]
    let completion_Status = Globals.localizableFromPlist?.value(forKey: "list_CompletionStatus") as? [String]
    let evse_status = Globals.localizableFromPlist?.value(forKey: "list_EVSEStatus") as? [String]
    let evse_failure_status = Globals.localizableFromPlist?.value(forKey: "list_EVSEFailureStatus") as? [String]
    let ev_ready_status = Globals.localizableFromPlist?.value(forKey: "list_EVReady") as? [String]
    let cplc_com_status = Globals.localizableFromPlist?.value(forKey: "list_CPLCComStatus") as? [String]
    let ev_request_state = Globals.localizableFromPlist?.value(forKey: "list_EVRequestState") as? [String]
    let evse_state = Globals.localizableFromPlist?.value(forKey: "list_EVSEState") as? [String]
    let limit_reached = Globals.localizableFromPlist?.value(forKey: "list_EVSELimitReached") as? [String]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_charging", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        lbl_header_Charging.text = NSLocalizedString("header_Charging", comment: "")
        lbl_label_Plug.text = NSLocalizedString("label_Plug", comment: "")
        lbl_textPlug.text = "-"
        lbl_label_max_pilot.text = NSLocalizedString("label_max_pilot", comment: "")
        lbl_text_max_pilot.text = "-"
        lbl_label_AvChPwr.text = NSLocalizedString("label_AvChPwr", comment: "")
        lbl_textAvChPwr.text = "-"
        lbl_header_Battery.text = NSLocalizedString("header_Battery", comment: "")
        lbl_label_UserSOC.text = NSLocalizedString("label_UserSOC", comment: "")
        lbl_textUserSOC.text = "-"
        lbl_label_RealSOC.text = NSLocalizedString("label_RealSOC", comment: "")
        lbl_textRealSOC.text = "-"
        lbl_label_max_charge.text = NSLocalizedString("label_max_charge", comment: "")
        lbl_text_max_charge.text = "-"
        lbl_label_AvEner.text = NSLocalizedString("label_AvEner", comment: "")
        lbl_textAvEner.text = "-"
        lbl_label_ETF.text = NSLocalizedString("label_ETF", comment: "")
        lbl_textETF.text = "-"
        lbl_label_DcPwr.text = NSLocalizedString("label_DcPwr", comment: "")
        lbl_textDcPwr.text = "-"
        lbl_label_Amps.text = NSLocalizedString("label_Amps", comment: "")
        lbl_textAmps.text = "-"
        lbl_label_Volt.text = NSLocalizedString("label_Volt", comment: "")
        lbl_textVolt.text = "-"
        lbl_label_SOH.text = NSLocalizedString("label_SOH", comment: "")
        lbl_textSOH.text = "-"
        lbl_label_HKM.text = NSLocalizedString("label_HKM", comment: "")
        lbl_textHKM.text = "-"
        lbl_header_DrivingCh.text = NSLocalizedString("header_DrivingCh", comment: "")
        lbl_label_DISTA.text = NSLocalizedString("label_DISTA", comment: "")
        lbl_textKMA.text = "-"
        lbl_header_CompTemp.text = NSLocalizedString("header_CompTemp", comment: "")
        lbl_text_comp_1_temp.text = "-"
        lbl_text_comp_2_temp.text = "-"
        lbl_text_comp_3_temp.text = "-"
        lbl_text_comp_4_temp.text = "-"
        lbl_text_comp_5_temp.text = "-"
        lbl_text_comp_6_temp.text = "-"
        lbl_text_comp_7_temp.text = "-"
        lbl_text_comp_8_temp.text = "-"
        lbl_text_comp_9_temp.text = "-"
        lbl_text_comp_10_temp.text = "-"
        lbl_text_comp_11_temp.text = "-"
        lbl_text_comp_12_temp.text = "-"
        lbl_unit_Celsius.text = NSLocalizedString("unit_Celsius", comment: "")
        lbl_text_bala_1_temp.text = "-"
        lbl_text_bala_2_temp.text = "-"
        lbl_text_bala_3_temp.text = "-"
        lbl_text_bala_4_temp.text = "-"
        lbl_text_bala_5_temp.text = "-"
        lbl_text_bala_6_temp.text = "-"
        lbl_text_bala_7_temp.text = "-"
        lbl_text_bala_8_temp.text = "-"
        lbl_text_bala_9_temp.text = "-"
        lbl_text_bala_10_temp.text = "-"
        lbl_text_bala_11_temp.text = "-"
        lbl_text_bala_12_temp.text = "-"
        lbl_header_GridParameters.text = NSLocalizedString("header_GridParameters", comment: "")
        lbl_label_MainsCurrentType.text = NSLocalizedString("label_MainsCurrentType", comment: "")
        lbl_textMainsCurrentType.text = "-"
        lbl_label_phaseCurrent.text = NSLocalizedString("label_phaseCurrent", comment: "")
        lbl_textPhase1CurrentRMS.text = "-"
        lbl_textPhase2CurrentRMS.text = "-"
        lbl_textPhase3CurrentRMS.text = "-"
        lbl_label_PhaseVoltage.text = NSLocalizedString("label_PhaseVoltage", comment: "")
        lbl_textPhaseVoltage1.text = "-"
        lbl_textPhaseVoltage2.text = "-"
        lbl_textPhaseVoltage3.text = "-"
        lbl_label_InterPhaseVoltage.text = NSLocalizedString("label_InterPhaseVoltage", comment: "")
        lbl_textInterPhaseVoltage12.text = "-"
        lbl_textInterPhaseVoltage23.text = "-"
        lbl_textInterPhaseVoltage31.text = "-"
        lbl_label_MainsActivePowerConsumed.text = NSLocalizedString("label_MainsActivePowerConsumed", comment: "")
        lbl_textMainsActivePower.text = "-"
        lbl_label_GroundResistanceOhm.text = NSLocalizedString("label_GroundResistanceOhm", comment: "")
        lbl_textGroundResistance.text = "-"
        lbl_label_SupervisorState.text = NSLocalizedString("label_SupervisorState", comment: "")
        lbl_textSupervisorState.text = "-"
        lbl_label_CompletionStatus.text = NSLocalizedString("label_CompletionStatus", comment: "")
        lbl_textCompletionStatus.text = "-"
        lbl_header_EVSEParameters.text = NSLocalizedString("header_EVSEParameters", comment: "")
        lbl_EVSEStatus.text = NSLocalizedString("EVSEStatus", comment: "")
        lbl_textEVSEStatus.text = "-"
        lbl_EVSEFailureStatus.text = NSLocalizedString("EVSEFailureStatus", comment: "")
        lbl_textEVSEFailureStatus.text = "-"
        lbl_EVReady.text = NSLocalizedString("EVReady", comment: "")
        lbl_textEVReady.text = "-"
        lbl_CPLCComStatus.text = NSLocalizedString("CPLCComStatus", comment: "")
        lbl_textCPLCComStatus.text = "-"
        lbl_EVRequestState.text = NSLocalizedString("EVRequestState", comment: "")
        lbl_textEVRequestState.text = "-"
        lbl_EVSEState.text = NSLocalizedString("EVSEState", comment: "")
        lbl_textEVSEState.text = "-"
        lbl_EVSEMaxPower.text = NSLocalizedString("EVSEMaxPower", comment: "")
        lbl_textEVSEMaxPower.text = "-"
        lbl_EVSEPowerLimitReached.text = NSLocalizedString("EVSEPowerLimitReached", comment: "")
        lbl_textEVSEPowerLimitReached.text = "-"
        lbl_EVSEMaxVoltage.text = NSLocalizedString("EVSEMaxVoltage", comment: "")
        lbl_textEVSEMaxVoltage.text = "-"
        lbl_EVSEPresentVoltage.text = NSLocalizedString("EVSEPresentVoltage", comment: "")
        lbl_textEVSEPresentVoltage.text = "-"
        lbl_EVSEVoltageLimitReached.text = NSLocalizedString("EVSEVoltageLimitReached", comment: "")
        lbl_textEVSEVoltageLimitReached.text = "-"
        lbl_EVSEMaxCurrent.text = NSLocalizedString("EVSEMaxCurrent", comment: "")
        lbl_textEVSEMaxCurrent.text = "-"
        lbl_EVSEPresentCurrent.text = NSLocalizedString("EVSEPresentCurrent", comment: "")
        lbl_textEVSEPresentCurrent.text = "-"
        lbl_EVSECurrentLimitReached.text = NSLocalizedString("EVSECurrentLimitReached", comment: "")
        lbl_textEVSECurrentLimitReached.text = "-"
        if !Utils.isPh2() {
            lbl_header_EVSEParameters.alpha = 0
            lbl_EVSEStatus.alpha = 0
            lbl_textEVSEStatus.alpha = 0
            lbl_EVSEFailureStatus.alpha = 0
            lbl_textEVSEFailureStatus.alpha = 0
            lbl_EVReady.alpha = 0
            lbl_textEVReady.alpha = 0
            lbl_CPLCComStatus.alpha = 0
            lbl_textCPLCComStatus.alpha = 0
            lbl_EVRequestState.alpha = 0
            lbl_textEVRequestState.alpha = 0
            lbl_EVSEState.alpha = 0
            lbl_textEVSEState.alpha = 0
            lbl_EVSEMaxPower.alpha = 0
            lbl_textEVSEMaxPower.alpha = 0
            lbl_EVSEPowerLimitReached.alpha = 0
            lbl_textEVSEPowerLimitReached.alpha = 0
            lbl_EVSEMaxVoltage.alpha = 0
            lbl_textEVSEMaxVoltage.alpha = 0
            lbl_EVSEPresentVoltage.alpha = 0
            lbl_textEVSEPresentVoltage.alpha = 0
            lbl_EVSEVoltageLimitReached.alpha = 0
            lbl_textEVSEVoltageLimitReached.alpha = 0
            lbl_EVSEMaxCurrent.alpha = 0
            lbl_textEVSEMaxCurrent.alpha = 0
            lbl_EVSEPresentCurrent.alpha = 0
            lbl_textEVSEPresentCurrent.alpha = 0
            lbl_EVSECurrentLimitReached.alpha = 0
            lbl_textEVSECurrentLimitReached.alpha = 0
        }
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

    override func viewDidLayoutSubviews() {
        var maxY: CGFloat = 0
        for v in cv.subviews {
            if v.frame.origin.y + v.frame.size.height > maxY, v.alpha > 0 {
                maxY = v.frame.origin.y + v.frame.size.height
            }
        }
        cv.frame.size.height = maxY + 20
        sv.contentSize = cv.frame.size
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

        addField(Sid.BcbTesterInit, intervalMs: 0) // INTERVAL_ONCE)
        addField(Sid.MaxCharge, intervalMs: 5000)
        addField(Sid.ACPilot, intervalMs: 5000)
        addField(Sid.PlugConnected, intervalMs: 5000)
        addField(Sid.UserSoC, intervalMs: 5000)
        addField(Sid.RealSoC, intervalMs: 5000)
        addField(Sid.AvailableChargingPower, intervalMs: 5000)
        addField(Sid.AvailableEnergy, intervalMs: 5000)
        addField(Sid.SOH, intervalMs: 5000) // state of health gives continuous timeouts. This frame is send at a very low rate
        addField(Sid.RangeEstimate, intervalMs: 5000)
        addField(Sid.HvKilometers, intervalMs: 5000)
        addField(Sid.TractionBatteryVoltage, intervalMs: 5000)
        addField(Sid.TractionBatteryCurrent, intervalMs: 5000)

        for i in 0 ... 12 {
            var sid = "\(Sid.Preamble_CompartmentTemperatures)\(32 + i * 24)"
            addField(sid, intervalMs: 5000)
            sid = "\(Sid.Preamble_BalancingBytes)\(16 + i * 8)"
            addField(sid, intervalMs: 5000)
        }

        addField(Sid.BcbTesterAwake, intervalMs: 1500)
        addField(Sid.MainsCurrentType, intervalMs: 0)
        addField(Sid.Phase1currentRMS, intervalMs: 0)
        addField(Sid.Phase2CurrentRMS, intervalMs: 0)
        addField(Sid.Phase3CurrentRMS, intervalMs: 0)
        if !Utils.isPh2() {
            addField(Sid.PhaseVoltage1, intervalMs: 0)
            addField(Sid.PhaseVoltage2, intervalMs: 0)
            addField(Sid.PhaseVoltage3, intervalMs: 0)
        }
        addField(Sid.InterPhaseVoltage12, intervalMs: 0)
        addField(Sid.InterPhaseVoltage23, intervalMs: 0)
        addField(Sid.InterPhaseVoltage31, intervalMs: 0)
        addField(Sid.MainsActivePower, intervalMs: 0)
        addField(Sid.GroundResistance, intervalMs: 0)
        addField(Sid.SupervisorState, intervalMs: 0)
        addField(Sid.CompletionStatus, intervalMs: 0)

        // TODO: Add variable holding information if CCS charging is available for the car
        if Utils.isPh2() {
            addField(Sid.CCSEVSEStatus, intervalMs: 0)
            addField(Sid.CCSFailureStatus, intervalMs: 0)
            addField(Sid.CCSEVReady, intervalMs: 0)
            addField(Sid.CCSCPLCComStatus, intervalMs: 0)
            addField(Sid.CCSEVRequestState, intervalMs: 0)
            addField(Sid.CCSEVSEState, intervalMs: 0)
            addField(Sid.CCSEVSEMaxPower, intervalMs: 0)
            addField(Sid.CCSEVSEPowerLimitReached, intervalMs: 0)
            addField(Sid.CCSEVSEMaxVoltage, intervalMs: 0)
            addField(Sid.CCSEVSEPresentVoltage, intervalMs: 0)
            addField(Sid.CCSEVSEVoltageLimitReaced, intervalMs: 0)
            addField(Sid.CCSEVSEMaxCurrent, intervalMs: 0)
            addField(Sid.CCSEVSEPresentCurrent, intervalMs: 0)
            addField(Sid.CCSEVSECurrentLimitReached, intervalMs: 0)
        }

        if Globals.shared.useIsoTpFields {
            addField(Sid.BcbVersion, intervalMs: 0) // pre 0x0800 versions have a pilot PWM resolution of 1
        }

        startQueue2()
    }

    @objc func endQueue2() {
        startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        DispatchQueue.main.async { [self] in
            switch sid {
            case Sid.MaxCharge:
                self.lbl_text_max_charge.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.ACPilot:
                self.pilot = self.fieldResultsDouble[sid!] ?? Double.nan
                self.lbl_text_max_pilot.text = String(format: "%.0f", self.pilot)
            case Sid.PlugConnected:
                let d = self.fieldResultsDouble[sid!]
                if d != nil, !d!.isNaN {
                    let i = Int(d!)
                    if i < self.plug_Status![i].count {
                        self.lbl_textPlug.text = self.plug_Status?[i]
                    }
                } else {
                    self.lbl_textPlug.text = self.plug_Status?[0]
                }
            case Sid.UserSoC:
                self.usoc = self.fieldResultsDouble[sid!] ?? Double.nan
                self.lbl_textUserSOC.text = String(format: "%.2f", self.usoc)
            case Sid.RealSoC:
                self.lbl_textRealSOC.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.AvailableChargingPower:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if val! > 45 {
                        self.lbl_textAvChPwr.text = "-"
                    } else {
                        self.lbl_textAvChPwr.text = String(format: "%.2f", val!)
                    }
                }
            case Sid.AvailableEnergy:
                if usoc > 0 {
                    var val = self.fieldResultsDouble[sid!]
                    if val != nil {
                        val = val! * (1 - usoc) / usoc
                        self.lbl_textETF.text = String(format: "%.2f", val!)
                    }
                }
                self.lbl_textAvEner.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.SOH: // state of health gives continuous timeouts. This frame is send at a very low rate
                self.lbl_textSOH.text = String(format: "%.0f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.RangeEstimate:
                let val = self.fieldResultsDouble[sid!]
                if val != nil, val! >= 1023 {
                    self.lbl_textKMA.text = "---"
                } else {
                    self.lbl_textKMA.text = String(format: "%.0f", val!)
                }
            case Sid.HvKilometers:
                self.lbl_textHKM.text = String(format: "%.0f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.TractionBatteryVoltage:
                self.dcVolt = self.fieldResultsDouble[sid!] ?? Double.nan
                self.lbl_textVolt.text = String(format: "%.2f", self.dcVolt)
            case Sid.TractionBatteryCurrent:
                let current = self.fieldResultsDouble[sid!] ?? Double.nan
                if current != Double.nan {
                    let dcPwr = self.dcVolt * current / 1000.0
                    self.lbl_textDcPwr.text = String(format: "%.1f", dcPwr)
                    self.lbl_textAmps.text = String(format: "%.2f", current)
                }
            case Sid.Preamble_CompartmentTemperatures + "32":
                self.lbl_text_comp_1_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "56":
                self.lbl_text_comp_2_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "80":
                self.lbl_text_comp_3_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "104":
                self.lbl_text_comp_4_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "128":
                self.lbl_text_comp_5_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "152":
                self.lbl_text_comp_6_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "176":
                self.lbl_text_comp_7_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "200":
                self.lbl_text_comp_8_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "224":
                self.lbl_text_comp_9_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "248":
                self.lbl_text_comp_10_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "272":
                self.lbl_text_comp_11_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_CompartmentTemperatures + "296":
                self.lbl_text_comp_12_temp.text = String(format: self.DefaultFormatTemperature, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "16":
                self.lbl_text_bala_1_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "24":
                self.lbl_text_bala_2_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "32":
                self.lbl_text_bala_3_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "40":
                self.lbl_text_bala_4_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "48":
                self.lbl_text_bala_5_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "56":
                self.lbl_text_bala_6_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "64":
                self.lbl_text_bala_7_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "72":
                self.lbl_text_bala_8_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "80":
                self.lbl_text_bala_9_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "88":
                self.lbl_text_bala_10_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "96":
                self.lbl_text_bala_11_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Preamble_BalancingBytes + "104":
                self.lbl_text_bala_12_temp.text = String(format: self.DefaultFormatBalancing, (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.MainsCurrentType:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    let i = Int(val!)
                    if i < self.mains_Current_Type!.count {
                        self.lbl_textMainsCurrentType.text = self.mains_Current_Type?[i]
                    }
                }
            case Sid.Phase1currentRMS:
                self.lbl_textPhase1CurrentRMS.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Phase2CurrentRMS:
                self.lbl_textPhase2CurrentRMS.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.Phase3CurrentRMS:
                self.lbl_textPhase3CurrentRMS.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.PhaseVoltage1:
                self.lbl_textPhaseVoltage1.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.PhaseVoltage2:
                self.lbl_textPhaseVoltage2.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.PhaseVoltage3:
                self.lbl_textPhaseVoltage3.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.InterPhaseVoltage12:
                self.lbl_textInterPhaseVoltage12.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.InterPhaseVoltage23:
                self.lbl_textInterPhaseVoltage23.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.InterPhaseVoltage31:
                self.lbl_textInterPhaseVoltage31.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.MainsActivePower:
                self.lbl_textMainsActivePower.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.GroundResistance:
                self.lbl_textGroundResistance.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)

            case Sid.SupervisorState:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.supervisor_State!.count {
                        self.lbl_textSupervisorState.text = self.supervisor_State![Int(val!)]
                    }
                }
            case Sid.CompletionStatus:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.completion_Status!.count {
                        self.lbl_textCompletionStatus.text = self.completion_Status![Int(val!)]
                    }
                }
            case Sid.CCSEVSEStatus:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.evse_status!.count {
                        self.lbl_textEVSEStatus.text = self.evse_status![Int(val!)]
                    }
                }
            case Sid.CCSFailureStatus:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.evse_failure_status!.count {
                        self.lbl_textEVSEFailureStatus.text = self.evse_failure_status![Int(val!)]
                    }
                }
            case Sid.CCSEVReady:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.ev_ready_status!.count {
                        self.lbl_textEVReady.text = self.ev_ready_status![Int(val!)]
                    }
                }
            case Sid.CCSCPLCComStatus:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.cplc_com_status!.count {
                        self.lbl_textCPLCComStatus.text = self.cplc_com_status![Int(val!)]
                    }
                }
            case Sid.CCSEVRequestState:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.ev_request_state!.count {
                        self.lbl_textEVRequestState.text = self.ev_request_state![Int(val!)]
                    }
                }
            case Sid.CCSEVSEState:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.evse_state!.count {
                        self.lbl_textEVSEState.text = self.evse_state![Int(val!)]
                    }
                }
            case Sid.CCSEVSEMaxPower:
                self.lbl_textEVSEMaxPower.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.CCSEVSEPowerLimitReached:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.limit_reached!.count {
                        self.lbl_textEVSEPowerLimitReached.text = self.limit_reached![Int(val!)]
                    }
                }
            case Sid.CCSEVSEMaxVoltage:
                self.lbl_textEVSEMaxVoltage.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.CCSEVSEPresentVoltage:
                self.lbl_textEVSEPresentVoltage.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.CCSEVSEVoltageLimitReaced:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.limit_reached!.count {
                        self.lbl_textEVSEVoltageLimitReached.text = self.limit_reached![Int(val!)]
                    }
                }
            case Sid.CCSEVSEMaxCurrent:
                self.lbl_textEVSEMaxCurrent.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.CCSEVSEPresentCurrent:
                self.lbl_textEVSEPresentCurrent.text = String(format: "%.2f", (self.fieldResultsDouble[sid!] ?? Double.nan) as Double)
            case Sid.CCSEVSECurrentLimitReached:
                let val = self.fieldResultsDouble[sid!]
                if val != nil {
                    if Int(val!) >= 0, Int(val!) < self.limit_reached!.count {
                        self.lbl_textEVSECurrentLimitReached.text = self.limit_reached![Int(val!)]
                    }
                }
            case Sid.BcbVersion: // pre 0x0800 versions have a pilot PWM resolution of 1
                let field = Fields.getInstance.fieldsBySid[sid!]
                let bcbVersionField = Fields.getInstance.getBySID(Sid.ACPilotDutyCycle)
                if bcbVersionField != nil, field != nil {
                    bcbVersionField?.resolution = Int(field!.getValue()) < 0x0800 ? 1.0 : 0.5
                }
            default:
                print("?")
            }
        }
    }
}
