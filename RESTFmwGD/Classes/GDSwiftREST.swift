//
//  GDSwiftREST.swift
//
//

import Foundation

/// Types adopting the `URLConvertible` protocol can be used to construct URLs, which are then used to construct
/// URL requests.
public protocol URLConvertible {
    /// - throws: An `Error` if the type cannot be converted to a `URL`.
    ///
    /// - returns: A URL or throws an `Error`.
    func asURL() throws -> URL
}

extension String: URLConvertible {
    /// - throws: An `GDError.invalidURL` if `self` is not a valid URL string.
    ///
    /// - returns: A URL or throws an `GDError`.
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
    /// - throws: An `GDError.invalidURL` if `url` is `nil`.
    ///
    /// - returns: A URL or throws an `GDError`.
    public func asURL() throws -> URL {
        guard let url = url else { throw GDError.invalidURL(url: self) }
        return url
    }
}

// MARK: -

/// Types adopting the `URLRequestConvertible` protocol can be used to construct URL requests.
public protocol URLRequestConvertible {
    /// - throws: An `Error` if the underlying `URLRequest` is `nil`.
    ///
    /// - returns: A URL request.
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
    ///
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
///
/// - returns: The created `DataRequest`.
@discardableResult
public func request(
    _ url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.urlDefault,
    headers: HTTPHeaders? = nil)
    -> DataRequest
{
    return SessionManager.defaultSession.request(
        url,
        method: method,
        parameters: parameters,
        encoding: encoding,
        headers: headers
    )
}

/// Creates a `DataRequest` using the default `SessionManager` to retrieve the contents of a URL based on the
/// specified `urlRequest`.
///
/// - returns: The created `DataRequest`.
@discardableResult
public func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
    return SessionManager.defaultSession.request(urlRequest)
}

// MARK: - Download Request

// MARK: URL Request

/// Creates a `DownloadRequest` using the default `SessionManager` to retrieve the contents of the specified `url`,
/// `method`, `parameters`, `encoding`, `headers` and save them to the `destination`.
///
/// If `destination` is not specified, the contents will remain in the temporary location determined by the
/// underlying URL session.
///
/// - returns: The created `DownloadRequest`.
@discardableResult
public func download(
    _ url: URLConvertible,
    method: HTTPMethod = .get,
    parameters: Parameters? = nil,
    encoding: ParameterEncoding = URLEncoding.urlDefault,
    headers: HTTPHeaders? = nil,
    to destination: DownloadRequest.DownloadFileDestination? = nil)
    -> DownloadRequest
{
    return SessionManager.defaultSession.download(
        url,
        method: method,
        parameters: parameters,
        encoding: encoding,
        headers: headers,
        to: destination
    )
}

/// Creates a `DownloadRequest` using the default `SessionManager` to retrieve the contents of a URL based on the
/// specified `urlRequest` and save them to the `destination`.
///
/// If `destination` is not specified, the contents will remain in the temporary location determined by the
/// underlying URL session.
///
/// - returns: The created `DownloadRequest`.
@discardableResult
public func download(
    _ urlRequest: URLRequestConvertible,
    to destination: DownloadRequest.DownloadFileDestination? = nil)
    -> DownloadRequest
{
    return SessionManager.defaultSession.download(urlRequest, to: destination)
}

// MARK: Resume Data

/// Creates a `DownloadRequest` using the default `SessionManager` from the `resumeData` produced from a
/// previous request cancellation to retrieve the contents of the original request and save them to the `destination`.
///
/// - returns: The created `DownloadRequest`.
@discardableResult
public func download(
    resumingWith resumeData: Data,
    to destination: DownloadRequest.DownloadFileDestination? = nil)
    -> DownloadRequest
{
    return SessionManager.defaultSession.download(resumingWith: resumeData, to: destination)
}

// MARK: - Upload Request

// MARK: File

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `url`, `method` and `headers`
/// for uploading the `file`.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(
    _ fileURL: URL,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil)
    -> UploadRequest
{
    return SessionManager.defaultSession.upload(fileURL, to: url, method: method, headers: headers)
}

/// Creates a `UploadRequest` using the default `SessionManager` from the specified `urlRequest` for
/// uploading the `file`.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(_ fileURL: URL, with urlRequest: URLRequestConvertible) -> UploadRequest {
    return SessionManager.defaultSession.upload(fileURL, with: urlRequest)
}

// MARK: Data

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `url`, `method` and `headers`
/// for uploading the `data`.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(
    _ data: Data,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil)
    -> UploadRequest
{
    return SessionManager.defaultSession.upload(data, to: url, method: method, headers: headers)
}

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `urlRequest` for
/// uploading the `data`.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(_ data: Data, with urlRequest: URLRequestConvertible) -> UploadRequest {
    return SessionManager.defaultSession.upload(data, with: urlRequest)
}

// MARK: InputStream

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `url`, `method` and `headers`
/// for uploading the `stream`.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(
    _ stream: InputStream,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil)
    -> UploadRequest
{
    return SessionManager.defaultSession.upload(stream, to: url, method: method, headers: headers)
}

/// Creates an `UploadRequest` using the default `SessionManager` from the specified `urlRequest` for
/// uploading the `stream`.
///
/// - returns: The created `UploadRequest`.
@discardableResult
public func upload(_ stream: InputStream, with urlRequest: URLRequestConvertible) -> UploadRequest {
    return SessionManager.defaultSession.upload(stream, with: urlRequest)
}

// MARK: MultipartFormData

/// Encodes `multipartFormData` using `encodingMemoryThreshold` with the default `SessionManager` and calls
/// `encodingCompletion` with new `UploadRequest` using the `url`, `method` and `headers`.
///
public func upload(
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
    to url: URLConvertible,
    method: HTTPMethod = .post,
    headers: HTTPHeaders? = nil,
    encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?)
{
    return SessionManager.defaultSession.upload(
        multipartFormData: multipartFormData,
        usingThreshold: encodingMemoryThreshold,
        to: url,
        method: method,
        headers: headers,
        encodingCompletion: encodingCompletion
    )
}

/// Encodes `multipartFormData` using `encodingMemoryThreshold` and the default `SessionManager` and
/// calls `encodingCompletion` with new `UploadRequest` using the `urlRequest`.
///
public func upload(
    multipartFormData: @escaping (MultipartFormData) -> Void,
    usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
    with urlRequest: URLRequestConvertible,
    encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?)
{
    return SessionManager.defaultSession.upload(
        multipartFormData: multipartFormData,
        usingThreshold: encodingMemoryThreshold,
        with: urlRequest,
        encodingCompletion: encodingCompletion
    )
}

#if !os(watchOS)

// MARK: - Stream Request

// MARK: Hostname and Port

/// Creates a `StreamRequest` using the default `SessionManager` for bidirectional streaming with the `hostname`
/// and `port`.
///
/// - returns: The created `StreamRequest`.
@discardableResult
@available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
public func stream(withHostName hostName: String, port: Int) -> StreamRequest {
    return SessionManager.defaultSession.stream(withHostName: hostName, port: port)
}

// MARK: NetService

/// Creates a `StreamRequest` using the default `SessionManager` for bidirectional streaming with the `netService`.
///
/// - returns: The created `StreamRequest`.
@discardableResult
@available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
public func stream(with netService: NetService) -> StreamRequest {
    return SessionManager.defaultSession.stream(with: netService)
}

#endif
