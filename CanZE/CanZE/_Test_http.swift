//
//  _Test_http.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 25/02/21.
//

import Foundation

extension _TestViewController {
    // http
    
    func writeHttp(s: String) {
        var request = URLRequest(url: URL(string: "\(Globals.shared.deviceHttpAddress)\(s)")!, timeoutInterval: 5)
        request.httpMethod = "GET"
        
        debug2("> \(s)")
        
        let task = URLSession.shared.dataTask(with: request) { [self] data, _, error in
            guard let data = data else {
                print(String(describing: error))
                debug2(error?.localizedDescription ?? "")
                return
            }
            //            print(data)
            let reply = String(data: data, encoding: .utf8)
            let reply2 = reply?.components(separatedBy: ",")
            if reply2?.count == 2 {
                var reply3 = reply2?.last
                if reply3!.contains("problem") {
                    reply3 = "ERROR"
                }
                let dic = ["reply": reply3]
                NotificationCenter.default.post(name: Notification.Name("received2"), object: dic)
            } else {
                debug2(reply!)
            }
        }
        task.resume()
    }
}
