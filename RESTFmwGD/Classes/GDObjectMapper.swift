//
//  Extension Request.swift
//  GDObjectMapper
//
//  Created by David Manzano on 2017-04-30.
//

import Foundation

extension DataRequest {
  
  enum ErrorCode: Int {
    case noData = 1
    case dataSerializationFailed = 2
  }
  
  internal static func newError(_ code: ErrorCode, failureReason: String) -> NSError {
    let errorDomain = "com.gdobjectmapper.error"
    
    let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
    let returnError = NSError(domain: errorDomain, code: code.rawValue, userInfo: userInfo)
    
    return returnError
  }
  
  /// Utility function for checking for errors in response
  internal static func checkResponseForError(data: Data?, error: Error?) -> Error? {
    if let error = error {
      return error
    }
    guard let _ = data else {
      let failureReason = "Data could not be serialized. Input data was nil."
      let error = newError(.noData, failureReason: failureReason)
      return error
    }
    return nil
  }
  
  /// Utility function for extracting JSON from response
  internal static func processResponse(request: URLRequest?, response: HTTPURLResponse?, data: Data?, keyPath: String?) -> Any? {
    let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
    let result = jsonResponseSerializer.serializeResponse(request, response, data, nil)
    
    let jsonObject: Any?
    if let keyPath = keyPath , keyPath.isEmpty == false {
      jsonObject = (result.value as AnyObject?)?.value(forKeyPath: keyPath)
    } else {
      jsonObject = result.value
    }
    
    return jsonObject
  }
  
  /// BaseMappable Object Serializer
  public static func objectMapperSerializer<T: BaseMappable>(_ keyPath: String?, mapToObject object: T? = nil, context: MapContext? = nil) -> DataResponseSerializer<T> {
    return DataResponseSerializer { request, response, data, error in
      if let error = checkResponseForError(data: data, error: error){
        return .failure(error)
      }
      
      let jsonObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
      
      if let object = object {
        _ = Mapper<T>(context: context, shouldIncludeNilValues: false).map(jsonObject: jsonObject, toObject: object)
        return .success(object)
      } else if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).map(jsonObject: jsonObject){
        return .success(parsedObject)
      }
      
      let failureReason = "ObjectMapper failed to serialize response."
      let error = newError(.dataSerializationFailed, failureReason: failureReason)
      return .failure(error)
    }
  }
  
  /// ImmutableMappable Array Serializer
  public static func objectMapperImmutableSerializer<T: ImmutableMappable>(_ keyPath: String?, context: MapContext? = nil) -> DataResponseSerializer<T> {
    return DataResponseSerializer { request, response, data, error in
      if let error = checkResponseForError(data: data, error: error){
        return .failure(error)
      }
      
      let jsonObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
      
      if let jsonObject = jsonObject,
        let parsedObject = (try? Mapper<T>(context: context, shouldIncludeNilValues: false).map(jsonObject: jsonObject)){
        return .success(parsedObject)
      }
      
      let failureReason = "ObjectMapper failed to serialize response."
      let error = newError(.dataSerializationFailed, failureReason: failureReason)
      return .failure(error)
    }
  }
  
  /**
   Adds a handler to be called once the request has finished.
   
   - parameter queue:             The queue on which the completion handler is dispatched.
   - parameter keyPath:           The key path where object mapping should be performed
   - parameter object:            An object to perform the mapping on to
   - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
   
   - returns: The request.
   */
  @discardableResult
  public func responseObject<T: BaseMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, mapToObject object: T? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
    return response(queue: queue, responseSerializer: DataRequest.objectMapperSerializer(keyPath, mapToObject: object, context: context), completionHandler: completionHandler)
  }
  
  @discardableResult
  public func responseObject<T: ImmutableMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<T>) -> Void) -> Self {
    return response(queue: queue, responseSerializer: DataRequest.objectMapperImmutableSerializer(keyPath, context: context), completionHandler: completionHandler)
  }
  
  /// BaseMappable Array Serializer
  public static func objectMapperArraySerializer<T: BaseMappable>(_ keyPath: String?, context: MapContext? = nil) -> DataResponseSerializer<[T]> {
    return DataResponseSerializer { request, response, data, error in
      if let error = checkResponseForError(data: data, error: error){
        return .failure(error)
      }
      
      let jsonObject = processResponse(request: request, response: response, data: data, keyPath: keyPath)
      
      if let parsedObject = Mapper<T>(context: context, shouldIncludeNilValues: false).mapArray(jsonObject: jsonObject){
        return .success(parsedObject)
      }
      
      let failureReason = "ObjectMapper failed to serialize response."
      let error = newError(.dataSerializationFailed, failureReason: failureReason)
      return .failure(error)
    }
  }
  
  /// ImmutableMappable Array Serializer
  public static func objectMapperImmutableArraySerializer<T: ImmutableMappable>(_ keyPath: String?, context: MapContext? = nil) -> DataResponseSerializer<[T]> {
    return DataResponseSerializer { request, response, data, error in
      if let error = checkResponseForError(data: data, error: error){
        return .failure(error)
      }
      
      if let jsonObject = processResponse(request: request, response: response, data: data, keyPath: keyPath), let parsedObject = try? Mapper<T>(context: context, shouldIncludeNilValues: false).mapArray(jsonObject: jsonObject){
        
        return .success(parsedObject)
        
      }
      
      let failureReason = "ObjectMapper failed to serialize response."
      let error = newError(.dataSerializationFailed, failureReason: failureReason)
      return .failure(error)
    }
  }
  
  /**
   Adds a handler to be called once the request has finished. T: BaseMappable
   
   - parameter queue: The queue on which the completion handler is dispatched.
   - parameter keyPath: The key path where object mapping should be performed
   - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
   
   - returns: The request.
   */
  @discardableResult
  public func responseArray<T: BaseMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
    return response(queue: queue, responseSerializer: DataRequest.objectMapperArraySerializer(keyPath, context: context), completionHandler: completionHandler)
  }
  
  /**
   Adds a handler to be called once the request has finished. T: ImmutableMappable
   
   - parameter queue: The queue on which the completion handler is dispatched.
   - parameter keyPath: The key path where object mapping should be performed
   - parameter completionHandler: A closure to be executed once the request has finished and the data has been mapped by ObjectMapper.
   
   - returns: The request.
   */
  @discardableResult
  public func responseArray<T: ImmutableMappable>(queue: DispatchQueue? = nil, keyPath: String? = nil, context: MapContext? = nil, completionHandler: @escaping (DataResponse<[T]>) -> Void) -> Self {
    return response(queue: queue, responseSerializer: DataRequest.objectMapperImmutableArraySerializer(keyPath, context: context), completionHandler: completionHandler)
  }
}

