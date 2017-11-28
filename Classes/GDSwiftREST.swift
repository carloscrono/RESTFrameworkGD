//
//  GDSwiftREST.swift
//
//

import Foundation

/// Types adopting the `URLConvertible` protocol can be used to construct URLs, which are then used to construct
/// URL requests.
public protocol URLConvertible {
    func asURL() throws -> URL
}

extension String: URLConvertible {
    /// Returns a URL if `self` represents a valid URL string that conforms to RFC 2396 or throws an `GDError`.
    public func asURL() throws -> URL {
        guard let url = URL(string: self) else { throw GDError.invalidURL(url: self) }
        return url
    }
}

extension URL: URLConvertible {
    /// Returns self.
    public func asURL() throws -> URL { return self }
}

extension URLComponents: URLConvertible {
    /// Returns a URL if `url` is not nil, otherwise throws an `Error`.
    public func asURL() throws -> URL {
        guard let url = url else { throw GDError.invalidURL(url: self) }
        return url
    }
}

// MARK: -

/// Types adopting the `URLRequestConvertible` protocol can be used to construct URL requests.
public protocol URLRequestConvertible {
    func asURLRequest() throws -> URLRequest
}

extension URLRequestConvertible {
    /// The URL request.
    public var urlRequest: URLRequest? { return try? asURLRequest() }
}

extension URLRequest: URLRequestConvertible {
    /// Returns a URL request or throws if an `Error` was encountered.
    public func asURLRequest() throws -> URLRequest { return self }
}

// MARK: -

extension URLRequest {
    /// Creates an instance with the specified `method`, `urlString` and `headers`.
    /// - returns: The new `URLRequest` instance.
    public init(url: URLConvertible, method: HTTPMethod, headers: HTTPHeaders? = nil) throws {
        let url = try url.asURL()

        self.init(url: url)

        httpMethod = method.rawValue

        if let headers = headers {
            for (headerField, headerValue) in headers {
                setValue(headerValue, forHTTPHeaderField: headerField)
            }
        }
    }

    func adapt(using adapter: RequestAdapter?) throws -> URLRequest {
        guard let adapter = adapter else { return self }
        return try adapter.adapt(self)
    }
}

// MARK: - Data Request

/// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of the specified `url`,
/// `method`, `parameters`, `encoding` and `headers`.
/// - returns: The created `DataRequest`.
@discardableResult
public func request(
    _ url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.default,
    headers: HTTPHeaders? = nil)
    -> DataRequest
{
    return SessionManager.default.request(
        url,
        method: method,
        parameters: parameters,
        encoding: encoding,
        headers: headers
    )
}

/// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of a URL based on the
/// specified `urlRequest`.
/// - returns: The created `DataRequest`.
@discardableResult
public func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
    return SessionManager.default.request(urlRequest)
}
