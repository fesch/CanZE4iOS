//
//  String.swift
//  CanZE
//
//  Created by Roberto Sonzogni on 21/01/21.
//

import Foundation

extension String {
    typealias Byte = UInt8
    var hexaToBytes: [Byte] {
        var start = startIndex
        return stride(from: 0, to: count, by: 2).compactMap { _ in // use flatMap for older Swift versions
            let end = index(after: start)
            defer { start = index(after: end) }
            return Byte(self[start ... end], radix: 16)
        }
    }

    var hexaToBytes_: String {
        return compactMap { c -> String? in
            guard let value = Int(String(c), radix: 16) else { return nil }
            let string = String(value, radix: 2)
            return repeatElement("0", count: 4 - string.count) + string
        }.joined()
    }

    var hexaToBinary: String {
        return hexaToBytes.map {
            let binary = String($0, radix: 2)
            return repeatElement("0", count: 8 - binary.count) + binary
        }.joined()
    }

    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return nil }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return nil
        }
    }

    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }

    func index(from: Int) -> Index {
        return index(startIndex, offsetBy: from)
    }

    func subString(from: Int) -> String {
        let fromIndex = index(from: from)
        return String(self[fromIndex...])
    }

    func subString(to: Int) -> String {
        let toIndex = index(from: to)
        return String(self[..<toIndex])
    }

    func subString(with r: Range<Int>) -> String {
        let startIndex = index(from: r.lowerBound)
        let endIndex = index(from: r.upperBound)
        return String(self[startIndex ..< endIndex])
    }

    func subString(from: Int, to: Int) -> String {
        let startIndex = index(from: from)
        let endIndex = index(from: to)
        return String(self[startIndex ..< endIndex])
    }
}
