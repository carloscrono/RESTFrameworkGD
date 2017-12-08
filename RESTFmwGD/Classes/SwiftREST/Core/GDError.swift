//
//  GDError.swift
//
//

import Foundation

/// `GDError` is the error type returned by SwiftREST. It encompasses a few different types of errors, each with
/// their own associated reasons.
///

public enum GDError: Error {
  //// The underlying reason the errors occurred:
  
  public enum ParameterEncodingFailureReason {
    case missingURL
    case jsonEncodingFailed(error: Error)
    case propertyListEncodingFailed(error: Error)
  }
  
  public enum MultipartEncodingFailureReason {
    case bodyPartURLInvalid(url: URL)
    case bodyPartFilenameInvalid(in: URL)
    case bodyPartFileNotReachable(at: URL)
    case bodyPartFileNotReachableWithError(atURL: URL, error: Error)
    case bodyPartFileIsDirectory(at: URL)
    case bodyPartFileSizeNotAvailable(at: URL)
    case bodyPartFileSizeQueryFailedWithError(forURL: URL, error: Error)
    case bodyPartInputStreamCreationFailed(for: URL)
    
    case outputStreamCreationFailed(for: URL)
    case outputStreamFileAlreadyExists(at: URL)
    case outputStreamURLInvalid(url: URL)
    case outputStreamWriteFailed(error: Error)
    
    case inputStreamReadFailed(error: Error)
  }
  
  public enum ResponseValidationFailureReason {
    case dataFileNil
    case dataFileReadFailed(at: URL)
    case missingContentType(acceptableContentTypes: [String])
    case unacceptableContentType(acceptableContentTypes: [String], responseContentType: String)
    case unacceptableStatusCode(code: Int)
  }
  
  public enum ResponseSerializationFailureReason {
    case inputDataNil
    case inputDataNilOrZeroLength
    case inputFileNil
    case inputFileReadFailed(at: URL)
    case stringSerializationFailed(encoding: String.Encoding)
    case jsonSerializationFailed(error: Error)
    case propertyListSerializationFailed(error: Error)
  }
  
  case invalidURL(url: URLConvertible)
  case parameterEncodingFailed(reason: ParameterEncodingFailureReason)
  case multipartEncodingFailed(reason: MultipartEncodingFailureReason)
  case responseValidationFailed(reason: ResponseValidationFailureReason)
  case responseSerializationFailed(reason: ResponseSerializationFailureReason)
}

// MARK: - Adapt Error

struct AdaptError: Error {
  let error: Error
}

extension Error {
  var underlyingAdaptError: Error? { return (self as? AdaptError)?.error }
}

// MARK: - Error Booleans

extension GDError {
  /// Returns whether the GDError is an invalid URL error.
  public var isInvalidURLError: Bool {
    if case .invalidURL = self {
      return true
    }
    return false
  }
  
  /// Returns whether the GDError is a parameter encoding error. When `true`, the `underlyingError` property will
  /// contain the associated value.
  public var isParameterEncodingError: Bool {
    if case .parameterEncodingFailed = self {
      return true
    }
    return false
  }
  
  /// Returns whether the GDError is a multipart encoding error. When `true`, the `url` and `underlyingError` properties
  /// will contain the associated values.
  public var isMultipartEncodingError: Bool {
    if case .multipartEncodingFailed = self {
      return true
    }
    return false
  }
  
  /// Returns whether the `GDError` is a response validation error. When `true`, the `acceptableContentTypes`,
  /// `responseContentType`, and `responseCode` properties will contain the associated values.
  public var isResponseValidationError: Bool {
    if case .responseValidationFailed = self {
      return true
    }
    return false
  }
  
  /// Returns whether the `GDError` is a response serialization error. When `true`, the `failedStringEncoding` and
  /// `underlyingError` properties will contain the associated values.
  public var isResponseSerializationError: Bool {
    if case .responseSerializationFailed = self {
      return true
    }
    return false
  }
}

// MARK: - Convenience Properties

extension GDError {
  /// The `URLConvertible` associated with the error.
  public var urlConvertible: URLConvertible? {
    if case .invalidURL(let url) = self {
      return url
    }
    return nil
  }
  
  /// The `URL` associated with the error.
  public var url: URL? {
    
    if case .multipartEncodingFailed(let reason) = self {
      return reason.url
    }
    return nil
  }
  
  /// The `Error` returned by a system framework associated with a `.parameterEncodingFailed`,
  /// `.multipartEncodingFailed` or `.responseSerializationFailed` error.
  public var underlyingError: Error? {
    switch self {
    case .parameterEncodingFailed(let reason):
      return reason.underlyingError
    case .multipartEncodingFailed(let reason):
      return reason.underlyingError
    case .responseSerializationFailed(let reason):
      return reason.underlyingError
    default:
      return nil
    }
  }
  
  /// The acceptable `Content-Type`s of a `.responseValidationFailed` error.
  public var acceptableContentTypes: [String]? {
    if case .responseValidationFailed(let reason) = self {
      return reason.acceptableContentTypes
    }
    return nil
  }
  
  /// The response `Content-Type` of a `.responseValidationFailed` error.
  public var responseContentType: String? {
    if case .responseValidationFailed(let reason) = self {
      return reason.responseContentType
    }
    return nil
  }
  
  /// The response code of a `.responseValidationFailed` error.
  public var responseCode: Int? {
    if case .responseValidationFailed(let reason) = self {
      return reason.responseCode
    }
    return nil
  }
  
  /// The `String.Encoding` associated with a failed `.stringResponse()` call.
  public var failedStringEncoding: String.Encoding? {
    if case .responseSerializationFailed(let reason) = self {
      return reason.failedStringEncoding
    }
    return nil
  }
}

extension GDError.ParameterEncodingFailureReason {
  var underlyingError: Error? {
    switch self {
    case .jsonEncodingFailed(let error):
      return error
    case .propertyListEncodingFailed(let error):
      return error
    default:
      return nil
    }
  }
}

extension GDError.MultipartEncodingFailureReason {
  var url: URL? {
    switch self {
    case .bodyPartURLInvalid(let url):
      return url
    case .bodyPartFilenameInvalid(let url):
      return url
    case .bodyPartFileNotReachable(let url):
      return url
    case .bodyPartFileIsDirectory(let url):
      return url
    case .bodyPartFileSizeNotAvailable(let url):
      return url
    case .bodyPartInputStreamCreationFailed(let url):
      return url
    case .outputStreamCreationFailed(let url):
      return url
    case .outputStreamFileAlreadyExists(let url):
      return url
    case .outputStreamURLInvalid(let url):
      return url
    case .bodyPartFileNotReachableWithError(let url, _):
      return url
    case .bodyPartFileSizeQueryFailedWithError(let url, _):
      return url
    default:
      return nil
    }
  }
  
  var underlyingError: Error? {
    switch self {
    case .bodyPartFileNotReachableWithError(_, let error):
      return error
    case .bodyPartFileSizeQueryFailedWithError(_, let error):
      return error
    case .outputStreamWriteFailed(let error):
      return error
    case .inputStreamReadFailed(let error):
      return error
    default:
      return nil
    }
  }
}

extension GDError.ResponseValidationFailureReason {
  var acceptableContentTypes: [String]? {
    switch self {
    case .missingContentType(let types):
      return types
    case .unacceptableContentType(let types, _):
      return types
    default:
      return nil
    }
  }
  
  var responseContentType: String? {
    if case .unacceptableContentType(_, let responseType) = self {
      return responseType
    }
    return nil
  }
  
  var responseCode: Int? {
    if case .unacceptableStatusCode(let code) = self {
      return code
    }
    return nil
  }
}

extension GDError.ResponseSerializationFailureReason {
  var failedStringEncoding: String.Encoding? {
    if case .stringSerializationFailed(let encoding) = self {
      return encoding
    }
    return nil
  }
  
  var underlyingError: Error? {
    switch self {
    case .jsonSerializationFailed(let error):
      return error
    case .propertyListSerializationFailed(let error):
      return error
    default:
      return nil
    }
  }
}

// MARK: - Error Descriptions

extension GDError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .invalidURL(let url):
      return "URL is not valid: \(url)"
    case .parameterEncodingFailed(let reason):
      return reason.localizedDescription
    case .multipartEncodingFailed(let reason):
      return reason.localizedDescription
    case .responseValidationFailed(let reason):
      return reason.localizedDescription
    case .responseSerializationFailed(let reason):
      return reason.localizedDescription
    }
  }
}

extension GDError.ParameterEncodingFailureReason {
  var localizedDescription: String {
    switch self {
    case .missingURL:
      return "URL request to encode was missing a URL"
    case .jsonEncodingFailed(let error):
      return "JSON could not be encoded because of error:\n\(error.localizedDescription)"
    case .propertyListEncodingFailed(let error):
      return "PropertyList could not be encoded because of error:\n\(error.localizedDescription)"
    }
  }
}

extension GDError.MultipartEncodingFailureReason {
  var localizedDescription: String {
    switch self {
    case .bodyPartURLInvalid(let url):
      return "The URL provided is not a file URL: \(url)"
    case .bodyPartFilenameInvalid(let url):
      return "The URL provided does not have a valid filename: \(url)"
    case .bodyPartFileNotReachable(let url):
      return "The URL provided is not reachable: \(url)"
    case .bodyPartFileNotReachableWithError(let url, let error):
      return (
        "The system returned an error while checking the provided URL for " +
        "reachability.\nURL: \(url)\nError: \(error)"
      )
    case .bodyPartFileIsDirectory(let url):
      return "The URL provided is a directory: \(url)"
    case .bodyPartFileSizeNotAvailable(let url):
      return "Could not fetch the file size from the provided URL: \(url)"
    case .bodyPartFileSizeQueryFailedWithError(let url, let error):
      return (
        "The system returned an error while attempting to fetch the file size from the " +
        "provided URL.\nURL: \(url)\nError: \(error)"
      )
    case .bodyPartInputStreamCreationFailed(let url):
      return "Failed to create an InputStream for the provided URL: \(url)"
    case .outputStreamCreationFailed(let url):
      return "Failed to create an OutputStream for URL: \(url)"
    case .outputStreamFileAlreadyExists(let url):
      return "A file already exists at the provided URL: \(url)"
    case .outputStreamURLInvalid(let url):
      return "The provided OutputStream URL is invalid: \(url)"
    case .outputStreamWriteFailed(let error):
      return "OutputStream write failed with error: \(error)"
    case .inputStreamReadFailed(let error):
      return "InputStream read failed with error: \(error)"
    }
  }
}

extension GDError.ResponseSerializationFailureReason {
  var localizedDescription: String {
    switch self {
    case .inputDataNil:
      return "Response could not be serialized, input data was nil."
    case .inputDataNilOrZeroLength:
      return "Response could not be serialized, input data was nil or zero length."
    case .inputFileNil:
      return "Response could not be serialized, input file was nil."
    case .inputFileReadFailed(let url):
      return "Response could not be serialized, input file could not be read: \(url)."
    case .stringSerializationFailed(let encoding):
      return "String could not be serialized with encoding: \(encoding)."
    case .jsonSerializationFailed(let error):
      return "JSON could not be serialized because of error:\n\(error.localizedDescription)"
    case .propertyListSerializationFailed(let error):
      return "PropertyList could not be serialized because of error:\n\(error.localizedDescription)"
    }
  }
}

extension GDError.ResponseValidationFailureReason {
  var localizedDescription: String {
    switch self {
    case .dataFileNil:
      return "Response could not be validated, data file was nil."
    case .dataFileReadFailed(let url):
      return "Response could not be validated, data file could not be read: \(url)."
    case .missingContentType(let types):
      return (
        "Response Content-Type was missing and acceptable content types " +
        "(\(types.joined(separator: ","))) do not match \"*/*\"."
      )
    case .unacceptableContentType(let acceptableTypes, let responseType):
      return (
        "Response Content-Type \"\(responseType)\" does not match any acceptable types: " +
        "\(acceptableTypes.joined(separator: ","))."
      )
    case .unacceptableStatusCode(let code):
      return "Response status code was unacceptable: \(code)."
    }
  }
}

