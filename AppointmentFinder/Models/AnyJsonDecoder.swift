//
//  AnyJsonDecoder.swift
//  KVR_Swift
//
//  Created by Ege Güler on 01.11.24.
//

import Foundation

struct AnyDecodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intVal = try? container.decode(Int.self) {
            value = intVal
            return
        }
        
        if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
            return
        }
        
        if let stringVal = try? container.decode(String.self) {
            value = stringVal
            return
        }
        
        if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
            return
        }
        
        if let arrayVal = try? container.decode([AnyDecodable].self) {
            value = arrayVal.map { $0.value }
            return
        }
        
        if let dictVal = try? container.decode([String: AnyDecodable].self) {
            var dict: [String: Any] = [:]
            for (key, val) in dictVal {
                dict[key] = val.value
            }
            value = dict
            return
        }
        
        throw NSError(domain: "AnyDecodableError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to decode value"])
    }
}
