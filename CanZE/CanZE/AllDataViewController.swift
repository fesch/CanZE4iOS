//
//  AllDataViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 29/01/21.
//

import UIKit

class AllDataViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    ///

    @IBOutlet var btnSelect_: UIButton!
    @IBOutlet var btnDownload_: UIButton!
    @IBOutlet var tv: UITextView!
    var arrayEcu: [Ecu] = []

    @IBOutlet var pickerView: UIView!
    @IBOutlet var picker: UIPickerView!
    @IBOutlet var btnPickerCancel: UIButton!
    @IBOutlet var btnPickerDone: UIButton!
    var tmpPickerIndex = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_alldata", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        tv.text = ""
        setupPicker()

        btnDownload_.setTitle(NSLocalizedString("button_alldata", comment: "").uppercased(), for: .normal)

        arrayEcu = []
        for ecu in Ecus.getInstance.getAllEcus() {
            if ecu.fromId > 0, ecu.fromId != 0x800, ecu.fromId != 0x801,
               !ecu.aliases.contains("AIRBAG"),
               !ecu.aliases.contains("ESC")
            {
                arrayEcu.append(ecu) // all reachable ECU's plus the Free Fields Computer. We skip the Virtual Fields Computer for now as it requires real fields and thus frames.
            }
        }

        btnSelect_.setTitle(arrayEcu.first?.mnemonic, for: .normal)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        NotificationCenter.default.addObserver(self, selector: #selector(decoded(notification:)), name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(endQueue2), name: Notification.Name("endQueue2"), object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("received2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("endQueue2"), object: nil)

        Frames.getInstance.load(assetName: "")
        Fields.getInstance.load(assetName: "")
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

        // ddField(sid: Sid.ACPilot, intervalMs: 10000)

        startQueue2()
    }

    @objc func endQueue2() {
        //    startQueue()
    }

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let field = Fields.getInstance.fieldsBySid[sid!]
        let val = Globals.shared.fieldResultsString[sid!]

        DispatchQueue.main.async {
            if field!.isString() || field!.isHexString() {
                self.tv.text += "\(sid!),\(field!.name ?? ""),\(val!)\n"
            } else {
//                self.tv.text += "\(sid!),\(field!.name ?? ""),\(val!)\n"
                self.tv.text += "\(sid!),\(field!.name ?? ""),\(field!.getValue())\n"
            }
            self.tv.scrollToBottom()
        }
    }

    @IBAction func btnSelect() {
        queue2 = []
        showPicker()
    }

    @IBAction func btnDownload() {
        if tmpPickerIndex > arrayEcu.count {
            return
        }

        tv.text = ""
        let ecu = arrayEcu[tmpPickerIndex]
        queue2 = []

        Frames.getInstance.load(ecu: ecu)
        Fields.getInstance.load(assetName: ecu.mnemonic + "_Fields.csv")

        /*
         } catch {
         tv.text += NSLocalizedString("message_NoEcuDefinition", comment: "")
         tv.scrollToBottom()
         // Reload the default frame & timings
         Frames.getInstance().load()
         Fields.getInstance().load()
         // Don't care about DTC's and tests
         return
         }
          */

        for frame in Frames.getInstance.getAllFrames() {
            if frame.responseId != nil, !frame.responseId.starts(with: "5") { // ship dtc commands and mode controls
//                          testerKeepalive(ecu); // may need to set a keepalive/session
                if frame.containingFrame != nil || ecu.fromId == 0x801 { // only use subframes and free frames
                    // query the Frame
                    for field in frame.getAllFields() {
                        addField(field.sid, intervalMs: 99999)
                    }
                }
            }
        }
        startQueue()
    }

    func setupPicker() {
        pickerView.center = view.center
        pickerView.alpha = 0.0
        picker.delegate = self
        btnPickerDone.backgroundColor = .lightGray
        btnPickerCancel.backgroundColor = .lightGray
    }

    func showPicker() {
        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        vBG.tag = vBG_TAG
        view.insertSubview(vBG, belowSubview: pickerView)

        pickerView.alpha = 1.0
        picker.reloadAllComponents()
    }

    func hidePicker() {
        pickerView.alpha = 0.0
        let vBG = view.viewWithTag(vBG_TAG)
        vBG?.removeFromSuperview()
    }

    @IBAction func btnPickerDone_() {
        hidePicker()
        if tmpPickerIndex > arrayEcu.count {
            return
        }
        let ecu = arrayEcu[tmpPickerIndex]
        btnSelect_.setTitle(ecu.mnemonic, for: .normal)
    }

    @IBAction func btnPickerCancel_() {
        hidePicker()
    }
}

extension AllDataViewController: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        tmpPickerIndex = row
    }
}

// MARK: UIPickerViewDataSource

extension AllDataViewController: UIPickerViewDataSource {
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return arrayEcu.count
    }

    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    public func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let ecu = arrayEcu[row]
        return ecu.mnemonic
    }
}
