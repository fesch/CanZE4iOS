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

    var logger = AllDataLogger()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString_("title_activity_alldata", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        tv.text = ""
        setupPicker()

        btnDownload_.setTitle(NSLocalizedString_("button_alldata", comment: "").uppercased(), for: .normal)

        arrayEcu = []
        for ecu in Ecus.getInstance.getAllEcus() {
            if ecu.fromId > 0, ecu.fromId != 0x800, ecu.fromId != 0x801,
               !ecu.aliases.contains("AIRBAG"),
               !ecu.aliases.contains("ESC")
            {
                arrayEcu.append(ecu) // all reachable ECU's plus the Free Fields Computer. We skip the Virtual Fields Computer for now as it requires real fields and thus frames.
            }
        }
        arrayEcu.sort { (a: Ecu, b: Ecu) -> Bool in
            a.mnemonic < b.mnemonic
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
        NotificationCenter.default.addObserver(self, selector: #selector(autoInit2), name: Notification.Name("autoInit"), object: nil)

        // btnSelect()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("decoded"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("updateDebugLabel"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("endQueue2"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("autoInit"), object: nil)

        Frames.getInstance.load(assetName: "")
        Fields.getInstance.load(assetName: "")
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

        DispatchQueue.main.async { [self] in
            if field!.isString() || field!.isHexString() {
                let s = "\(sid!),\(field!.name ?? ""),\(field?.strVal ?? "")"
                tv.text += "\(s)\n"
                logger.add(s, ecu: field!.frame.sendingEcu)
            } else if Globals.shared.fieldResultsDouble[sid!] != nil {
                let s = "\(sid!),\(field!.name ?? ""),\(field!.getValue())"
                tv.text += "\(s)\n"
                logger.add(s, ecu: field!.frame.sendingEcu)
            } else {
                let s = "\(sid!),\(field!.name ?? "")"
                tv.text += "\(s)\n"
                logger.add(s, ecu: field!.frame.sendingEcu)
            }
            tv.scrollToBottom()
        }
    }

    @IBAction func btnSelect() {
        Globals.shared.queue2 = []
        Globals.shared.lastId = 0
        showPicker()
    }

    @IBAction func btnDownload() {
        if tmpPickerIndex > arrayEcu.count {
            return
        }

        tv.text = ""
        let ecu = arrayEcu[tmpPickerIndex]
        logger = AllDataLogger()
        Globals.shared.queue2 = []
        Globals.shared.lastId = 0

        Frames.getInstance.load(ecu: ecu)
        Fields.getInstance.load(assetName: ecu.mnemonic + "_Fields.csv")

        /*
         } catch {
         tv.text += NSLocalizedString_("message_NoEcuDefinition", comment: "")
         tv.scrollToBottom()
         // Reload the default frame & timings
         Frames.getInstance().load()
         Fields.getInstance().load()
         // Don't care about DTC's and tests
         return
         }
          */

        for frame in Frames.getInstance.getAllFrames() {
            if frame.responseId != nil, !frame.responseId.hasPrefix("5") { // ship dtc commands and mode controls
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
        pickerView.alpha = 0.0
        picker.delegate = self
        // btnPickerDone.backgroundColor = .lightGray
        // btnPickerCancel.backgroundColor = .lightGray
        btnPickerDone.setTitle(NSLocalizedString_("default_Ok", comment: "").uppercased(), for: .normal)
        btnPickerCancel.setTitle(NSLocalizedString_("default_Cancel", comment: "").lowercased(), for: .normal)
    }

    func showPicker() {
        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        vBG.tag = Globals.K_TAG_vBG
        view.insertSubview(vBG, belowSubview: pickerView)

        pickerView.alpha = 1.0
        picker.reloadAllComponents()
    }

    func hidePicker() {
        pickerView.alpha = 0.0
        let vBG = view.viewWithTag(Globals.K_TAG_vBG)
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

class AllDataLogger {
    var url: URL?
    func add(_ s: String, ecu: Ecu?) {
        if url == nil {
            let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL

            let df = DateFormatter()
            df.dateFormat = "YYYY-MM-dd-HH-mm-ss"
            let s = "\(ecu?.mnemonic ?? "ecu")-\(df.string(from: Date())).txt"
            url = dir.appendingPathComponent(s)

//            do {
//                try "\(Date())".appendLineToURL(fileURL: url! as URL)
//            } catch {
//                print("can't create log file")
//            }
        }
        do {
            try s.appendLineToURL(fileURL: url! as URL)
        } catch {
            print("can't write to log file")
        }
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
