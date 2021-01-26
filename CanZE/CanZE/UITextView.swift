//
//  UITextView.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import UIKit

extension UITextView {
    func scrollToBottom() {
        DispatchQueue.main.async {
            self.scrollRangeToVisible(NSMakeRange(self.text.count, Int.max))
        }
    }
}
