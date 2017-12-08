//
//  TransformOf.swift
//  ObjectMapper
//
//  Created by Grupo GD on 1/23/15.
//

open class TransformOf<O, J>: TransformType {
  public typealias Object = O
  public typealias JSON = J
  
  private let fromJSON: (J?) -> O?
  private let toJSON: (O?) -> J?
  
  public init(fromJSON: @escaping(J?) -> O?, toJSON: @escaping(O?) -> J?) {
    self.fromJSON = fromJSON
    self.toJSON = toJSON
  }
  
  open func transformFromJSON(_ value: Any?) -> O? {
    return fromJSON(value as? J)
  }
  
  open func transformToJSON(_ value: O?) -> J? {
    return toJSON(value)
  }
}

