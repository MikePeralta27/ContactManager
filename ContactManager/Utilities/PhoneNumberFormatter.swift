//
//  PhoneNumberFormatter.swift
//  ContactManager
//
//  Formats raw input into a readable phone number, stripping any non-digit
//  characters so the phone field only ever contains numbers (plus separators).
//

import Foundation

enum PhoneNumberFormatter {
    /// Keeps digits only (max 15, the E.164 limit) and groups them into a
    /// readable phone format.
    static func format(_ raw: String) -> String {
        let digits = Array(raw.filter { $0.isNumber }.prefix(15))
        let n = digits.count

        func slice(_ range: Range<Int>) -> String { String(digits[range]) }

        switch n {
        case 0:
            return ""
        case 1...3:
            return String(digits)
        case 4...6:
            return "(\(slice(0..<3))) \(slice(3..<n))"
        case 7...10:
            return "(\(slice(0..<3))) \(slice(3..<6))-\(slice(6..<n))"
        default: // 11...15 -> treat leading digits as a country code
            let cc = slice(0..<(n - 10))
            let area = slice((n - 10)..<(n - 7))
            let mid = slice((n - 7)..<(n - 4))
            let last = slice((n - 4)..<n)
            return "+\(cc) (\(area)) \(mid)-\(last)"
        }
    }
}
