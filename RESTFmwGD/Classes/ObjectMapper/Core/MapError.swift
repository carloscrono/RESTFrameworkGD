//
//  MapError.swift
//  ObjectMapper
//
//  Created by Grupo GD on 2016-09-26.
//

import Foundation

public struct MapError: Error {
	public var key: String?
	public var currentValue: Any?
	public var reason: String?
	public var file: StaticString?
	public var function: StaticString?
	public var line: UInt?
	
	public init(key: String?, currentValue: Any?, reason: String?, file: StaticString? = nil, function: StaticString? = nil, line: UInt? = nil) {
		self.key = key
		self.currentValue = currentValue
		self.reason = reason
		self.file = file
		self.function = function
		self.line = line
	}
}

extension MapError: CustomStringConvertible {
	
	private var location: String? {
		guard let file = file, let function = function, let line = line else { return nil }
		let fileName = ((String(describing: file).components(separatedBy: "/").last ?? "").components(separatedBy: ".").first ?? "")
		return "\(fileName).\(function):\(line)"
	}
	
	public var description: String {
		let info: [(String, Any?)] = [
			("- reason", reason),
			("- location", location),
			("- key", key),
			("- currentValue", currentValue),
			]
		let infoString = info.map { "\($0.0): \($0.1 ?? "nil")" }.joined(separator: "\n")
		return "Got an error while mapping.\n\(infoString)"
	}
	
}
