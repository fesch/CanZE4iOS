//
//  UserDefaults.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 23/01/21.
//

import Foundation

// MARK: UserDefaults

extension UserDefaults {
    func exists(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
}
