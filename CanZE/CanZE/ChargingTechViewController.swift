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

    var plug_Status: [String] = []
    var mains_Current_Type: [String] = []
    var supervisor_State: [String] = []
    var completion_Status: [String] = []
    var evse_status: [String] = []
    var evse_failure_status: [String] = []
    var ev_ready_status: [String] = []
    var cplc_com_status: [String] = []
    var ev_request_state: [String] = []
    var evse_state: [String] = []
    var limit_reached: [String] = []

    var doneOneTimeOnly = false

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_charging", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        //

        plug_Status = localizableFromPlist("list_PlugStatus")
        mains_Current_Type = localizableFromPlist("list_MainsCurrentType")
        supervisor_State = Utils.isPh2() ? localizableFromPlist("list_SupervisorStatePh2") : localizableFromPlist("list_SupervisorState")
        completion_Status = localizableFromPlist("list_CompletionStatus")
        evse_status = localizableFromPlist("list_EVSEStatus")
        evse_failure_status = localizableFromPlist("list_EVSEFailureStatus")
        ev_ready_status = localizableFromPlist("list_EVReady")
        cplc_com_status = localizableFromPlist("list_CPLCComStatus")
        ev_request_state = localizableFromPlist("list_EVRequestState")
        evse_state = localizableFromPlist("list_EVSEState")
        limit_reached = localizableFromPlist("list_EVSELimitReached")

        lbl_header_Charging.text = NSLocalizedString_("header_Charging", comment: "")
        lbl_label_Plug.text = NSLocalizedString_("label_Plug", comment: "")
        lbl_textPlug.text = "-"
        lbl_label_max_pilot.text = NSLocalizedString_("label_max_pilot", comment: "")
        lbl_text_max_pilot.text = "-"
        lbl_label_AvChPwr.text = NSLocalizedString_("label_AvChPwr", comment: "")
        lbl_textAvChPwr.text = "-"
        lbl_header_Battery.text = NSLocalizedString_("header_Battery", comment: "")
        lbl_label_UserSOC.text = NSLocalizedString_("label_UserSOC", comment: "")
        lbl_textUserSOC.text = "-"
        lbl_label_RealSOC.text = NSLocalizedString_("label_RealSOC", comment: "")
        lbl_textRealSOC.text = "-"
        lbl_label_max_charge.text = NSLocalizedString_("label_max_charge", comment: "")
        lbl_text_max_charge.text = "-"
        lbl_label_AvEner.text = NSLocalizedString_("label_AvEner", comment: "")
        lbl_textAvEner.text = "-"
        lbl_label_ETF.text = NSLocalizedString_("label_ETF", comment: "")
        lbl_textETF.text = "-"
        lbl_label_DcPwr.text = NSLocalizedString_("label_DcPwr", comment: "")
        lbl_textDcPwr.text = "-"
        lbl_label_Amps.text = NSLocalizedString_("label_Amps", comment: "")
        lbl_textAmps.text = "-"
        lbl_label_Volt.text = NSLocalizedString_("label_Volt", comment: "")
        lbl_textVolt.text = "-"
        lbl_label_SOH.text = NSLocalizedString_("label_SOH", comment: "")
        lbl_textSOH.text = "-"
        lbl_label_HKM.text = NSLocalizedString_("label_HKM", comment: "")
        lbl_textHKM.text = "-"
        lbl_header_DrivingCh.text = NSLocalizedString_("header_DrivingCh", comment: "")
        lbl_label_DISTA.text = NSLocalizedString_("label_DISTA", comment: "")
        lbl_textKMA.text = "-"
        lbl_header_CompTemp.text = NSLocalizedString_("header_CompTemp", comment: "")
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
        lbl_unit_Celsius.text = NSLocalizedString_("unit_Celsius", comment: "")
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
        lbl_header_GridParameters.text = NSLocalizedString_("header_GridParameters", comment: "")
        lbl_label_MainsCurrentType.text = NSLocalizedString_("label_MainsCurrentType", comment: "")
        lbl_textMainsCurrentType.text = "-"
        lbl_label_phaseCurrent.text = NSLocalizedString_("label_phaseCurrent", comment: "")
        lbl_textPhase1CurrentRMS.text = "-"
        lbl_textPhase2CurrentRMS.text = "-"
        lbl_textPhase3CurrentRMS.text = "-"
        lbl_label_PhaseVoltage.text = NSLocalizedString_("label_PhaseVoltage", comment: "")
        lbl_textPhaseVoltage1.text = "-"
        lbl_textPhaseVoltage2.text = "-"
        lbl_textPhaseVoltage3.text = "-"
        lbl_label_InterPhaseVoltage.text = NSLocalizedString_("label_InterPhaseVoltage", comment: "")
        lbl_textInterPhaseVoltage12.text = "-"
        lbl_textInterPhaseVoltage23.text = "-"
        lbl_textInterPhaseVoltage31.text = "-"
        lbl_label_MainsActivePowerConsumed.text = NSLocalizedString_("label_MainsActivePowerConsumed", comment: "")
        lbl_textMainsActivePower.text = "-"
        lbl_label_GroundResistanceOhm.text = NSLocalizedString_("label_GroundResistanceOhm", comment: "")
        lbl_textGroundResistance.text = "-"
        lbl_label_SupervisorState.text = NSLocalizedString_("label_SupervisorState", comment: "")
        lbl_textSupervisorState.text = "-"
        lbl_label_CompletionStatus.text = NSLocalizedString_("label_CompletionStatus", comment: "")
        lbl_textCompletionStatus.text = "-"
        lbl_header_EVSEParameters.text = NSLocalizedString_("header_EVSEParameters", comment: "")
        lbl_EVSEStatus.text = NSLocalizedString_("EVSEStatus", comment: "")
        lbl_textEVSEStatus.text = "-"
        lbl_EVSEFailureStatus.text = NSLocalizedString_("EVSEFailureStatus", comment: "")
        lbl_textEVSEFailureStatus.text = "-"
        lbl_EVReady.text = NSLocalizedString_("EVReady", comment: "")
        lbl_textEVReady.text = "-"
        lbl_CPLCComStatus.text = NSLocalizedString_("CPLCComStatus", comment: "")
        lbl_textCPLCComStatus.text = "-"
        lbl_EVRequestState.text = NSLocalizedString_("EVRequestState", comment: "")
        lbl_textEVRequestState.text = "-"
        lbl_EVSEState.text = NSLocalizedString_("EVSEState", comment: "")
        lbl_textEVSEState.text = "-"
        lbl_EVSEMaxPower.text = NSLocalizedString_("EVSEMaxPower", comment: "")
        lbl_textEVSEMaxPower.text = "-"
        lbl_EVSEPowerLimitReached.text = NSLocalizedString_("EVSEPowerLimitReached", comment: "")
        lbl_textEVSEPowerLimitReached.text = "-"
        lbl_EVSEMaxVoltage.text = NSLocalizedString_("EVSEMaxVoltage", comment: "")
        lbl_textEVSEMaxVoltage.text = "-"
        lbl_EVSEPresentVoltage.text = NSLocalizedString_("EVSEPresentVoltage", comment: "")
        lbl_textEVSEPresentVoltage.text = "-"
        lbl_EVSEVoltageLimitReached.text = NSLocalizedString_("EVSEVoltageLimitReached", comment: "")
        lbl_textEVSEVoltageLimitReached.text = "-"
        lbl_EVSEMaxCurrent.text = NSLocalizedString_("EVSEMaxCurrent", comment: "")
        lbl_textEVSEMaxCurrent.text = "-"
        lbl_EVSEPresentCurrent.text = NSLocalizedString_("EVSEPresentCurrent", comment: "")
        lbl_textEVSEPresentCurrent.text = "-"
        lbl_EVSECurrentLimitReached.text = NSLocalizedString_("EVSECurrentLimitReached", comment: "")
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

            lbl_textPlug.text = plug_Status[0]
        }
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
                view.makeToast(NSLocalizedString_("Device not connected", comment: ""))
            }
            return
        }

        Globals.shared.queue2 = []
        Globals.shared.lastId = 0

        if !doneOneTimeOnly {
            addField_(Sid.BcbTesterInit, intervalMs: 0) // INTERVAL_ONCE)
            doneOneTimeOnly = true
        }
        addField_(Sid.MaxCharge, intervalMs: 5000)
        addField_(Sid.ACPilot, intervalMs: 5000)
        addField_(Sid.PlugConnected, intervalMs: 5000)
        addField_(Sid.UserSoC, intervalMs: 5000)
        addField_(Sid.RealSoC, intervalMs: 5000)
        addField_(Sid.AvailableChargingPower, intervalMs: 5000)
        addField_(Sid.AvailableEnergy, intervalMs: 5000)
        addField_(Sid.SOH, intervalMs: 5000) // state of health gives continuous timeouts. This frame is send at a very low rate
        addField_(Sid.RangeEstimate, intervalMs: 5000)
        addField_(Sid.HvKilometers, intervalMs: 5000)
        addField_(Sid.TractionBatteryVoltage, intervalMs: 5000)
        addField_(Sid.TractionBatteryCurrent, intervalMs: 5000)

        for i in 0 ... 12 {
            var sid = "\(Sid.Preamble_CompartmentTemperatures)\(32 + i * 24)"
            addField_(sid, intervalMs: 5000)
            sid = "\(Sid.Preamble_BalancingBytes)\(16 + i * 8)"
            addField_(sid, intervalMs: 5000)
        }

        addField_(Sid.BcbTesterAwake, intervalMs: 1500)
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

        // TO DO Add variable holding information if CCS charging is available for the car
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
                case Sid.MaxCharge:
                    lbl_text_max_charge.text = String(format: "%.2f", val!)
                case Sid.ACPilot:
                    pilot = val!
                    lbl_text_max_pilot.text = String(format: "%.0f", pilot)
                case Sid.PlugConnected:
                    let i = Int(val!)
                    if i < plug_Status[i].count {
                        lbl_textPlug.text = plug_Status[i]
                    }
                case Sid.UserSoC:
                    usoc = val!
                    lbl_textUserSOC.text = String(format: "%.2f", usoc)
                case Sid.RealSoC:
                    lbl_textRealSOC.text = String(format: "%.2f", val!)
                case Sid.AvailableChargingPower:
                    if val! > 45 {
                        lbl_textAvChPwr.text = "-"
                    } else {
                        lbl_textAvChPwr.text = String(format: "%.2f", val!)
                    }
                case Sid.AvailableEnergy:
                    if usoc > 0 {
                        let val2 = val! * (1 - usoc) / usoc
                        lbl_textETF.text = String(format: "%.2f", val2)
                    }
                    lbl_textAvEner.text = String(format: "%.2f", val!)
                case Sid.SOH: // state of health gives continuous timeouts. This frame is send at a very low rate
                    lbl_textSOH.text = String(format: "%.0f", val!)
                case Sid.RangeEstimate:
                    if val! >= 1023 {
                        lbl_textKMA.text = "---"
                    } else {
                        lbl_textKMA.text = String(format: "%.0f", val!)
                    }
                case Sid.HvKilometers: // EVC_Odometer ?
                    lbl_textHKM.text = String(format: "%.0f", val!)
                case Sid.TractionBatteryVoltage:
                    dcVolt = val!
                    lbl_textVolt.text = String(format: "%.2f", dcVolt)
                case Sid.TractionBatteryCurrent:
                    let current = val!
                    if current != Double.nan {
                        let dcPwr = dcVolt * current / 1000.0
                        lbl_textDcPwr.text = String(format: "%.1f", dcPwr)
                        lbl_textAmps.text = String(format: "%.2f", current)
                    }
                case Sid.Preamble_CompartmentTemperatures + "32":
                    lbl_text_comp_1_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "56":
                    lbl_text_comp_2_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "80":
                    lbl_text_comp_3_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "104":
                    lbl_text_comp_4_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "128":
                    lbl_text_comp_5_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "152":
                    lbl_text_comp_6_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "176":
                    lbl_text_comp_7_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "200":
                    lbl_text_comp_8_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "224":
                    lbl_text_comp_9_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "248":
                    lbl_text_comp_10_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "272":
                    lbl_text_comp_11_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_CompartmentTemperatures + "296":
                    lbl_text_comp_12_temp.text = String(format: DefaultFormatTemperature, val!)
                case Sid.Preamble_BalancingBytes + "16":
                    lbl_text_bala_1_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "24":
                    lbl_text_bala_2_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "32":
                    lbl_text_bala_3_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "40":
                    lbl_text_bala_4_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "48":
                    lbl_text_bala_5_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "56":
                    lbl_text_bala_6_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "64":
                    lbl_text_bala_7_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "72":
                    lbl_text_bala_8_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "80":
                    lbl_text_bala_9_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "88":
                    lbl_text_bala_10_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "96":
                    lbl_text_bala_11_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.Preamble_BalancingBytes + "104":
                    lbl_text_bala_12_temp.text = String(format: DefaultFormatBalancing, val!)
                case Sid.MainsCurrentType:
                    let i = Int(val!)
                    if i < mains_Current_Type.count {
                        lbl_textMainsCurrentType.text = mains_Current_Type[i]
                    }
                case Sid.Phase1currentRMS:
                    lbl_textPhase1CurrentRMS.text = String(format: "%.2f", val!)
                case Sid.Phase2CurrentRMS:
                    lbl_textPhase2CurrentRMS.text = String(format: "%.2f", val!)
                case Sid.Phase3CurrentRMS:
                    lbl_textPhase3CurrentRMS.text = String(format: "%.2f", val!)
                case Sid.PhaseVoltage1:
                    lbl_textPhaseVoltage1.text = String(format: "%.2f", val!)
                case Sid.PhaseVoltage2:
                    lbl_textPhaseVoltage2.text = String(format: "%.2f", val!)
                case Sid.PhaseVoltage3:
                    lbl_textPhaseVoltage3.text = String(format: "%.2f", val!)
                case Sid.InterPhaseVoltage12:
                    lbl_textInterPhaseVoltage12.text = String(format: "%.2f", val!)
                case Sid.InterPhaseVoltage23:
                    lbl_textInterPhaseVoltage23.text = String(format: "%.2f", val!)
                case Sid.InterPhaseVoltage31:
                    lbl_textInterPhaseVoltage31.text = String(format: "%.2f", val!)
                case Sid.MainsActivePower:
                    lbl_textMainsActivePower.text = String(format: "%.2f", val!)
                case Sid.GroundResistance:
                    lbl_textGroundResistance.text = String(format: "%.2f", val!)

                case Sid.SupervisorState:
                    let i = Int(val!)
                    if i >= 0, i < supervisor_State.count {
                        lbl_textSupervisorState.text = supervisor_State[i]
                    }
                case Sid.CompletionStatus:
                    let i = Int(val!)
                    if i >= 0, i < completion_Status.count {
                        lbl_textCompletionStatus.text = completion_Status[i]
                    }
                case Sid.CCSEVSEStatus:
                    let i = Int(val!)
                    if i >= 0, i < evse_status.count {
                        lbl_textEVSEStatus.text = evse_status[i]
                    }
                case Sid.CCSFailureStatus:
                    let i = Int(val!)
                    if i >= 0, i < evse_failure_status.count {
                        lbl_textEVSEFailureStatus.text = evse_failure_status[i]
                    }
                case Sid.CCSEVReady:
                    let i = Int(val!)
                    if i >= 0, i < ev_ready_status.count {
                        lbl_textEVReady.text = ev_ready_status[i]
                    }
                case Sid.CCSCPLCComStatus:
                    let i = Int(val!)
                    if i >= 0, i < cplc_com_status.count {
                        lbl_textCPLCComStatus.text = cplc_com_status[i]
                    }
                case Sid.CCSEVRequestState:
                    let i = Int(val!)
                    if i >= 0, i < ev_request_state.count {
                        lbl_textEVRequestState.text = ev_request_state[i]
                    }
                case Sid.CCSEVSEState:
                    let i = Int(val!)
                    if i >= 0, i < evse_state.count {
                        lbl_textEVSEState.text = evse_state[i]
                    }
                case Sid.CCSEVSEMaxPower:
                    lbl_textEVSEMaxPower.text = String(format: "%.2f", val!)
                case Sid.CCSEVSEPowerLimitReached:
                    let i = Int(val!)
                    if i >= 0, i < limit_reached.count {
                        lbl_textEVSEPowerLimitReached.text = limit_reached[i]
                    }
                case Sid.CCSEVSEMaxVoltage:
                    lbl_textEVSEMaxVoltage.text = String(format: "%.2f", val!)
                case Sid.CCSEVSEPresentVoltage:
                    lbl_textEVSEPresentVoltage.text = String(format: "%.2f", val!)
                case Sid.CCSEVSEVoltageLimitReaced:
                    let i = Int(val!)
                    if i >= 0, i < limit_reached.count {
                        lbl_textEVSEVoltageLimitReached.text = limit_reached[i]
                    }
                case Sid.CCSEVSEMaxCurrent:
                    lbl_textEVSEMaxCurrent.text = String(format: "%.2f", val!)
                case Sid.CCSEVSEPresentCurrent:
                    lbl_textEVSEPresentCurrent.text = String(format: "%.2f", val!)
                case Sid.CCSEVSECurrentLimitReached:
                    let i = Int(val!)
                    if i >= 0, i < limit_reached.count {
                        lbl_textEVSECurrentLimitReached.text = limit_reached[i]
                    }
                case Sid.BcbVersion: // pre 0x0800 versions have a pilot PWM resolution of 1
                    let field = Fields.getInstance.fieldsBySid[sid!]
                    let bcbVersionField = Fields.getInstance.getBySID(Sid.ACPilotDutyCycle)
                    if bcbVersionField != nil, field != nil {
                        bcbVersionField?.resolution = Int(field!.getValue()) < 0x0800 ? 1.0 : 0.5
                    }
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
}
