//
//  Response.swift
//

import Foundation

/// Used to store all data associated with an non-serialized response of a data or upload request.
public struct DefaultDataResponse {
  /// The URL request sent to the server.
  public let request: URLRequest?
  
  /// The server's response to the URL request.
  public let response: HTTPURLResponse?
  
  /// The data returned by the server.
  public let data: Data?
  
  /// The error encountered while executing or validating the request.
  public let error: Error?
  
  /// The timeline of the complete lifecycle of the request.
  public let timeline: Timeline
  
  var _metrics: AnyObject?
  
  /// Creates a `DefaultDataResponse` instance from the specified parameters.
  ///
  public init(
    request: URLRequest?,
    response: HTTPURLResponse?,
    data: Data?,
    error: Error?,
    timeline: Timeline = Timeline(),
    metrics: AnyObject? = nil)
  {
    self.request = request
    self.response = response
    self.data = data
    self.error = error
    self.timeline = timeline
  }
}

// MARK: -

/// Used to store all data associated with a serialized response of a data or upload request.
public struct DataResponse<V> {
  /// The URL request sent to the server.
  public let request: URLRequest?
  
  /// The server's response to the URL request.
  public let response: HTTPURLResponse?
  
  /// The data returned by the server.
  public let data: Data?
  
  /// The result of response serialization.
  public let result: Result<V>
  
  /// The timeline of the complete lifecycle of the request.
  public let timeline: Timeline
  
  /// Returns the associated value of the result if it is a success, `nil` otherwise.
  public var value: V? { return result.value }
  
  /// Returns the associated error value if the result if it is a failure, `nil` otherwise.
  public var error: Error? { return result.error }
  
  var _metrics: AnyObject?
  
  /// Creates a `DataResponse` instance with the specified parameters derived from response serialization.
  ///
  /// - returns: The new `DataResponse` instance.
  public init(
    request: URLRequest?,
    response: HTTPURLResponse?,
    data: Data?,
    result: Result<V>,
    timeline: Timeline = Timeline())
  {
    self.request = request
    self.response = response
    self.data = data
    self.result = result
    self.timeline = timeline
  }
}

// MARK: -

extension DataResponse: CustomStringConvertible, CustomDebugStringConvertible {
  /// The textual representation used when written to an output stream, which includes whether the result was a
  /// success or failure.
  public var description: String {
    return result.debugDescription
  }
  
  /// The debug textual representation used when written to an output stream, which includes the URL request, the URL
  /// response, the server data, the response serialization result and the timeline.
  public var debugDescription: String {
    var output: [String] = []
    
    output.append(request != nil ? "[Request]: \(request!.httpMethod ?? "GET") \(request!)" : "[Request]: nil")
    output.append(response != nil ? "[Response]: \(response!)" : "[Response]: nil")
    output.append("[Data]: \(data?.count ?? 0) bytes")
    output.append("[Result]: \(result.debugDescription)")
    output.append("[Timeline]: \(timeline.debugDescription)")
    
    return output.joined(separator: "\n")
  }
}

// MARK: -

extension DataResponse {
  /// Evaluates the specified closure when the result of this `DataResponse` is a success, passing the unwrapped
  /// result value as a parameter.
  ///
  /// - returns: A `DataResponse` whose result wraps the value returned by the given closure. If this instance's
  ///            result is a failure, returns a response wrapping the same failure.
  public func map<T>(_ transform: (V) -> T) -> DataResponse<T> {
    var response = DataResponse<T>(
      request: request,
      response: self.response,
      data: data,
      result: result.map(transform),
      timeline: timeline
    )
    
    response._metrics = _metrics
    
    return response
  }
  
  /// Evaluates the given closure when the result of this `DataResponse` is a success, passing the unwrapped result
  /// value as a parameter.
  ///
  /// - returns: A success or failure `DataResponse` depending on the result of the given closure. If this instance's
  ///            result is a failure, returns the same failure.
  public func flatMap<T>(_ transform: (V) throws -> T) -> DataResponse<T> {
    var response = DataResponse<T>(
      request: request,
      response: self.response,
      data: data,
      result: result.flatMap(transform),
      timeline: timeline
    )
    
    response._metrics = _metrics
    
    return response
  }
}

// MARK: -

/// Used to store all data associated with an non-serialized response of a download request.
public struct DefaultDownloadResponse {
  /// The URL request sent to the server.
  public let request: URLRequest?
  
  /// The server's response to the URL request.
  public let response: HTTPURLResponse?
  
  /// The temporary destination URL of the data returned from the server.
  public let temporaryURL: URL?
  
  /// The final destination URL of the data returned from the server if it was moved.
  public let destinationURL: URL?
  
  /// The resume data generated if the request was cancelled.
  public let resumeData: Data?
  
  /// The error encountered while executing or validating the request.
  public let error: Error?
  
  /// The timeline of the complete lifecycle of the request.
  public let timeline: Timeline
  
  var _metrics: AnyObject?
  
  /// Creates a `DefaultDownloadResponse` instance from the specified parameters.
  ///
  public init(
    request: URLRequest?,
    response: HTTPURLResponse?,
    temporaryURL: URL?,
    destinationURL: URL?,
    resumeData: Data?,
    error: Error?,
    timeline: Timeline = Timeline(),
    metrics: AnyObject? = nil)
  {
    self.request = request
    self.response = response
    self.temporaryURL = temporaryURL
    self.destinationURL = destinationURL
    self.resumeData = resumeData
    self.error = error
    self.timeline = timeline
  }
}

// MARK: -

/// Used to store all data associated with a serialized response of a download request.
public struct DownloadResponse<V> {
  /// The URL request sent to the server.
  public let request: URLRequest?
  
  /// The server's response to the URL request.
  public let response: HTTPURLResponse?
  
  /// The temporary destination URL of the data returned from the server.
  public let temporaryURL: URL?
  
  /// The final destination URL of the data returned from the server if it was moved.
  public let destinationURL: URL?
  
  /// The resume data generated if the request was cancelled.
  public let resumeData: Data?
  
  /// The result of response serialization.
  public let result: Result<V>
  
  /// The timeline of the complete lifecycle of the request.
  public let timeline: Timeline
  
  /// Returns the associated value of the result if it is a success, `nil` otherwise.
  public var value: V? { return result.value }
  
  /// Returns the associated error value if the result if it is a failure, `nil` otherwise.
  public var error: Error? { return result.error }
  
  var _metrics: AnyObject?
  
  /// Creates a `DownloadResponse` instance with the specified parameters derived from response serialization.
  ///
  /// - returns: The new `DownloadResponse` instance.
  public init(
    request: URLRequest?,
    response: HTTPURLResponse?,
    temporaryURL: URL?,
    destinationURL: URL?,
    resumeData: Data?,
    result: Result<V>,
    timeline: Timeline = Timeline())
  {
    self.request = request
    self.response = response
    self.temporaryURL = temporaryURL
    self.destinationURL = destinationURL
    self.resumeData = resumeData
    self.result = result
    self.timeline = timeline
  }
}

// MARK: -

extension DownloadResponse: CustomStringConvertible, CustomDebugStringConvertible {
  /// The textual representation used when written to an output stream, which includes whether the result was a
  /// success or failure.
  public var description: String {
    return result.debugDescription
  }
  
  /// The debug textual representation used when written to an output stream, which includes the URL request, the URL
  /// response, the temporary and destination URLs, the resume data, the response serialization result and the
  /// timeline.
  public var debugDescription: String {
    var output: [String] = []
    
    output.append(request != nil ? "[Request]: \(request!.httpMethod ?? "GET") \(request!)" : "[Request]: nil")
    output.append(response != nil ? "[Response]: \(response!)" : "[Response]: nil")
    output.append("[TemporaryURL]: \(temporaryURL?.path ?? "nil")")
    output.append("[DestinationURL]: \(destinationURL?.path ?? "nil")")
    output.append("[ResumeData]: \(resumeData?.count ?? 0) bytes")
    output.append("[Result]: \(result.debugDescription)")
    output.append("[Timeline]: \(timeline.debugDescription)")
    
    return output.joined(separator: "\n")
  }
}

// MARK: -

extension DownloadResponse {
  /// Evaluates the given closure when the result of this `DownloadResponse` is a success, passing the unwrapped
  /// result value as a parameter.
  ///
  /// - returns: A `DownloadResponse` whose result wraps the value returned by the given closure. If this instance's
  ///            result is a failure, returns a response wrapping the same failure.
  public func map<T>(_ transform: (V) -> T) -> DownloadResponse<T> {
    var response = DownloadResponse<T>(
      request: request,
      response: self.response,
      temporaryURL: temporaryURL,
      destinationURL: destinationURL,
      resumeData: resumeData,
      result: result.map(transform),
      timeline: timeline
    )
    
    response._metrics = _metrics
    
    return response
  }
  
  /// Evaluates the given closure when the result of this `DownloadResponse` is a success, passing the unwrapped
  /// result value as a parameter.
  ///
  /// - returns: A success or failure `DownloadResponse` depending on the result of the given closure. If this
  /// instance's result is a failure, returns the same failure.
  public func flatMap<T>(_ transform: (V) throws -> T) -> DownloadResponse<T> {
    var response = DownloadResponse<T>(
      request: request,
      response: self.response,
      temporaryURL: temporaryURL,
      destinationURL: destinationURL,
      resumeData: resumeData,
      result: result.flatMap(transform),
      timeline: timeline
    )
    
    response._metrics = _metrics
    
    return response
  }
}

// MARK: -

protocol Response {
  /// The task metrics containing the request / response statistics.
  var _metrics: AnyObject? { get set }
  mutating func add(_ metrics: AnyObject?)
}

extension Response {
  mutating func add(_ metrics: AnyObject?) {
    #if !os(watchOS)
      guard #available(iOS 10.0, macOS 10.12, tvOS 10.0, *) else { return }
      guard let metrics = metrics as? URLSessionTaskMetrics else { return }
      
      _metrics = metrics
    #endif
  }
}

// MARK: -

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DefaultDataResponse: Response {
  #if !os(watchOS)
  /// The task metrics containing the request / response statistics.
  public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
  #endif
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DataResponse: Response {
  #if !os(watchOS)
  /// The task metrics containing the request / response statistics.
  public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
  #endif
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DefaultDownloadResponse: Response {
  #if !os(watchOS)
  /// The task metrics containing the request / response statistics.
  public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
  #endif
}

@available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
extension DownloadResponse: Response {
  #if !os(watchOS)
  /// The task metrics containing the request / response statistics.
  public var metrics: URLSessionTaskMetrics? { return _metrics as? URLSessionTaskMetrics }
  #endif
}

