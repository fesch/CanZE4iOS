//
//  LoggerEmulator.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 01/02/21.
//

import Foundation
import UIKit

class LoggerEmulator {
    var url: URL?
    func add(_ s: String) {
        if url == nil {
            let dir: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last! as URL
            url = dir.appendingPathComponent("Emulator \(String(format: "%.0f", Date().timeIntervalSince1970)).log")
            do {
                try "".appendLineToURL(fileURL: url! as URL)
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
