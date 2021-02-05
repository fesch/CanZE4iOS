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
    @IBOutlet var lblResult: UILabel!
    @IBOutlet var lblHeader: UILabel!
    @IBOutlet var tableV: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        title = NSLocalizedString("title_activity_firmware", comment: "")
        lblDebug.text = ""
        NotificationCenter.default.addObserver(self, selector: #selector(updateDebugLabel(notification:)), name: Notification.Name("updateDebugLabel"), object: nil)

        ///

        lblHeader.attributedText = NSLocalizedString("help_Ecus", comment: "").htmlToAttributedString
        lblResult.text = ""

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

    @objc func endQueue2() {}

    @objc func decoded(notification: Notification) {
        let obj = notification.object as! [String: String]
        let sid = obj["sid"]

        let field = Fields.getInstance.fieldsBySid[sid!]
        if field != nil {
            DispatchQueue.main.async {
                if field?.value == Double.nan || field?.value == nil, field?.strVal == nil || field?.strVal == "" {
                    if self.lblResult.text!.count > 0 {
                        self.lblResult.text? += "\n"
                    }
                    self.lblResult.text! += "\(field!.frame.sendingEcu.mnemonic ?? ""),\(field!.name.replacingOccurrences(of: " (string!)", with: "")):"
                } else {
                    if field!.to - field!.from < 8 {
                        if self.lblResult.text!.count > 0 {
                            self.lblResult.text? += "\n"
                        }
                        self.lblResult.text! += "\(field!.frame.sendingEcu.mnemonic ?? ""),\(field!.name.replacingOccurrences(of: " (string!)", with: "")):\(String(format: "%02X", Int(field!.value)))"
                    } else {
                        if field?.strVal != nil, field?.strVal != "" {
                            if self.lblResult.text!.count > 0 {
                                self.lblResult.text? += "\n"
                            }
                            self.lblResult.text! += "\(field!.frame.sendingEcu.mnemonic ?? ""),\(field!.name.replacingOccurrences(of: " (string!)", with: "")):\(field?.strVal ?? "")"
                        } else {
                            if self.lblResult.text!.count > 0 {
                                self.lblResult.text? += "\n"
                            }
                            self.lblResult.text! += "\(field!.frame.sendingEcu.mnemonic ?? ""),\(field!.name.replacingOccurrences(of: " (string!)", with: "")):\(String(format: "%04X", Int(field!.value)))"
                        }
                    }
                }
            }
        }
    }

    @IBAction func btnDownload() {
        view.makeToast("not yet implemented")
        // TODO:

        /*
                  queue2 = []
                 Frames.getInstance.load(ecu: ecu)
                 Fields.getInstance.load(assetName: ecu.mnemonic + "_Fields.csv")

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
             }*/
    }

    func download(ecu: Ecu) {
        let i = tableV.indexPathForSelectedRow
        if i == nil {
            return
        }

        let ecu = arrayEcu[i!.row]
        queue2 = []
        lblResult.text = ""

        if Utils.isPh2() {
            // open the gateway, as the poller is stopped
            // queryFrame(frame: getFrame(fromId: 0x18daf1d2, responseId: "5003")!)
        }

        if ecu.sessionRequired {
            // open the ecu, as the poller is stopped
            queryFrame(frame: getFrame(fromId: ecu.fromId, responseId: ecu.startDiag)!)
        }
        // get the info
        processOneEcu(ecu: ecu)
    }

    func queryFrame(frame: Frame) {
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

    func processOneEcu(ecu: Ecu) {
        // query the Frame
        var frame = getFrame(fromId: ecu.fromId, responseId: "6180")
        if frame != nil {
            addFrame(frame: frame!)
        } else {
            // else 2nd approach
            frame = getFrame(fromId: ecu.fromId, responseId: "62f1a0")
            if frame != nil {
                addFrame(frame: frame!)
            }
            frame = getFrame(fromId: ecu.fromId, responseId: "62f18a")
            if frame != nil {
                addFrame(frame: frame!)
            }
            frame = getFrame(fromId: ecu.fromId, responseId: "62f194")
            if frame != nil {
                addFrame(frame: frame!)
            }
            frame = getFrame(fromId: ecu.fromId, responseId: "62f195")
            if frame != nil {
                addFrame(frame: frame!)
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
        download(ecu: ecu)
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
