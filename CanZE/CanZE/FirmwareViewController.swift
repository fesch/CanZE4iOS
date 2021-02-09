//
//  FirmwareViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 29/01/21.
//

import UIKit

class FirmwareViewController: CanZeViewController {
    @IBOutlet var lblDebug: UILabel!

    ///
    var arrayEcu: [Ecu] = []

    @IBOutlet var btnDownload_: UIButton!
    @IBOutlet var lblResult1: UILabel!
    @IBOutlet var lblResult2: UILabel!
    @IBOutlet var lblResult3: UILabel!
    @IBOutlet var lblResult4: UILabel!
    @IBOutlet var lblHeader: UILabel!
    @IBOutlet var tableV: UITableView!

    var multi = false
    var logger = AllFirmwaresLogger()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_firmware", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        lblHeader.attributedText = NSLocalizedString("help_Ecus", comment: "").htmlToAttributedString
        lblResult1.text = ""
        lblResult2.text = ""
        lblResult3.text = ""
        lblResult4.text = ""

        btnDownload_.setTitle(NSLocalizedString("button_WriteCsv", comment: "").uppercased(), for: .normal)

        arrayEcu = []
        for ecu in Ecus.getInstance.getAllEcus() {
            if ecu.fromId > 0, ecu.fromId != 0x800, ecu.fromId != 0x801,
               !ecu.aliases.contains("AIRBAG"),
               !ecu.aliases.contains("ESC")
            {
                arrayEcu.append(ecu) // all reachable ECU's plus the Free Fields Computer. We skip the Virtual Fields Computer for now as it requires real fields and thus frames.
            }
        }

        tableV.delegate = self
        tableV.dataSource = self
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

        startQueue2()
    }

    @objc func endQueue2() { if multi == true {
        if let v = view.viewWithTag(vBG_TAG) {
            v.removeFromSuperview()
        }
        view.makeToast("_end")

    }}

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        if let field = Fields.getInstance.fieldsBySid[sid!] {
            DispatchQueue.main.async {
                let fieldName = field.name.replacingOccurrences(of: " (string!)", with: "")
                var s = "\(field.frame.sendingEcu.mnemonic ?? ""),\(fieldName):"
                if field.value != Double.nan, field.value != nil, field.strVal == "" {
                    if field.to - field.from < 8 {
                        s.append(String(format: "%02X", Int(field.value)))
                    } else if field.strVal != "" {
                        s.append(field.strVal)
                    } else {
                        s.append(String(format: "%04X", Int(field.value)))
                    }
                }
                if sid!.contains(".6180.56") || sid!.contains(".62f1a0.") {
                    self.lblResult1.text = s
                } else if sid!.contains(".6180.64") || sid!.contains(".62f18a.") {
                    self.lblResult2.text = s
                } else if sid!.contains(".6180.128") || sid!.contains(".62f194.") {
                    self.lblResult3.text = s
                } else if sid!.contains(".6180.144") || sid!.contains(".62f195.") {
                    self.lblResult4.text = s
                }
                if self.multi {
                    self.logger.add(s)
                }
            }
        }
    }

    func downloadSingle(_ ecu: Ecu) {
        let i = tableV.indexPathForSelectedRow
        if i == nil {
            return
        }

        let ecu = arrayEcu[i!.row]
        queue2 = []
        lblResult1.text = ""
        lblResult2.text = ""
        lblResult3.text = ""
        lblResult4.text = ""
        multi = false

        if Utils.isPh2() {
            // open the gateway, as the poller is stopped
            queryFrame(getFrame(fromId: 0x18daf1d2, responseId: "5003")!)
        }

        if ecu.sessionRequired {
            if ecu.fromId > 0, ecu.fromId < 0x800 || ecu.fromId >= 0x900 {
                // open the ecu, as the poller is stopped
                queryFrame(getFrame(fromId: ecu.fromId, responseId: ecu.startDiag)!)
            }
        }
        // get the info
        processOneEcu(ecu)
    }

    class AllFirmwaresLogger {
        var url: URL?
        func add(_ s: String) {
            if url == nil {
                let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL

                let df = DateFormatter()
                df.dateFormat = "YYYY-MM-dd-HH-mm-ss"
                let s = "Firmwares-\(df.string(from: Date())).csv"
                url = dir.appendingPathComponent(s)

                do {
                    try "\(Date())".appendLineToURL(fileURL: url! as URL)
                } catch {
                    print("can't create log file")
                }
            }
            do {
                try s.appendLineToURL(fileURL: url! as URL)
            } catch {
                print("can't write to log file")
            }
        }
    }

    @IBAction func btnDownload() {
        // TODO:

        logger = AllFirmwaresLogger()
        logger.add("ECU, Version Type, Version data")

        if Utils.isPh2() {
            if let frame = getFrame(fromId: 0x18daf1d2, responseId: "5003") { // open the gateway, as the poller is stopped
                queryFrame(frame)
            }
        }

        for ecu in Ecus.getInstance.getAllEcus() {
            // see if we need to stop right now
            if ecu.fromId > 0, ecu.fromId < 0x800 || ecu.fromId >= 0x900 {
                keepAlive()
                if ecu.sessionRequired {
                    if let frame = getFrame(fromId: ecu.fromId, responseId: ecu.startDiag) { // open the ecu, as the poller is stopped
                        queryFrame(frame)
                    }
                }
                processOneEcu(ecu)
            }
        }
        // closeDump()
        // displayProgress(false, R.id.progressBar_cyclic3, R.id.csvFirmware) //
        multi = true

        let vBG = UIView(frame: view.frame)
        vBG.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        vBG.tag = vBG_TAG
        view.addSubview(vBG)

        startQueue2()
    }

    func keepAlive() {
        if !Utils.isPh2() {
            return // quit ticker if no gateway and no session
        }
//           if (Calendar.getInstance().getTimeInMillis() < ticker) return; // then, quit if no timeout
        if Utils.isPh2() {
            // open the gateway
            queryFrame(Frames.getInstance.getById(id: 0x18daf1d2, responseId: "5003")!)
        }
//           ticker = ticker + 3000;
    }

    func queryFrame(_ frame: Frame) {
        addFrame(frame: frame)
    }

    func getFrame(fromId: Int, responseId: String) -> Frame? {
        let frame = Frames.getInstance.getById(id: fromId, responseId: responseId)
        if frame == nil {
//            MainActivity.getInstance().dropDebugMessage(String.format(Locale.getDefault(), "Frame for this ECU %X.%s not found", fromId, responseId));
            return nil
        }
//        MainActivity.getInstance().dropDebugMessage(frame.getFromIdHex() + "." + frame.getResponseId());
        return frame!
    }

    func processOneEcu(_ ecu: Ecu) {
        // query the Frame
        if let frame = getFrame(fromId: ecu.fromId, responseId: "6180") { // all firmware data
            addFrame(frame: frame)
        } else {
            // else 2nd approach
            if let frame = getFrame(fromId: ecu.fromId, responseId: "62f1a0") { // diagnosticVersion
                addFrame(frame: frame)
            }
            if let frame = getFrame(fromId: ecu.fromId, responseId: "62f18a") { // systemSupplierIdentifier
                addFrame(frame: frame)
            }
            if let frame = getFrame(fromId: ecu.fromId, responseId: "62f194") { // systemSupplierECUSoftwareNumber
                addFrame(frame: frame)
            }
            if let frame = getFrame(fromId: ecu.fromId, responseId: "62f195") { // systemSupplierECUSoftwareVersionNumber
                addFrame(frame: frame)
            }
        }
        startQueue2()
    }

    func setSoftwareValue(field: Field, label: String) {
        var toDisplay = ""
        if field.isString() {
            toDisplay = label + ":" + field.strVal
        } else if (field.to - field.from) < 8 {
            toDisplay = label + String(format: ":%02X", Int(field.getValue()))
        } else {
            toDisplay = label + String(format: ":%04X", Int(field.getValue()))
        }

//           if (id == 0) { //log
//               log(toDisplay)
//               return;
//           }

        print(toDisplay)
    }
}

extension FirmwareViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ecu = arrayEcu[indexPath.row]
        downloadSingle(ecu)
    }
}

extension FirmwareViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayEcu.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")! as UITableViewCell
        let ecu = arrayEcu[indexPath.row]
        cell.textLabel!.text = "\(ecu.mnemonic ?? "") (\(ecu.name ?? ""))"
        return cell
    }
}
