//
//  Result.swift
//

import Foundation

/// Used to represent whether a request was successful or encountered an error.
///
/// - success: The request and all post processing operations were successful resulting in the serialization of the
///            provided associated value.
///
/// - failure: The request encountered an error resulting in a failure. The associated values are the original data
///            provided by the server as well as the error that caused the failure.
public enum Result<V> {
  case success(V)
  case failure(Error)
  
  /// Returns `true` if the result is a success, `false` otherwise.
  public var isSuccess: Bool {
    switch self {
    case .success:
      return true
    case .failure:
      return false
    }
  }
  
  /// Returns `true` if the result is a failure, `false` otherwise.
  public var isFailure: Bool {
    return !isSuccess
  }
  
  /// Returns the associated value if the result is a success, `nil` otherwise.
  public var value: V? {
    switch self {
    case .success(let value):
      return value
    case .failure:
      return nil
    }
  }
  
  /// Returns the associated error value if the result is a failure, `nil` otherwise.
  public var error: Error? {
    switch self {
    case .success:
      return nil
    case .failure(let error):
      return error
    }
  }
}

// MARK: - CustomStringConvertible

extension Result: CustomStringConvertible {
  /// The textual representation used when written to an output stream, which includes whether the result was a
  /// success or failure.
  public var description: String {
    switch self {
    case .success:
      return "SUCCESS"
    case .failure:
      return "FAILURE"
    }
  }
}

// MARK: - CustomDebugStringConvertible

extension Result: CustomDebugStringConvertible {
  /// The debug textual representation used when written to an output stream, which includes whether the result was a
  /// success or failure in addition to the value or error.
  public var debugDescription: String {
    switch self {
    case .success(let value):
      return "SUCCESS: \(value)"
    case .failure(let error):
      return "FAILURE: \(error)"
    }
  }
}

// MARK: - Functional APIs

extension Result {
  /// Creates a `Result` instance from the result of a closure.
  ///
  /// - parameter value: The closure to execute and create the result for.
  public init(value: () throws -> V) {
    do {
      self = try .success(value())
    } catch {
      self = .failure(error)
    }
  }
  
  /// Returns the success value, or throws the failure error.
  ///
  public func unwrap() throws -> V {
    switch self {
    case .success(let value):
      return value
    case .failure(let error):
      throw error
    }
  }
  
  /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
  ///
  /// - returns: A `Result` containing the result of the given closure. If this instance is a failure, returns the
  ///            same failure.
  public func map<T>(_ transform: (V) -> T) -> Result<T> {
    switch self {
    case .success(let value):
      return .success(transform(value))
    case .failure(let error):
      return .failure(error)
    }
  }
  
  /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
  ///
  /// - returns: A `Result` containing the result of the given closure. If this instance is a failure, returns the
  ///            same failure.
  public func flatMap<T>(_ transform: (V) throws -> T) -> Result<T> {
    switch self {
    case .success(let value):
      do {
        return try .success(transform(value))
      } catch {
        return .failure(error)
      }
    case .failure(let error):
      return .failure(error)
    }
  }
  
  /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
  ///
  /// - Returns: A `Result` instance containing the result of the transform. If this instance is a success, returns
  ///            the same instance.
  public func mapError<T: Error>(_ transform: (Error) -> T) -> Result {
    switch self {
    case .failure(let error):
      return .failure(transform(error))
    case .success:
      return self
    }
  }
  
  /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
  ///
  /// - Returns: A `Result` instance containing the result of the transform. If this instance is a success, returns
  ///            the same instance.
  public func flatMapError<T: Error>(_ transform: (Error) throws -> T) -> Result {
    switch self {
    case .failure(let error):
      do {
        return try .failure(transform(error))
      } catch {
        return .failure(error)
      }
    case .success:
      return self
    }
  }
  
  /// Evaluates the specified closure when the `Result` is a success, passing the unwrapped value as a parameter.
  ///
  /// - Returns: This `Result` instance, unmodified.
  @discardableResult
  public func withValue(_ closure: (V) -> Void) -> Result {
    if case let .success(value) = self {
      closure(value)
    }
    
    return self
  }
  
  /// Evaluates the specified closure when the `Result` is a failure, passing the unwrapped error as a parameter.
  ///
  /// - Returns: This `Result` instance, unmodified.
  @discardableResult
  public func withError(_ closure: (Error) -> Void) -> Result {
    if case let .failure(error) = self {
      closure(error)
    }
    
    return self
  }
  
  /// Evaluates the specified closure when the `Result` is a success.
  ///
  /// - Returns: This `Result` instance, unmodified.
  @discardableResult
  public func ifSuccess(_ closure: () -> Void) -> Result {
    if isSuccess {
      closure()
    }
    
    return self
  }
  
  /// Evaluates the specified closure when the `Result` is a failure.
  ///
  /// - Returns: This `Result` instance, unmodified.
  @discardableResult
  public func ifFailure(_ closure: () -> Void) -> Result {
    if isFailure {
      closure()
    }
    
    return self
  }
}

