//
//  HomeViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 17/12/20.
//

import Toast_Swift
import UIKit

class HomeViewController: CanZeViewController {
    @IBOutlet var btnConsumption: ButtonWithImage!
    @IBOutlet var btnBattery: ButtonWithImage!
    @IBOutlet var btnClimate: ButtonWithImage!
    @IBOutlet var btnCharging: ButtonWithImage!
    @IBOutlet var btnDriving: ButtonWithImage!
    @IBOutlet var btnBraking: ButtonWithImage!
    @IBOutlet var btnAvgSpeed: ButtonWithImage!
    @IBOutlet var lblNews: UILabel!

    var firstRun = true
    var msg = ""
    var isHtml = false

//    var last = "button_bluetooth_connected"

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        navigationController?.navigationBar.barTintColor = UIColor(white: 0.95, alpha: 1)

//         if navigationItem.rightBarButtonItems != nil && navigationItem.rightBarButtonItems!.count > 1 {
//             for b in navigationItem.rightBarButtonItems! {
//                b.tintColor = .orange
//             }
//         } else if navigationItem.rightBarButtonItem != nil {
//        navigationItem.rightBarButtonItem!.tintColor = .green
//         }

        /*
                 let b = navigationItem.rightBarButtonItems?.last
                 b!.tintColor = .blue

                 Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
                     let b = self.navigationItem.rightBarButtonItems?.last
                     var n = ""
                     if self.last == "button_bluetooth_disconnected" {
                         n = "button_bluetooth_searching_1"
         //                b!.tintColor = .blue
                     } else if self.last == "button_bluetooth_searching_1" {
                         n = "button_bluetooth_searching_2"
         //                b!.tintColor = .blue
                     } else if self.last == "button_bluetooth_searching_2" {
                         n = "button_bluetooth_searching_3"
         //                b!.tintColor = .blue
                     } else {
                         n = "button_bluetooth_disconnected"
         //                b!.tintColor = UIColor(white: 0.0, alpha: 0.4)
         //                b!.tintColor = .blue
                     }
                     self.last = n
                     print(n)
                     b?.image = UIImage(named: n)
                 }
                  */

        // icona
        let v = UIImageView(image: UIImage(named: "CanZEiconSmall.jpg"))
        let item1 = UIBarButtonItem(customView: v)
        // print(item1.customView?.frame)  // 0,0,55.66,55.66  (167x132)

        // nome app
        let label = UILabel()
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 18.0)
        label.text = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        let item2 = UIBarButtonItem(customView: label)

        // mostra su nav bar
        let items = Array(arrayLiteral: item1, item2)
        navigationItem.leftBarButtonItems = items

        btnConsumption.setTitle(NSLocalizedString("button_Consumption", comment: "").uppercased(), for: .normal)
        btnConsumption.setImage(#imageLiteral(resourceName: "button_consumption"), for: .normal)

        btnBattery.setTitle(NSLocalizedString("button_Battery", comment: "").uppercased(), for: .normal)
        btnBattery.setImage(#imageLiteral(resourceName: "button_battery"), for: .normal)

        btnClimate.setTitle(NSLocalizedString("button_Climate", comment: "").uppercased(), for: .normal)
        btnClimate.setImage(#imageLiteral(resourceName: "button_climate"), for: .normal)

        btnCharging.setTitle(NSLocalizedString("button_Charging", comment: "").uppercased(), for: .normal)
        btnCharging.setImage(#imageLiteral(resourceName: "button_charge"), for: .normal)

        btnDriving.setTitle(NSLocalizedString("button_Driving", comment: "").uppercased(), for: .normal)
        btnDriving.setImage(#imageLiteral(resourceName: "button_drive"), for: .normal)

        btnBraking.setTitle(NSLocalizedString("button_Braking", comment: "").uppercased(), for: .normal)
        btnBraking.setImage(#imageLiteral(resourceName: "button_brake"), for: .normal)

        btnAvgSpeed.setTitle(NSLocalizedString("button_speedcontrol", comment: "").uppercased(), for: .normal)
        btnAvgSpeed.setImage(#imageLiteral(resourceName: "button_speedcam"), for: .normal)

        lblNews.text = ""

        getNews()

        loadSettings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !ud.bool(forKey: "disclaimer") {
            performSegue(withIdentifier: "disclaimer", sender: nil)
        } else if deviceIsConnectable() {
            // connect()
        } else {
            view.makeToast(NSLocalizedString("toast_AdjustSettings", comment: ""))
        }
    }

    func getNews() {
        if firstRun {
            var request = URLRequest(url: URL(string: "https://raw.githubusercontent.com/fesch/CanZE/Development/NEWS.json")!, timeoutInterval: 5)
            request.httpMethod = "GET"

            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data else {
                    print(String(describing: error))
                    return
                }
                //              print(String(data: data, encoding: .utf8)!)

                // TODO: app version check ?
                // TODO: news in html format ?

                let decoder = JSONDecoder()
                do {
                    let newsData = try decoder.decode(AnyDecodable.self, from: data).value as! [String: Any]

                    let newsText = newsData["news"] as? String
                    if newsText != nil {
                        if newsText!.contains("<") {
                            self.isHtml = true
                        }
                        DispatchQueue.main.async {
                            if self.isHtml {
                                self.lblNews.attributedText = newsText?.htmlToAttributedString
                            } else {
                                self.lblNews.text = newsText
                            }
                        }
                        self.firstRun = false
                    }

                } catch {
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        self.lblNews.text = "error"
                    }
                }
            }

            task.resume()
        }
    }

    @IBAction func btn(sender: UIButton) {
        if !deviceIsConnectable() {
            view.makeToast(NSLocalizedString("toast_AdjustSettings", comment: ""))
        } else {
            var segueIdentifier = ""

            switch sender {
            case btnConsumption:
//                segueIdentifier = "Consumption"
                break
            case btnBattery:
                segueIdentifier = "Battery"
                break
            case btnClimate:
//                segueIdentifier = "Climate"
                break
            case btnCharging:
                segueIdentifier = "Charging"
            case btnDriving:
//                segueIdentifier = "Driving"
                break
            case btnBraking:
//                segueIdentifier = "Braking"
                break
            case btnAvgSpeed:
//                segueIdentifier = "AvgSpeed"
                break
            default:
                view.makeToast("menu error") // TODO: translation
            }

            if segueIdentifier != "" {
                performSegue(withIdentifier: segueIdentifier, sender: nil)
            } else {
                view.makeToast("not yet implemented")
            }
        }
    }
}
