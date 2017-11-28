//
//  ISO8601DateTransform.swift
//  ObjectMapper
//
//  Created by Carlos Martínez on 21 Nov 2016.
//

import Foundation

public extension DateFormatter {
	public convenience init(withFormat format : String, locale : String) {
		self.init()
		self.locale = Locale(identifier: locale)
		dateFormat = format
	}
}

open class ISO8601DateTransform: DateFormatterTransform {
	
	static let reusableISODateFormatter = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ", locale: "en_US_POSIX")

	public init() {
		super.init(dateFormatter: ISO8601DateTransform.reusableISODateFormatter)
	}
}

