//
//  SessionManager.swift
//

import Foundation

/// Responsible for creating and managing `Request` objects, as well as their underlying `NSURLSession`.
open class SessionManager {

    // MARK: - Helper Types

    /// Defines whether the `MultipartFormData` encoding was successful and contains result of the encoding as
    /// associated values.
    ///
    /// - Success: Represents a successful `MultipartFormData` encoding and contains the new `UploadRequest` along with
    ///            streaming information.
    /// - Failure: Used to represent a failure in the `MultipartFormData` encoding and also contains the encoding
    ///            error.
    public enum MultipartFormDataEncodingResult {
        case success(request: UploadRequest, streamingFromDisk: Bool, streamFileURL: URL?)
        case failure(Error)
    }

    // MARK: - Properties

    /// A default instance of `SessionManager`, used by top-level SwiftyREST request methods, and suitable for use
    /// directly for any ad hoc requests.
    open static let `default`: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders

        return SessionManager(configuration: configuration)
    }()

    /// Creates default values for the "Accept-Encoding", "Accept-Language" and "User-Agent" headers.
    open static let defaultHTTPHeaders: HTTPHeaders = {
        // Accept-Encoding HTTP Header; see https://tools.ietf.org/html/rfc7230#section-4.2.3
        let acceptEncoding: String = "gzip;q=1.0, compress;q=0.5"

        // Accept-Language HTTP Header; see https://tools.ietf.org/html/rfc7231#section-5.3.5
        let acceptLanguage = Locale.preferredLanguages.prefix(6).enumerated().map { index, languageCode in
            let quality = 1.0 - (Double(index) * 0.1)
            return "\(languageCode);q=\(quality)"
        }.joined(separator: ", ")

        // User-Agent Header; see https://tools.ietf.org/html/rfc7231#section-5.5.3
        let userAgent: String = {
            if let info = Bundle.main.infoDictionary {
                let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
                let bundle = info[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
                let appVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
                let appBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"

                let osNameVersion: String = {
                    let version = ProcessInfo.processInfo.operatingSystemVersion
                    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

                    let osName: String = {
                        #if os(iOS)
                            return "iOS"
                        #elseif os(watchOS)
                            return "watchOS"
                        #elseif os(tvOS)
                            return "tvOS"
                        #elseif os(macOS)
                            return "OS X"
                        #elseif os(Linux)
                            return "Linux"
                        #else
                            return "Unknown"
                        #endif
                    }()

                    return "\(osName) \(versionString)"
                }()

                let SwiftyRESTVersion: String = {
                    guard
                        let afInfo = Bundle(for: SessionManager.self).infoDictionary,
                        let build = afInfo["CFBundleShortVersionString"]
                    else { return "Unknown" }

                    return "SwiftyREST/\(build)"
                }()

                return "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion)) \(SwiftyRESTVersion)"
            }

            return "SwiftyREST"
        }()

        return [
            "Accept-Encoding": acceptEncoding,
            "Accept-Language": acceptLanguage,
            "User-Agent": userAgent
        ]
    }()

    /// Default memory threshold used when encoding `MultipartFormData` in bytes.
    open static let multipartFormDataEncodingMemoryThreshold: UInt64 = 10_000_000

    /// The underlying session.
    open let session: URLSession

    /// The session delegate handling all the task and session delegate callbacks.
    open let delegate: SessionDelegate

    /// Whether to start requests immediately after being constructed. `true` by default.
    open var startRequestsImmediately: Bool = true

    /// The request adapter called each time a new request is created.
    open var adapter: RequestAdapter?

    /// The request retrier called each time a request encounters an error to determine whether to retry the request.
    open var retrier: RequestRetrier? {
        get { return delegate.retrier }
        set { delegate.retrier = newValue }
    }

    /// The background completion handler closure provided by the UIApplicationDelegate
    ///
    open var backgroundCompletionHandler: (() -> Void)?

    let queue = DispatchQueue(label: "org.SwiftyREST.session-manager." + UUID().uuidString)

    // MARK: - Lifecycle

    /// Creates an instance with the specified `configuration`, `delegate` and `serverTrustPolicyManager`.
    ///
    /// - returns: The new `SessionManager` instance.
    public init(
        configuration: URLSessionConfiguration = URLSessionConfiguration.default,
        delegate: SessionDelegate = SessionDelegate(),
        serverTrustPolicyManager: ServerTrustPolicyManager? = nil)
    {
        self.delegate = delegate
        self.session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)

        commonInit(serverTrustPolicyManager: serverTrustPolicyManager)
    }

    /// Creates an instance with the specified `session`, `delegate` and `serverTrustPolicyManager`.
    ///
    /// - returns: The new `SessionManager` instance if the URL session's delegate matches; `nil` otherwise.
    public init?(
        session: URLSession,
        delegate: SessionDelegate,
        serverTrustPolicyManager: ServerTrustPolicyManager? = nil)
    {
        guard delegate === session.delegate else { return nil }

        self.delegate = delegate
        self.session = session

        commonInit(serverTrustPolicyManager: serverTrustPolicyManager)
    }

    private func commonInit(serverTrustPolicyManager: ServerTrustPolicyManager?) {
        session.serverTrustPolicyManager = serverTrustPolicyManager

        delegate.sessionManager = self

        delegate.sessionDidFinishEventsForBackgroundURLSession = { [weak self] session in
            guard let strongSelf = self else { return }
            DispatchQueue.main.async { strongSelf.backgroundCompletionHandler?() }
        }
    }

    deinit {
        session.invalidateAndCancel()
    }

    // MARK: - Data Request

    /// Creates a `DataRequest` to retrieve the contents of the specified `url`, `method`, `parameters`, `encoding`
    /// and `headers`.
    ///
    /// - returns: The created `DataRequest`.
    @discardableResult
    open func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil)
        -> DataRequest
    {
        var originalRequest: URLRequest?

        do {
            originalRequest = try URLRequest(url: url, method: method, headers: headers)
            let encodedURLRequest = try encoding.encode(originalRequest!, with: parameters)
            return request(encodedURLRequest)
        } catch {
            return request(originalRequest, failedWith: error)
        }
    }

    /// Creates a `DataRequest` to retrieve the contents of a URL based on the specified `urlRequest`.
    ///
    /// - returns: The created `DataRequest`.
    @discardableResult
    open func request(_ urlRequest: URLRequestConvertible) -> DataRequest {
        var originalRequest: URLRequest?

        do {
            originalRequest = try urlRequest.asURLRequest()
            let originalTask = DataRequest.Requestable(urlRequest: originalRequest!)

            let task = try originalTask.task(session: session, adapter: adapter, queue: queue)
            let request = DataRequest(session: session, requestTask: .data(originalTask, task))

            delegate[task] = request

            if startRequestsImmediately { request.resume() }

            return request
        } catch {
            return request(originalRequest, failedWith: error)
        }
    }

    // MARK: Private - Request Implementation

    private func request(_ urlRequest: URLRequest?, failedWith error: Error) -> DataRequest {
        var requestTask: Request.RequestTask = .data(nil, nil)

        if let urlRequest = urlRequest {
            let originalTask = DataRequest.Requestable(urlRequest: urlRequest)
            requestTask = .data(originalTask, nil)
        }

        let underlyingError = error.underlyingAdaptError ?? error
        let request = DataRequest(session: session, requestTask: requestTask, error: underlyingError)

        if let retrier = retrier, error is AdaptError {
            allowRetrier(retrier, toRetry: request, with: underlyingError)
        } else {
            if startRequestsImmediately { request.resume() }
        }

        return request
    }

    // MARK: - Download Request

    // MARK: URL Request

    /// Creates a `DownloadRequest` to retrieve the contents the specified `url`, `method`, `parameters`, `encoding`,
    /// `headers` and save them to the `destination`.
    ///
    /// - returns: The created `DownloadRequest`.
    @discardableResult
    open func download(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil,
        to destination: DownloadRequest.DownloadFileDestination? = nil)
        -> DownloadRequest
    {
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: headers)
            let encodedURLRequest = try encoding.encode(urlRequest, with: parameters)
            return download(encodedURLRequest, to: destination)
        } catch {
            return download(nil, to: destination, failedWith: error)
        }
    }

    /// Creates a `DownloadRequest` to retrieve the contents of a URL based on the specified `urlRequest` and save
    /// them to the `destination`.
    ///
    /// - returns: The created `DownloadRequest`.
    @discardableResult
    open func download(
        _ urlRequest: URLRequestConvertible,
        to destination: DownloadRequest.DownloadFileDestination? = nil)
        -> DownloadRequest
    {
        do {
            let urlRequest = try urlRequest.asURLRequest()
            return download(.request(urlRequest), to: destination)
        } catch {
            return download(nil, to: destination, failedWith: error)
        }
    }

    // MARK: Resume Data

    /// Creates a `DownloadRequest` from the `resumeData` produced from a previous request cancellation to retrieve
    /// the contents of the original request and save them to the `destination`.
    ///
    /// - returns: The created `DownloadRequest`.
    @discardableResult
    open func download(
        resumingWith resumeData: Data,
        to destination: DownloadRequest.DownloadFileDestination? = nil)
        -> DownloadRequest
    {
        return download(.resumeData(resumeData), to: destination)
    }

    // MARK: Private - Download Implementation

    private func download(
        _ downloadable: DownloadRequest.Downloadable,
        to destination: DownloadRequest.DownloadFileDestination?)
        -> DownloadRequest
    {
        do {
            let task = try downloadable.task(session: session, adapter: adapter, queue: queue)
            let download = DownloadRequest(session: session, requestTask: .download(downloadable, task))

            download.downloadDelegate.destination = destination

            delegate[task] = download

            if startRequestsImmediately { download.resume() }

            return download
        } catch {
            return download(downloadable, to: destination, failedWith: error)
        }
    }

    private func download(
        _ downloadable: DownloadRequest.Downloadable?,
        to destination: DownloadRequest.DownloadFileDestination?,
        failedWith error: Error)
        -> DownloadRequest
    {
        var downloadTask: Request.RequestTask = .download(nil, nil)

        if let downloadable = downloadable {
            downloadTask = .download(downloadable, nil)
        }

        let underlyingError = error.underlyingAdaptError ?? error

        let download = DownloadRequest(session: session, requestTask: downloadTask, error: underlyingError)
        download.downloadDelegate.destination = destination

        if let retrier = retrier, error is AdaptError {
            allowRetrier(retrier, toRetry: download, with: underlyingError)
        } else {
            if startRequestsImmediately { download.resume() }
        }

        return download
    }

    // MARK: - Upload Request

    // MARK: File

    /// Creates an `UploadRequest` from the specified `url`, `method` and `headers` for uploading the `file`.
    ///
    /// - returns: The created `UploadRequest`.
    @discardableResult
    open func upload(
        _ fileURL: URL,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil)
        -> UploadRequest
    {
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: headers)
            return upload(fileURL, with: urlRequest)
        } catch {
            return upload(nil, failedWith: error)
        }
    }

    /// Creates a `UploadRequest` from the specified `urlRequest` for uploading the `file`.
    ///
    /// - returns: The created `UploadRequest`.
    @discardableResult
    open func upload(_ fileURL: URL, with urlRequest: URLRequestConvertible) -> UploadRequest {
        do {
            let urlRequest = try urlRequest.asURLRequest()
            return upload(.file(fileURL, urlRequest))
        } catch {
            return upload(nil, failedWith: error)
        }
    }

    // MARK: Data

    /// Creates an `UploadRequest` from the specified `url`, `method` and `headers` for uploading the `data`.
    ///
    /// - returns: The created `UploadRequest`.
    @discardableResult
    open func upload(
        _ data: Data,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil)
        -> UploadRequest
    {
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: headers)
            return upload(data, with: urlRequest)
        } catch {
            return upload(nil, failedWith: error)
        }
    }

    /// Creates an `UploadRequest` from the specified `urlRequest` for uploading the `data`.
    ///
    /// - returns: The created `UploadRequest`.
    @discardableResult
    open func upload(_ data: Data, with urlRequest: URLRequestConvertible) -> UploadRequest {
        do {
            let urlRequest = try urlRequest.asURLRequest()
            return upload(.data(data, urlRequest))
        } catch {
            return upload(nil, failedWith: error)
        }
    }

    // MARK: InputStream

    /// Creates an `UploadRequest` from the specified `url`, `method` and `headers` for uploading the `stream`.
    ///
    /// - returns: The created `UploadRequest`.
    @discardableResult
    open func upload(
        _ stream: InputStream,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil)
        -> UploadRequest
    {
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: headers)
            return upload(stream, with: urlRequest)
        } catch {
            return upload(nil, failedWith: error)
        }
    }

    /// Creates an `UploadRequest` from the specified `urlRequest` for uploading the `stream`.
    ///
    /// - returns: The created `UploadRequest`.
    @discardableResult
    open func upload(_ stream: InputStream, with urlRequest: URLRequestConvertible) -> UploadRequest {
        do {
            let urlRequest = try urlRequest.asURLRequest()
            return upload(.stream(stream, urlRequest))
        } catch {
            return upload(nil, failedWith: error)
        }
    }

    // MARK: MultipartFormData

    /// Encodes `multipartFormData` using `encodingMemoryThreshold` and calls `encodingCompletion` with new
    /// `UploadRequest` using the `url`, `method` and `headers`.
    ///
    open func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil,
        encodingCompletion: ((MultipartFormDataEncodingResult) -> Void)?)
    {
        do {
            let urlRequest = try URLRequest(url: url, method: method, headers: headers)

            return upload(
                multipartFormData: multipartFormData,
                usingThreshold: encodingMemoryThreshold,
                with: urlRequest,
                encodingCompletion: encodingCompletion
            )
        } catch {
            DispatchQueue.main.async { encodingCompletion?(.failure(error)) }
        }
    }

    /// Encodes `multipartFormData` using `encodingMemoryThreshold` and calls `encodingCompletion` with new
    /// `UploadRequest` using the `urlRequest`.
    ///
    open func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
        with urlRequest: URLRequestConvertible,
        encodingCompletion: ((MultipartFormDataEncodingResult) -> Void)?)
    {
        DispatchQueue.global(qos: .utility).async {
            let formData = MultipartFormData()
            multipartFormData(formData)

            var tempFileURL: URL?

            do {
                var urlRequestWithContentType = try urlRequest.asURLRequest()
                urlRequestWithContentType.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")

                let isBackgroundSession = self.session.configuration.identifier != nil

                if formData.contentLength < encodingMemoryThreshold && !isBackgroundSession {
                    let data = try formData.encode()

                    let encodingResult = MultipartFormDataEncodingResult.success(
                        request: self.upload(data, with: urlRequestWithContentType),
                        streamingFromDisk: false,
                        streamFileURL: nil
                    )

                    DispatchQueue.main.async { encodingCompletion?(encodingResult) }
                } else {
                    let fileManager = FileManager.default
                    let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
                    let directoryURL = tempDirectoryURL.appendingPathComponent("com.SwiftyREST.manager/multipart.form.data")
                    let fileName = UUID().uuidString
                    let fileURL = directoryURL.appendingPathComponent(fileName)

                    tempFileURL = fileURL

                    var directoryError: Error?

                    // Create directory inside serial queue to ensure two threads don't do this in parallel
                    self.queue.sync {
                        do {
                            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                        } catch {
                            directoryError = error
                        }
                    }

                    if let directoryError = directoryError { throw directoryError }

                    try formData.writeEncodedData(to: fileURL)

                    let upload = self.upload(fileURL, with: urlRequestWithContentType)

                    // Cleanup the temp file once the upload is complete
                    upload.delegate.queue.addOperation {
                        do {
                            try FileManager.default.removeItem(at: fileURL)
                        } catch {
                            // No-op
                        }
                    }

                    DispatchQueue.main.async {
                        let encodingResult = MultipartFormDataEncodingResult.success(
                            request: upload,
                            streamingFromDisk: true,
                            streamFileURL: fileURL
                        )

                        encodingCompletion?(encodingResult)
                    }
                }
            } catch {
                // Cleanup the temp file in the event that the multipart form data encoding failed
                if let tempFileURL = tempFileURL {
                    do {
                        try FileManager.default.removeItem(at: tempFileURL)
                    } catch {
                        // No-op
                    }
                }

                DispatchQueue.main.async { encodingCompletion?(.failure(error)) }
            }
        }
    }

    // MARK: Private - Upload Implementation

    private func upload(_ uploadable: UploadRequest.Uploadable) -> UploadRequest {
        do {
            let task = try uploadable.task(session: session, adapter: adapter, queue: queue)
            let upload = UploadRequest(session: session, requestTask: .upload(uploadable, task))

            if case let .stream(inputStream, _) = uploadable {
                upload.delegate.taskNeedNewBodyStream = { _, _ in inputStream }
            }

            delegate[task] = upload

            if startRequestsImmediately { upload.resume() }

            return upload
        } catch {
            return upload(uploadable, failedWith: error)
        }
    }

    private func upload(_ uploadable: UploadRequest.Uploadable?, failedWith error: Error) -> UploadRequest {
        var uploadTask: Request.RequestTask = .upload(nil, nil)

        if let uploadable = uploadable {
            uploadTask = .upload(uploadable, nil)
        }

        let underlyingError = error.underlyingAdaptError ?? error
        let upload = UploadRequest(session: session, requestTask: uploadTask, error: underlyingError)

        if let retrier = retrier, error is AdaptError {
            allowRetrier(retrier, toRetry: upload, with: underlyingError)
        } else {
            if startRequestsImmediately { upload.resume() }
        }

        return upload
    }

#if !os(watchOS)

    // MARK: - Stream Request

    // MARK: Hostname and Port

    /// Creates a `StreamRequest` for bidirectional streaming using the `hostname` and `port`.
    ///
    /// - returns: The created `StreamRequest`.
    @discardableResult
    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    open func stream(withHostName hostName: String, port: Int) -> StreamRequest {
        return stream(.stream(hostName: hostName, port: port))
    }

    // MARK: NetService

    /// Creates a `StreamRequest` for bidirectional streaming using the `netService`.
    ///
    /// - returns: The created `StreamRequest`.
    @discardableResult
    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    open func stream(with netService: NetService) -> StreamRequest {
        return stream(.netService(netService))
    }

    // MARK: Private - Stream Implementation

    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    private func stream(_ streamable: StreamRequest.Streamable) -> StreamRequest {
        do {
            let task = try streamable.task(session: session, adapter: adapter, queue: queue)
            let request = StreamRequest(session: session, requestTask: .stream(streamable, task))

            delegate[task] = request

            if startRequestsImmediately { request.resume() }

            return request
        } catch {
            return stream(failedWith: error)
        }
    }

    @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
    private func stream(failedWith error: Error) -> StreamRequest {
        let stream = StreamRequest(session: session, requestTask: .stream(nil, nil), error: error)
        if startRequestsImmediately { stream.resume() }
        return stream
    }

#endif

    // MARK: - Internal - Retry Request

    func retry(_ request: Request) -> Bool {
        guard let originalTask = request.originalTask else { return false }

        do {
            let task = try originalTask.task(session: session, adapter: adapter, queue: queue)

            request.delegate.task = task // resets all task delegate data

            request.retryCount += 1
            request.startTime = CFAbsoluteTimeGetCurrent()
            request.endTime = nil

            task.resume()

            return true
        } catch {
            request.delegate.error = error.underlyingAdaptError ?? error
            return false
        }
    }

    private func allowRetrier(_ retrier: RequestRetrier, toRetry request: Request, with error: Error) {
        DispatchQueue.utility.async { [weak self] in
            guard let strongSelf = self else { return }

            retrier.should(strongSelf, retry: request, with: error) { shouldRetry, timeDelay in
                guard let strongSelf = self else { return }

                guard shouldRetry else {
                    if strongSelf.startRequestsImmediately { request.resume() }
                    return
                }

                DispatchQueue.utility.after(timeDelay) {
                    guard let strongSelf = self else { return }

                    let retrySucceeded = strongSelf.retry(request)

                    if retrySucceeded, let task = request.task {
                        strongSelf.delegate[task] = request
                    } else {
                        if strongSelf.startRequestsImmediately { request.resume() }
                    }
                }
            }
        }
    }
}
