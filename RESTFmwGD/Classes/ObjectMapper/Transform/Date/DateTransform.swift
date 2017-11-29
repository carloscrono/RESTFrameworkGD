//
//  DateTransform.swift
//  ObjectMapper
//
//  Created by Jorge Ochoa on 2016-10-13.
//

import Foundation

open class DateTransform: TransformType {
	public typealias Object = Date
	public typealias JSON = Double

	public init() {}

	open func transformFromJSON(_ value: Any?) -> Date? {
		if let timeInt = value as? Double {
			return Date(timeIntervalSince1970: TimeInterval(timeInt))
		}
		
		if let timeStr = value as? String {
			return Date(timeIntervalSince1970: TimeInterval(atof(timeStr)))
		}
		
		return nil
	}

	open func transformToJSON(_ value: Date?) -> Double? {
		if let date = value {
			return Double(date.timeIntervalSince1970)
		}
		return nil
	}
}
