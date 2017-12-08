//
//  DictionaryTransform.swift
//  ObjectMapper
//
//  Created by Grupo GD on 7/20/16.
//

import Foundation

///Transforms [String: AnyObject] <-> [Key: Value] where Key is RawRepresentable as String, Value is Mappable
public struct DictionaryTransform<K, V>: TransformType where K: Hashable, K: RawRepresentable, K.RawValue == String, V: Mappable {
  
  public init() {
    // Intentionally unimplemented...
  }
  
  public func transformFromJSON(_ value: Any?) -> [K: V]? {
    
    guard let json = value as? [String: Any] else {
      
      return nil
    }
    
    let result = json.reduce([:]) { (result, element) -> [K: V] in
      
      guard
        let key = K(rawValue: element.0),
        let valueJSON = element.1 as? [String: Any],
        let value = V(json: valueJSON)
        else {
          
          return result
      }
      
      var result = result
      result[key] = value
      return result
    }
    
    return result
  }
  
  public func transformToJSON(_ value: [K: V]?) -> Any? {
    
    let result = value?.reduce([:]) { (result, element) -> [String: Any] in
      
      let key = element.0.rawValue
      let value = element.1.toJSON()
      
      var result = result
      result[key] = value
      return result
    }
    
    return result
  }
}

