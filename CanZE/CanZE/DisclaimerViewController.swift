//
//  DisclaimerViewController.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 18/01/21.
//

import UIKit

class DisclaimerViewController: CanZeViewController {

    @IBOutlet var tv : UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.title = Bundle.main.infoDictionary![kCFBundleNameKey as String] as? String
        
        tv.attributedText = NSLocalizedString("prompt_DisclaimerText", comment: "").htmlToAttributedString
        
        ud.setValue(true, forKey: "disclaimer")
        ud.synchronize()
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
