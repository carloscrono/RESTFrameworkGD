//
//  TransformOf.swift
//  ObjectMapper
//
//  Created by Grupo GD on 8/22/16.
//

import Foundation

open class NSDecimalNumberTransform: TransformType {
    public typealias Object = NSDecimalNumber
    public typealias JSON = String

    public init() {}

    open func transformFromJSON(_ value: Any?) -> NSDecimalNumber? {
        if let string = value as? String {
            return NSDecimalNumber(string: string)
        } else if let number = value as? NSNumber {
            return NSDecimalNumber(decimal: number.decimalValue)
        } else if let double = value as? Double {
            return NSDecimalNumber(floatLiteral: double)
        }
        return nil
    }

    open func transformToJSON(_ value: NSDecimalNumber?) -> String? {
        guard let value = value else { return nil }
        return value.description
    }
}
