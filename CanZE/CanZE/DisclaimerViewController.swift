//
//  DisclaimerViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 18/01/21.
//

import UIKit

class DisclaimerViewController: CanZeViewController {
    @IBOutlet var tv: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        
        tv.attributedText = NSLocalizedString_("prompt_DisclaimerText", comment: "").htmlToAttributedString
        
        Globals.shared.ud.setValue(true, forKey: "disclaimer")
        Globals.shared.ud.synchronize()
    }
}
