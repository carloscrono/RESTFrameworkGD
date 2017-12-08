//
//  ImmutableMappble.swift
//  ObjectMapper
//
//  Created by GrupoGD on 23/09/2016.
//

public protocol ImmutableMappable: BaseMappable {
  init(map: Map) throws
}

public extension ImmutableMappable {
  
  /// Implement this method to support object -> JSON transform.
  public func mapping(map: Map) {
    // Intentionally unimplemented...
    print(map)
  }
  
  /// Initializes object from a JSON String
  public init(jsonString: String, context: MapContext? = nil) throws {
    self = (try Mapper(context: context).map(jsonString: jsonString))!
  }
  
  /// Initializes object from a JSON Dictionary
  public init(json: [String: Any], context: MapContext? = nil) throws {
    self = (try Mapper(context: context).map(json: json))!
  }
  
  /// Initializes object from a JSONObject
  public init(jsonObject: Any, context: MapContext? = nil) throws {
    self = (try Mapper(context: context).map(jsonObject: jsonObject))!
  }
  
}

public extension Map {
  
  fileprivate func currentValue(for key: String, nested: Bool? = nil, delimiter: String = ".") -> Any? {
    let isNested = nested ?? key.contains(delimiter)
    return self[key, nested: isNested, delimiter: delimiter].currentValue
  }
  
  // MARK: Basic
  
  /// Returns a value or throws an error.
  public func value<T>(_ key: String, nested: Bool? = nil, delimiter: String = ".", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> T {
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let value = currentValue as? T else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot cast to '\(T.self)'", file: file, function: function, line: line)
    }
    return value
  }
  
  /// Returns a transformed value or throws an error.
  public func value<T: TransformType>(_ key: String, nested: Bool? = nil, delimiter: String = ".", using transform: T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> T.Object {
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let value = transform.transformFromJSON(currentValue) else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot transform to '\(T.Object.self)' using \(transform)", file: file, function: function, line: line)
    }
    return value
  }
  
  /// Returns a RawRepresentable type or throws an error.
  public func value<T: RawRepresentable>(_ key: String, nested: Bool? = nil, delimiter: String = ".", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> T {
    return try self.value(key, nested: nested, delimiter: delimiter, using: EnumTransform(), file: file, function: function, line: line)
  }
  
  /// Returns a `[RawRepresentable]` type or throws an error.
  public func value<T: RawRepresentable>(_ key: String, nested: Bool? = nil, delimiter: String = ".", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> [T] {
    return try self.value(key, nested: nested, delimiter: delimiter, using: EnumTransform(), file: file, function: function, line: line)
  }
  
  // MARK: BaseMappable
  
  /// Returns a `BaseMappable` object or throws an error.
  public func value<T: BaseMappable>(_ key: String, nested: Bool? = nil, delimiter: String = ".", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> T {
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let jsonObject = currentValue else {
      throw MapError(key: key, currentValue: currentValue, reason: "Found unexpected nil value", file: file, function: function, line: line)
    }
    return try Mapper<T>(context: context).mapOrFail(jsonObject: jsonObject)
  }
  
  // MARK: [BaseMappable]
  
  /// Returns a `[BaseMappable]` or throws an error.
  public func value<T: BaseMappable>(_ key: String, nested: Bool? = nil, delimiter: String = ".", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> [T] {
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let jsonArray = currentValue as? [Any] else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot cast to '[Any]'", file: file, function: function, line: line)
    }
    
    return try jsonArray.map { JSONObject -> T in
      return try Mapper<T>(context: context).mapOrFail(jsonObject: JSONObject)
    }
  }
  
  /// Returns a `[BaseMappable]` using transform or throws an error.
  public func value<T: TransformType>(_ key: String, nested: Bool? = nil, delimiter: String = ".", using transform: T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> [T.Object] {
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let jsonArray = currentValue as? [Any] else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot cast to '[Any]'", file: file, function: function, line: line)
    }
    
    return try jsonArray.map { json -> T.Object in
      guard let object = transform.transformFromJSON(json) else {
        throw MapError(key: "\(key)", currentValue: json, reason: "Cannot transform to '\(T.Object.self)' using \(transform)", file: file, function: function, line: line)
      }
      return object
    }
  }
  
  // MARK: [String: BaseMappable]
  
  /// Returns a `[String: BaseMappable]` or throws an error.
  public func value<T: BaseMappable>(_ key: String, nested: Bool? = nil, delimiter: String = ".", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> [String: T] {
    
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let jsonDictionary = currentValue as? [String: Any] else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot cast to '[String: Any]'", file: file, function: function, line: line)
    }
    var value: [String: T] = [:]
    for (key, json) in jsonDictionary {
      value[key] = try Mapper<T>(context: context).mapOrFail(jsonObject: json)
    }
    return value
  }
  
  /// Returns a `[String: BaseMappable]` using transform or throws an error.
  public func value<T: TransformType>(_ key: String, nested: Bool? = nil, delimiter: String = ".", using transform: T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> [String: T.Object] {
    
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let jsonDictionary = currentValue as? [String: Any] else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot cast to '[String: Any]'", file: file, function: function, line: line)
    }
    var value: [String: T.Object] = [:]
    for (key, json) in jsonDictionary {
      guard let object = transform.transformFromJSON(json) else {
        throw MapError(key: key, currentValue: json, reason: "Cannot transform to '\(T.Object.self)' using \(transform)", file: file, function: function, line: line)
      }
      value[key] = object
    }
    return value
  }
  
  // MARK: [[BaseMappable]]
  /// Returns a `[[BaseMappable]]` or throws an error.
  public func value<T: BaseMappable>(_ key: String, nested: Bool? = nil, delimiter: String = ".", file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> [[T]] {
    
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let json2DArray = currentValue as? [[Any]] else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot cast to '[[Any]]'", file: file, function: function, line: line)
    }
    return try json2DArray.map { jsonArray in
      try jsonArray.map { jsonObject -> T in
        return try Mapper<T>(context: context).mapOrFail(jsonObject: jsonObject)
      }
    }
  }
  
  /// Returns a `[[BaseMappable]]` using transform or throws an error.
  public func value<T: TransformType>(_ key: String, nested: Bool? = nil, delimiter: String = ".", using transform: T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) throws -> [[T.Object]] {
    
    let currentValue = self.currentValue(for: key, nested: nested, delimiter: delimiter)
    guard let json2DArray = currentValue as? [[Any]] else {
      throw MapError(key: key, currentValue: currentValue, reason: "Cannot cast to '[[Any]]'",
                     file: file, function: function, line: line)
    }
    
    return try json2DArray.map { jsonArray in
      try jsonArray.map { json -> T.Object in
        guard let object = transform.transformFromJSON(json) else {
          throw MapError(key: "\(key)", currentValue: json, reason: "Cannot transform to '\(T.Object.self)' using \(transform)", file: file, function: function, line: line)
        }
        return object
      }
    }
  }
}

public extension Mapper where N: ImmutableMappable {
  
  public func map(json: [String: Any]) throws -> N {
    return try self.mapOrFail(json: json)
  }
  
  public func map(jsonString: String) throws -> N {
    return try mapOrFail(jsonString: jsonString)
  }
  
  public func map(jsonObject: Any) throws -> N {
    return try mapOrFail(jsonObject: jsonObject)
  }
  
  // MARK: Array mapping functions
  
  public func mapArray(jsonArray: [[String: Any]]) throws -> [N] {
    return try jsonArray.flatMap(mapOrFail)
  }
  
  public func mapArray(jsonString: String) throws -> [N] {
    guard let jsonObject = Mapper.parseJSONString(jsonString: jsonString) else {
      throw MapError(key: nil, currentValue: jsonString, reason: "Cannot convert string into Any'")
    }
    
    return (try mapArray(jsonObject: jsonObject))!
  }
  
  public func mapArray(jsonObject: Any) throws -> [N] {
    guard let jsonArray = jsonObject as? [[String: Any]] else {
      throw MapError(key: nil, currentValue: jsonObject, reason: "Cannot cast to '[[String: Any]]'")
    }
    
    return try mapArray(jsonArray: jsonArray)
  }
  
  // MARK: Dictionary mapping functions
  
  public func mapDictionary(jsonString: String) throws -> [String: N] {
    guard let jsonObject = Mapper.parseJSONString(jsonString: jsonString) else {
      throw MapError(key: nil, currentValue: jsonString, reason: "Cannot convert string into Any'")
    }
    
    return (try mapDictionary(jsonObject: jsonObject))!
  }
  
  public func mapDictionary(jsonObject: Any?) throws -> [String: N] {
    guard let json = jsonObject as? [String: [String: Any]] else {
      throw MapError(key: nil, currentValue: jsonObject, reason: "Cannot cast to '[String: [String: Any]]''")
    }
    
    return (try mapDictionary(json: json))!
  }
  
  public func mapDictionary(json: [String: [String: Any]]) throws -> [String: N] {
    return try json.filterMap(mapOrFail)
  }
  
  // MARK: Dictinoary of arrays mapping functions
  
  public func mapDictionaryOfArrays(jsonObject: Any?) throws -> [String: [N]] {
    guard let json = jsonObject as? [String: [[String: Any]]] else {
      throw MapError(key: nil, currentValue: jsonObject, reason: "Cannot cast to '[String: [String: Any]]''")
    }
    return try mapDictionaryOfArrays(json: json)
  }
  
  public func mapDictionaryOfArrays(json: [String: [[String: Any]]]) throws -> [String: [N]] {
    return try json.filterMap { array -> [N] in
      try mapArray(jsonArray: array)
    }
  }
  
  // MARK: 2 dimentional array mapping functions
  
  public func mapArrayOfArrays(jsonObject: Any?) throws -> [[N]] {
    guard let jsonArray = jsonObject as? [[[String: Any]]] else {
      throw MapError(key: nil, currentValue: jsonObject, reason: "Cannot cast to '[[[String: Any]]]''")
    }
    return try jsonArray.map(mapArray)
  }
  
}

internal extension Mapper {
  
  internal func mapOrFail(json: [String: Any]) throws -> N {
    let map = Map(mappingType: .fromJSON, json: json, context: context, shouldIncludeNilValues: shouldIncludeNilValues)
    
    // Check if object is ImmutableMappable, if so use ImmutableMappable protocol for mapping
    if let klass = N.self as? ImmutableMappable.Type,
      var object = try klass.init(map: map) as? N {
      object.mapping(map: map)
      return object
    }
    
    // If not, map the object the standard way
    guard let value = self.map(json: json) else {
      throw MapError(key: nil, currentValue: json, reason: "Cannot map to '\(N.self)'")
    }
    return value
  }
  
  internal func mapOrFail(jsonString: String) throws -> N {
    guard let json = Mapper.parseJSONStringIntoDictionary(jsonString: jsonString) else {
      throw MapError(key: nil, currentValue: jsonString, reason: "Cannot parse into '[String: Any]'")
    }
    return try mapOrFail(json: json)
  }
  
  internal func mapOrFail(jsonObject: Any) throws -> N {
    guard let json = jsonObject as? [String: Any] else {
      throw MapError(key: nil, currentValue: jsonObject, reason: "Cannot cast to '[String: Any]'")
    }
    return try mapOrFail(json: json)
  }
  
}

