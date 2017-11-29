//
//  TransformOf.swift
//  ObjectMapper
//
//  Created by Grupo GD on 1/23/15.
//

open class TransformOf<ObjectType, JSONType>: TransformType {
	public typealias Object = ObjectType
	public typealias JSON = JSONType

	private let fromJSON: (JSONType?) -> ObjectType?
	private let toJSON: (ObjectType?) -> JSONType?

	public init(fromJSON: @escaping(JSONType?) -> ObjectType?, toJSON: @escaping(ObjectType?) -> JSONType?) {
		self.fromJSON = fromJSON
		self.toJSON = toJSON
	}

	open func transformFromJSON(_ value: Any?) -> ObjectType? {
		return fromJSON(value as? JSONType)
	}

	open func transformToJSON(_ value: ObjectType?) -> JSONType? {
		return toJSON(value)
	}
}
