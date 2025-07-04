//
//  Config.swift
//  opencareai
//
//  Created by Shruthi Sathya on 7/3/25.
//


// Config.swift
import Foundation

enum Config {
    static func string(for key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            fatalError("Could not find key '\(key)' in Info.plist")
        }
        return value
    }
}