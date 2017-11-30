//
//  TransformType.swift
//  ObjectMapper
//
//  Created by Grupo GD on 2/4/15.
//

public protocol TransformType {
	associatedtype Object
	associatedtype JSON

	func transformFromJSON(_ value: Any?) -> Object?
	func transformToJSON(_ value: Object?) -> JSON?
}
