//
//  ParameterEncoding.swift
//

import Foundation

/// HTTP method definitions.
public enum HTTPMethod: String {
  case options = "OPTIONS"
  case get     = "GET"
  case head    = "HEAD"
  case post    = "POST"
  case put     = "PUT"
  case patch   = "PATCH"
  case delete  = "DELETE"
  case trace   = "TRACE"
  case connect = "CONNECT"
}

// MARK: -

/// A dictionary of parameters to apply to a `URLRequest`.
public typealias Parameters = [String: Any]

/// A type used to define how a set of parameters are applied to a `URLRequest`.
public protocol ParameterEncoding {
  /// Creates a URL request by encoding parameters and applying them onto an existing request.
  ///
  /// - throws: An `GDError.parameterEncodingFailed` error if encoding fails.
  ///
  /// - returns: The encoded request.
  func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest
}

// MARK: -

/// Creates a url-encoded query string to be set as or appended to any existing URL query string or set as the HTTP
/// body of the URL request. Whether the query string is set or appended to any existing URL query string or set as
/// the HTTP body depends on the destination of the encoding.
public struct URLEncoding: ParameterEncoding {
  
  // MARK: Helper Types
  
  /// Defines whether the url-encoded query string is applied to the existing query string or HTTP body of the
  /// resulting URL request.
  public enum Destination {
    case methodDependent, queryString, httpBody
  }
  
  // MARK: Properties
  
  /// Returns a default `URLEncoding` instance.
  public static var urlDefault: URLEncoding { return URLEncoding() }
  
  /// Returns a `URLEncoding` instance with a `.methodDependent` destination.
  public static var methodDependent: URLEncoding { return URLEncoding() }
  
  /// Returns a `URLEncoding` instance with a `.queryString` destination.
  public static var queryString: URLEncoding { return URLEncoding(destination: .queryString) }
  
  /// Returns a `URLEncoding` instance with an `.httpBody` destination.
  public static var httpBody: URLEncoding { return URLEncoding(destination: .httpBody) }
  
  /// The destination defining where the encoded query string is to be applied to the URL request.
  public let destination: Destination
  
  // MARK: Initialization
  
  /// Creates a `URLEncoding` instance using the specified destination.
  ///
  /// - returns: The new `URLEncoding` instance.
  public init(destination: Destination = .methodDependent) {
    self.destination = destination
  }
  
  // MARK: Encoding
  
  /// Creates a URL request by encoding parameters and applying them onto an existing request.
  ///
  /// - throws: An `Error` if the encoding process encounters an error.
  ///
  /// - returns: The encoded request.
  public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
    var urlRequest = try urlRequest.asURLRequest()
    
    guard let parameters = parameters else { return urlRequest }
    
    if let method = HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET"), encodesParametersInURL(with: method) {
      guard let url = urlRequest.url else {
        throw GDError.parameterEncodingFailed(reason: .missingURL)
      }
      
      if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
        let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
        urlComponents.percentEncodedQuery = percentEncodedQuery
        urlRequest.url = urlComponents.url
      }
    } else {
      if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
        urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
      }
      
      urlRequest.httpBody = query(parameters).data(using: .utf8, allowLossyConversion: false)
    }
    
    return urlRequest
  }
  
  /// Creates percent-escaped, URL encoded query string components from the given key-value pair using recursion.
  ///
  /// - returns: The percent-escaped, URL encoded query string components.
  public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
    var components: [(String, String)] = []
    
    if let dictionary = value as? [String: Any] {
      for (nestedKey, value) in dictionary {
        components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
      }
    } else if let array = value as? [Any] {
      for value in array {
        components += queryComponents(fromKey: "\(key)[]", value: value)
      }
    } else {
      components = self.appending(key: key, value: value)
    }
    
    return components
  }
  
  //Appending for code lint
  private func appending(key:String, value:Any) -> [(String, String)] {
    var components: [(String, String)] = []
    
    if let value = value as? NSNumber {
      if value.isBool {
        components.append((escape(key), escapingBool(value: value)))
      } else {
        components.append((escape(key), escape("\(value)")))
      }
    } else if let bool = value as? Bool {
      components.append((escape(key), escapingBool(value: bool)))
    } else {
      components.append((escape(key), escape("\(value)")))
    }
    
    return components
  }
  
  //Escaping Bool
  func escapingBool(value:NSNumber) -> String {
    return escape(value.boolValue ? "1" : "0")
  }
  
  //Escaping bool
  func escapingBool(value:Bool) -> String {
    return escape(value ? "1" : "0")
  }
  
  /// Returns a percent-escaped string following RFC 3986 for a query string key or value.
  ///
  /// - parameter string: The string to be percent-escaped.
  ///
  /// - returns: The percent-escaped string.
  public func escape(_ string: String) -> String {
    let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
    let subDelimitersToEncode = "!$&'()*+,;="
    
    var allowedCharacterSet = CharacterSet.urlQueryAllowed
    allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
    
    var escaped = ""
    
    if #available(iOS 8.3, *) {
      escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
    } else {
      let batchSize = 50
      var index = string.startIndex
      
      while index != string.endIndex {
        let startIndex = index
        let endIndex = string.index(index, offsetBy: batchSize, limitedBy: string.endIndex) ?? string.endIndex
        let range = startIndex..<endIndex
        
        let substring = string[range]
        
        escaped += substring.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? String(substring)
        
        index = endIndex
      }
    }
    
    return escaped
  }
  
  private func query(_ parameters: [String: Any]) -> String {
    var components: [(String, String)] = []
    
    for key in parameters.keys.sorted(by: <) {
      let value = parameters[key]!
      components += queryComponents(fromKey: key, value: value)
    }
    return components.map { "\($0)=\($1)" }.joined(separator: "&")
  }
  
  private func encodesParametersInURL(with method: HTTPMethod) -> Bool {
    switch destination {
    case .queryString:
      return true
    case .httpBody:
      return false
    default:
      break
    }
    
    if method == .get || method == .head || method == .delete {
      return true
    }
    return false
  }
}

// MARK: -

/// Uses `JSONSerialization` to create a JSON representation of the parameters object, which is set as the body of the
/// request. The `Content-Type` HTTP header field of an encoded request is set to `application/json`.
public struct JSONEncoding: ParameterEncoding {
  
  // MARK: Properties
  
  /// Returns a `JSONEncoding` instance with default writing options.
  public static var jsonDefault: JSONEncoding { return JSONEncoding() }
  
  /// Returns a `JSONEncoding` instance with `.prettyPrinted` writing options.
  public static var prettyPrinted: JSONEncoding { return JSONEncoding(options: .prettyPrinted) }
  
  /// The options for writing the parameters as JSON data.
  public let options: JSONSerialization.WritingOptions
  
  // MARK: Initialization
  
  /// Creates a `JSONEncoding` instance using the specified options.
  ///
  /// - returns: The new `JSONEncoding` instance.
  public init(options: JSONSerialization.WritingOptions = []) {
    self.options = options
  }
  
  // MARK: Encoding
  
  /// Creates a URL request by encoding parameters and applying them onto an existing request.
  /// - throws: An `Error` if the encoding process encounters an error.
  ///
  /// - returns: The encoded request.
  public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
    var urlRequest = try urlRequest.asURLRequest()
    
    guard let parameters = parameters else { return urlRequest }
    
    do {
      let data = try JSONSerialization.data(withJSONObject: parameters, options: options)
      
      if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }
      
      urlRequest.httpBody = data
    } catch {
      throw GDError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
    }
    
    return urlRequest
  }
  
  /// Creates a URL request by encoding the JSON object and setting the resulting data on the HTTP body.
  ///
  /// - returns: The encoded request.
  public func encode(_ urlRequest: URLRequestConvertible, withJSONObject jsonObject: Any? = nil) throws -> URLRequest {
    var urlRequest = try urlRequest.asURLRequest()
    
    guard let jsonObject = jsonObject else { return urlRequest }
    
    do {
      let data = try JSONSerialization.data(withJSONObject: jsonObject, options: options)
      
      if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
      }
      
      urlRequest.httpBody = data
    } catch {
      throw GDError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
    }
    
    return urlRequest
  }
}

// MARK: -

/// Uses `PropertyListSerialization` to create a plist representation of the parameters object, according to the
/// associated format and write options values, which is set as the body of the request. The `Content-Type` HTTP header
/// field of an encoded request is set to `application/x-plist`.
public struct PropertyListEncoding: ParameterEncoding {
  
  // MARK: Properties
  
  /// Returns a default `PropertyListEncoding` instance.
  public static var defaultList: PropertyListEncoding { return PropertyListEncoding() }
  
  /// Returns a `PropertyListEncoding` instance with xml formatting and default writing options.
  public static var xml: PropertyListEncoding { return PropertyListEncoding(format: .xml) }
  
  /// Returns a `PropertyListEncoding` instance with binary formatting and default writing options.
  public static var binary: PropertyListEncoding { return PropertyListEncoding(format: .binary) }
  
  /// The property list serialization format.
  public let format: PropertyListSerialization.PropertyListFormat
  
  /// The options for writing the parameters as plist data.
  public let options: PropertyListSerialization.WriteOptions
  
  // MARK: Initialization
  
  /// Creates a `PropertyListEncoding` instance using the specified format and options.
  ///
  /// - returns: The new `PropertyListEncoding` instance.
  public init(
    format: PropertyListSerialization.PropertyListFormat = .xml,
    options: PropertyListSerialization.WriteOptions = 0)
  {
    self.format = format
    self.options = options
  }
  
  // MARK: Encoding
  
  /// Creates a URL request by encoding parameters and applying them onto an existing request.
  ///
  /// - throws: An `Error` if the encoding process encounters an error.
  ///
  /// - returns: The encoded request.
  public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
    var urlRequest = try urlRequest.asURLRequest()
    
    guard let parameters = parameters else { return urlRequest }
    
    do {
      let data = try PropertyListSerialization.data(
        fromPropertyList: parameters,
        format: format,
        options: options
      )
      
      if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
        urlRequest.setValue("application/x-plist", forHTTPHeaderField: "Content-Type")
      }
      
      urlRequest.httpBody = data
    } catch {
      throw GDError.parameterEncodingFailed(reason: .propertyListEncodingFailed(error: error))
    }
    
    return urlRequest
  }
}

// MARK: -

extension NSNumber {
  fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

