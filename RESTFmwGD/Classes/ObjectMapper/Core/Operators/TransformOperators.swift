//
//  TransformOperators.swift
//  ObjectMapper
//
//  Created by Grupo GD on 2016-09-26.
//

import Foundation

// MARK:- Transforms

/// Object of Basic type with Transform
public func <- <T: TransformType>(left: inout T.Object, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let value = transform.transformFromJSON(map.currentValue)
    FromJSON.basicType(&left, object: value)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: T.Object, right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let value: T.JSON? = transform.transformToJSON(left)
    ToJSON.optionalBasicType(value, map: map)
  }
}


/// Optional object of basic type with Transform
public func <- <T: TransformType>(left: inout T.Object?, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let value = transform.transformFromJSON(map.currentValue)
    FromJSON.optionalBasicType(&left, object: value)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: T.Object?, right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let value: T.JSON? = transform.transformToJSON(left)
    ToJSON.optionalBasicType(value, map: map)
  }
}


/// Implicitly unwrapped optional object of basic type with Transform
public func <- <T: TransformType>(left: inout T.Object!, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let value = transform.transformFromJSON(map.currentValue)
    FromJSON.optionalBasicType(&left, object: value)
  case .toJSON:
    left >>> right
  default: ()
  }
}

/// Array of Basic type with Transform
public func <- <T: TransformType>(left: inout [T.Object], right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let values = fromJSONArrayWithTransform(map.currentValue, transform: transform)
    FromJSON.basicType(&left, object: values)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: [T.Object], right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == .toJSON{
    let values = toJSONArrayWithTransform(left, transform: transform)
    ToJSON.optionalBasicType(values, map: map)
  }
}


/// Optional array of Basic type with Transform
public func <- <T: TransformType>(left: inout [T.Object]?, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let values = fromJSONArrayWithTransform(map.currentValue, transform: transform)
    FromJSON.optionalBasicType(&left, object: values)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: [T.Object]?, right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let values = toJSONArrayWithTransform(left, transform: transform)
    ToJSON.optionalBasicType(values, map: map)
  }
}


/// Implicitly unwrapped optional array of Basic type with Transform
public func <- <T: TransformType>(left: inout [T.Object]!, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let values = fromJSONArrayWithTransform(map.currentValue, transform: transform)
    FromJSON.optionalBasicType(&left, object: values)
  case .toJSON:
    left >>> right
  default: ()
  }
}

/// Dictionary of Basic type with Transform
public func <- <T: TransformType>(left: inout [String: T.Object], right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let values = fromJSONDictionaryWithTransform(map.currentValue, transform: transform)
    FromJSON.basicType(&left, object: values)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: [String: T.Object], right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == . toJSON {
    let values = toJSONDictionaryWithTransform(left, transform: transform)
    ToJSON.optionalBasicType(values, map: map)
  }
}


/// Optional dictionary of Basic type with Transform
public func <- <T: TransformType>(left: inout [String: T.Object]?, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let values = fromJSONDictionaryWithTransform(map.currentValue, transform: transform)
    FromJSON.optionalBasicType(&left, object: values)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: [String: T.Object]?, right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let values = toJSONDictionaryWithTransform(left, transform: transform)
    ToJSON.optionalBasicType(values, map: map)
  }
}


/// Implicitly unwrapped optional dictionary of Basic type with Transform
public func <- <T: TransformType>(left: inout [String: T.Object]!, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let values = fromJSONDictionaryWithTransform(map.currentValue, transform: transform)
    FromJSON.optionalBasicType(&left, object: values)
  case .toJSON:
    left >>> right
  default: ()
  }
}

// MARK:- Transforms of Mappable Objects - <T: BaseMappable>

/// Object conforming to Mappable that have transforms
public func <- <T: TransformType>(left: inout T.Object, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let value: T.Object? = transform.transformFromJSON(map.currentValue)
    FromJSON.basicType(&left, object: value)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: T.Object, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let value: T.JSON? = transform.transformToJSON(left)
    ToJSON.optionalBasicType(value, map: map)
  }
}


/// Optional Mappable objects that have transforms
public func <- <T: TransformType>(left: inout T.Object?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let value: T.Object? = transform.transformFromJSON(map.currentValue)
    FromJSON.optionalBasicType(&left, object: value)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: T.Object?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON{
    let value: T.JSON? = transform.transformToJSON(left)
    ToJSON.optionalBasicType(value, map: map)
  }
}


/// Implicitly unwrapped optional Mappable objects that have transforms
public func <- <T: TransformType>(left: inout T.Object!, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let value: T.Object? = transform.transformFromJSON(map.currentValue)
    FromJSON.optionalBasicType(&left, object: value)
  case .toJSON:
    left >>> right
  default: ()
  }
}


// MARK:- Dictionary of Mappable objects with a transform - Dictionary<String, T: BaseMappable>

/// Dictionary of Mappable objects <String, T: Mappable> with a transform
public func <- <T: TransformType>(left: inout Dictionary<String, T.Object>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .fromJSON && map.isKeyPresent,
    let object = map.currentValue as? [String: Any] {
    let value = fromJSONDictionaryWithTransform(object as Any?, transform: transform) ?? left
    FromJSON.basicType(&left, object: value)
  } else if map.mappingType == .toJSON {
    left >>> right
  }
}

public func >>> <T: TransformType>(left: Dictionary<String, T.Object>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let value = toJSONDictionaryWithTransform(left, transform: transform)
    ToJSON.basicType(value, map: map)
  }
}


/// Optional Dictionary of Mappable object <String, T: Mappable> with a transform
public func <- <T: TransformType>(left: inout Dictionary<String, T.Object>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .fromJSON && map.isKeyPresent, let object = map.currentValue as? [String : Any]{
    let value = fromJSONDictionaryWithTransform(object as Any?, transform: transform) ?? left
    FromJSON.optionalBasicType(&left, object: value)
  } else if map.mappingType == .toJSON {
    left >>> right
  }
}

public func >>> <T: TransformType>(left: Dictionary<String, T.Object>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let value = toJSONDictionaryWithTransform(left, transform: transform)
    ToJSON.optionalBasicType(value, map: map)
  }
}


/// Implicitly unwrapped Optional Dictionary of Mappable object <String, T: Mappable> with a transform
public func <- <T: TransformType>(left: inout Dictionary<String, T.Object>!, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .fromJSON && map.isKeyPresent, let dictionary = map.currentValue as? [String : Any]{
    let transformedDictionary = fromJSONDictionaryWithTransform(dictionary as Any?, transform: transform) ?? left
    FromJSON.optionalBasicType(&left, object: transformedDictionary)
  } else if map.mappingType == .toJSON {
    left >>> right
  }
}

/// Dictionary of Mappable objects <String, T: Mappable> with a transform
public func <- <T: TransformType>(left: inout Dictionary<String, [T.Object]>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  
  if let dictionary = map.currentValue as? [String : [Any]], map.mappingType == .fromJSON && map.isKeyPresent {
    let transformedDictionary = dictionary.map { (arg: (key: String, values: [Any])) -> (String, [T.Object]) in
      let (key, values) = arg
      if let jsonArray = fromJSONArrayWithTransform(values, transform: transform) {
        return (key, jsonArray)
      }
      if let leftValue = left[key] {
        return (key, leftValue)
      }
      return (key, [])
    }
    
    FromJSON.basicType(&left, object: transformedDictionary)
  } else if map.mappingType == .toJSON {
    left >>> right
  }
}

public func >>> <T: TransformType>(left: Dictionary<String, [T.Object]>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  
  if map.mappingType == .toJSON {
    
    let transformedDictionary = left.map { (arg: (key: String, value: [T.Object])) in
      return (arg.key, toJSONArrayWithTransform(arg.value, transform: transform) ?? [])
    }
    
    ToJSON.basicType(transformedDictionary, map: map)
  }
}

public func >>> <T: TransformType>(left: Dictionary<String, [T.Object]>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  
  if map.mappingType == .toJSON {
    let transformedDictionary = left?.map { (arg: (key: String, values: [T.Object])) in
      return (arg.key, toJSONArrayWithTransform(arg.values, transform: transform) ?? [])
    }
    
    ToJSON.optionalBasicType(transformedDictionary, map: map)
  }
}

/// Optional Dictionary of Mappable object <String, T: Mappable> with a transform
public func <- <T: TransformType>(left: inout Dictionary<String, [T.Object]>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  
  if let dictionary = map.currentValue as? [String : [Any]], map.mappingType == .fromJSON && map.isKeyPresent {
    let transformedDictionary = dictionary.map { (arg: (key: String, values: [Any])) -> (String, [T.Object]) in
      let (key, values) = arg
      if let jsonArray = fromJSONArrayWithTransform(values, transform: transform) {
        return (key, jsonArray)
      }
      if let leftValue = left?[key] {
        return (key, leftValue)
      }
      return (key, [])
    }
    FromJSON.optionalBasicType(&left, object: transformedDictionary)
  } else if map.mappingType == .toJSON {
    left >>> right
  }
}

// MARK:- Array of Mappable objects with transforms - Array<T: BaseMappable>

/// Array of Mappable objects
public func <- <T: TransformType>(left: inout Array<T.Object>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    if let transformedValues = fromJSONArrayWithTransform(map.currentValue, transform: transform) {
      FromJSON.basicType(&left, object: transformedValues)
    }
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: Array<T.Object>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let transformedValues = toJSONArrayWithTransform(left, transform: transform)
    ToJSON.optionalBasicType(transformedValues, map: map)
  }
}


/// Optional array of Mappable objects
public func <- <T: TransformType>(left: inout Array<T.Object>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let transformedValues = fromJSONArrayWithTransform(map.currentValue, transform: transform)
    FromJSON.optionalBasicType(&left, object: transformedValues)
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: Array<T.Object>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let transformedValues = toJSONArrayWithTransform(left, transform: transform)
    ToJSON.optionalBasicType(transformedValues, map: map)
  }
}


/// Implicitly unwrapped Optional array of Mappable objects
public func <- <T: TransformType>(left: inout Array<T.Object>!, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    let transformedValues = fromJSONArrayWithTransform(map.currentValue, transform: transform)
    FromJSON.optionalBasicType(&left, object: transformedValues)
  case .toJSON:
    left >>> right
  default: ()
  }
}

// MARK:- Array of Array of objects - Array<Array<T>>> with transforms

/// Array of Array of objects with transform
public func <- <T: TransformType>(left: inout [[T.Object]], right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .toJSON:
    left >>> right
  case .fromJSON where map.isKeyPresent:
    guard let original2DArray = map.currentValue as? [[Any]] else { break }
    let transformed2DArray = original2DArray.flatMap { values in
      fromJSONArrayWithTransform(values as Any?, transform: transform)
    }
    FromJSON.basicType(&left, object: transformed2DArray)
  default:
    break
  }
}

public func >>> <T: TransformType>(left: [[T.Object]], right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == .toJSON{
    let transformed2DArray = left.flatMap { values in
      toJSONArrayWithTransform(values, transform: transform)
    }
    ToJSON.basicType(transformed2DArray, map: map)
  }
}

/// Optional array of array of objects with transform
public func <- <T: TransformType>(left: inout [[T.Object]]?, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .toJSON:
    left >>> right
  case .fromJSON where map.isKeyPresent:
    guard let original2DArray = map.currentValue as? [[Any]] else { break }
    let transformed2DArray = original2DArray.flatMap { values in
      fromJSONArrayWithTransform(values as Any?, transform: transform)
    }
    FromJSON.optionalBasicType(&left, object: transformed2DArray)
  default:
    break
  }
}

public func >>> <T: TransformType>(left: [[T.Object]]?, right: (Map, T)) {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let transformed2DArray = left?.flatMap { values in
      toJSONArrayWithTransform(values, transform: transform)
    }
    ToJSON.optionalBasicType(transformed2DArray, map: map)
  }
}


/// Implicitly unwrapped Optional array of array of objects with transform
public func <- <T: TransformType>(left: inout [[T.Object]]!, right: (Map, T)) {
  let (map, transform) = right
  switch map.mappingType {
  case .toJSON:
    left >>> right
  case .fromJSON where map.isKeyPresent:
    guard let original2DArray = map.currentValue as? [[Any]] else { break }
    let transformed2DArray = original2DArray.flatMap { values in
      fromJSONArrayWithTransform(values as Any?, transform: transform)
    }
    FromJSON.optionalBasicType(&left, object: transformed2DArray)
  default:
    break
  }
}

// MARK:- Set of Mappable objects with a transform - Set<T: BaseMappable>

/// Set of Mappable objects with transform
public func <- <T: TransformType>(left: inout Set<T.Object>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    if let transformedValues = fromJSONArrayWithTransform(map.currentValue, transform: transform) {
      FromJSON.basicType(&left, object: Set(transformedValues))
    }
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: Set<T.Object>, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON {
    let transformedValues = toJSONArrayWithTransform(Array(left), transform: transform)
    ToJSON.optionalBasicType(transformedValues, map: map)
  }
}


/// Optional Set of Mappable objects with transform
public func <- <T: TransformType>(left: inout Set<T.Object>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    if let transformedValues = fromJSONArrayWithTransform(map.currentValue, transform: transform) {
      FromJSON.basicType(&left, object: Set(transformedValues))
    }
  case .toJSON:
    left >>> right
  default: ()
  }
}

public func >>> <T: TransformType>(left: Set<T.Object>?, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  if map.mappingType == .toJSON, let values = left {
    let transformedValues = toJSONArrayWithTransform(Array(values), transform: transform)
    ToJSON.optionalBasicType(transformedValues, map: map)
  }
}


/// Implicitly unwrapped Optional set of Mappable objects with transform
public func <- <T: TransformType>(left: inout Set<T.Object>!, right: (Map, T)) where T.Object: BaseMappable {
  let (map, transform) = right
  switch map.mappingType {
  case .fromJSON where map.isKeyPresent:
    if let transformedValues = fromJSONArrayWithTransform(map.currentValue, transform: transform) {
      FromJSON.basicType(&left, object: Set(transformedValues))
    }
  case .toJSON:
    left >>> right
  default: ()
  }
}


private func fromJSONArrayWithTransform<T: TransformType>(_ input: Any?, transform: T) -> [T.Object]? {
  if let values = input as? [Any] {
    return values.flatMap { value in
      return transform.transformFromJSON(value)
    }
  } else {
    return nil
  }
}

private func fromJSONDictionaryWithTransform<T: TransformType>(_ input: Any?, transform: T) -> [String: T.Object]? {
  if let values = input as? [String: Any] {
    return values.filterMap { value in
      return transform.transformFromJSON(value)
    }
  } else {
    return nil
  }
}

private func toJSONArrayWithTransform<T: TransformType>(_ input: [T.Object]?, transform: T) -> [T.JSON]? {
  return input?.flatMap { value in
    return transform.transformToJSON(value)
  }
}

private func toJSONDictionaryWithTransform<T: TransformType>(_ input: [String: T.Object]?, transform: T) -> [String: T.JSON]? {
  return input?.filterMap { value in
    return transform.transformToJSON(value)
  }
}
