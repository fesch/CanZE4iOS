//
//  Logger.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 01/02/21.
//

import Foundation
import UIKit

class Logger {
    var url: URL?

    init() {
        if url == nil {
            let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
            url = dir.appendingPathComponent("CanZE \(String(format: "%.0f", Date().timeIntervalSince1970)).log")
            do {
                try "\(Date())".appendLineToURL(fileURL: url! as URL)
            } catch {
                print("can't create log file")
            }
        }
    }

    func add(s: String) {
        do {
            try s.appendLineToURL(fileURL: url! as URL)
        } catch {
            print("can't write to log file")
        }
    }
}
