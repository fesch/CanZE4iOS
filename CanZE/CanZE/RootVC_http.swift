//
//  RootVC_http.swift
//  CanZE
//
//  Created by Roberto on 25/02/2021.
//

import Foundation

extension RootViewController {
    // HTTP
    func writeHttp(s: String) {
        var request = URLRequest(url: URL(string: "\(Globals.shared.deviceHttpAddress)\(s)")!, timeoutInterval: 5)
        request.httpMethod = "GET"

        debug("> \(s)")

        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            if error != nil {
                DispatchQueue.main.async { [self] in
                    view.makeToast(error?.localizedDescription)
                }
                return
            }
            if data == nil {
                self.debug("data == nil")
                return
            }
            if var reply = String(data: data!, encoding: .utf8) {
                let a = reply.components(separatedBy: ",")
                if a.count > 0 {
                    reply = a.last!
                }
                if reply.contains("problem") {
                    reply = "ERROR"
                }

                let dic = ["reply": reply]
                NotificationCenter.default.post(name: Notification.Name("received2"), object: dic)
            }
        }
        task.resume()
    }
}
