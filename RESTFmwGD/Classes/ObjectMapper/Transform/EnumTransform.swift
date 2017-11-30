//
//  EnumTransform.swift
//  ObjectMapper
//
//  Created by Grupo GD on 3/20/15.
//

import Foundation

open class EnumTransform<T: RawRepresentable>: TransformType {
	public typealias Object = T
	public typealias JSON = T.RawValue
	
	public init() {}
	
	open func transformFromJSON(_ value: Any?) -> T? {
		if let raw = value as? T.RawValue {
			return T(rawValue: raw)
		}
		return nil
	}
	
	open func transformToJSON(_ value: T?) -> T.RawValue? {
		if let obj = value {
			return obj.rawValue
		}
		return nil
	}
}
