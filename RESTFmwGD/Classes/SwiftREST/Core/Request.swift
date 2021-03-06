//
//  Request.swift
//

import Foundation

/// A type that can inspect and optionally adapt a `URLRequest` in some manner if necessary.
public protocol RequestAdapter {
  /// Inspects and adapts the specified `URLRequest` in some manner if necessary and returns the result.
  ///
  /// - returns: The adapted `URLRequest`.
  func adapt(_ urlRequest: URLRequest) throws -> URLRequest
}

// MARK: -

/// A closure executed when the `RequestRetrier` determines whether a `Request` should be retried or not.
public typealias RequestRetryCompletion = (_ shouldRetry: Bool, _ timeDelay: TimeInterval) -> Void

/// A type that determines whether a request should be retried after being executed by the specified session manager
/// and encountering an error.
public protocol RequestRetrier {
  /// Determines whether the `Request` should be retried by calling the `completion` closure.
  ///
  func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion)
}

// MARK: -

protocol TaskConvertible {
  func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask
}

/// A dictionary of headers to apply to a `URLRequest`.
public typealias HTTPHeaders = [String: String]

// MARK: -

/// Responsible for sending a request and receiving the response and associated data from the server, as well as
/// managing its underlying `URLSessionTask`.
open class Request {
  
  // MARK: Helper Types
  
  /// A closure executed when monitoring upload or download progress of a request.
  public typealias ProgressHandler = (Progress) -> Void
  
  enum RequestTask {
    case data(TaskConvertible?, URLSessionTask?)
    case download(TaskConvertible?, URLSessionTask?)
    case upload(TaskConvertible?, URLSessionTask?)
    case stream(TaskConvertible?, URLSessionTask?)
  }
  
  // MARK: Properties
  
  /// The delegate for the underlying task.
  open internal(set) var delegate: TaskDelegate {
    get {
      taskDelegateLock.lock()
      defer { taskDelegateLock.unlock()
      }
      return taskDelegate
    }
    set {
      taskDelegateLock.lock()
      defer { taskDelegateLock.unlock()
      }
      taskDelegate = newValue
    }
  }
  
  /// The underlying task.
  open var task: URLSessionTask? { return delegate.task }
  
  /// The session belonging to the underlying task.
  open let session: URLSession
  
  /// The request sent or to be sent to the server.
  open var requesting: URLRequest? { return task?.originalRequest }
  
  /// The response received from the server, if any.
  open var response: HTTPURLResponse? { return task?.response as? HTTPURLResponse }
  
  /// The number of times the requesting has been retried.
  open internal(set) var retryCount: UInt = 0
  
  let originalTask: TaskConvertible?
  
  var startTime: CFAbsoluteTime?
  var endTime: CFAbsoluteTime?
  
  var validations: [() -> Void] = []
  
  private var taskDelegate: TaskDelegate
  private var taskDelegateLock = NSLock()
  
  // MARK: Lifecycle
  
  init(session: URLSession, requestTask: RequestTask, error: Error? = nil) {
    self.session = session
    
    switch requestTask {
    case .data(let originalTask, let task):
      taskDelegate = DataTaskDelegate(task: task)
      self.originalTask = originalTask
    case .download(let originalTask, let task):
      taskDelegate = DownloadTaskDelegate(task: task)
      self.originalTask = originalTask
    case .upload(let originalTask, let task):
      taskDelegate = UploadTaskDelegate(task: task)
      self.originalTask = originalTask
    case .stream(let originalTask, let task):
      taskDelegate = TaskDelegate(task: task)
      self.originalTask = originalTask
    }
    
    delegate.error = error
    delegate.queue.addOperation { self.endTime = CFAbsoluteTimeGetCurrent() }
  }
  
  // MARK: Authentication
  
  /// Associates an HTTP Basic credential with the request.
  ///
  /// - returns: The request.
  @discardableResult
  open func authenticate(
    user: String,
    password: String,
    persistence: URLCredential.Persistence = .forSession)
    -> Self
  {
    let credential = URLCredential(user: user, password: password, persistence: persistence)
    return authenticate(usingCredential: credential)
  }
  
  /// Associates a specified credential with the request.
  ///
  /// - parameter credential: The credential.
  ///
  /// - returns: The request.
  @discardableResult
  open func authenticate(usingCredential credential: URLCredential) -> Self {
    delegate.credential = credential
    return self
  }
  
  /// Returns a base64 encoded basic authentication credential as an authorization header tuple.
  ///
  /// - returns: A tuple with Authorization header and credential value if encoding succeeds, `nil` otherwise.
  open static func authorizationHeader(user: String, password: String) -> (key: String, value: String)? {
    guard let data = "\(user):\(password)".data(using: .utf8) else { return nil }
    
    let credential = data.base64EncodedString(options: [])
    
    return (key: "Authorization", value: "Basic \(credential)")
  }
  
  // MARK: State
  
  /// Resumes the request.
  open func resume() {
    guard let task = task else {
      delegate.queue.isSuspended = false
      return
    }
    
    if startTime == nil {
      startTime = CFAbsoluteTimeGetCurrent()
    }
    
    task.resume()
    
    NotificationCenter.default.post(
      name: Notification.Name.Task.didResume,
      object: self,
      userInfo: [Notification.Key.task: task]
    )
  }
  
  /// Suspends the request.
  open func suspend() {
    guard let task = task else { return }
    
    task.suspend()
    
    NotificationCenter.default.post(
      name: Notification.Name.Task.didSuspend,
      object: self,
      userInfo: [Notification.Key.task: task]
    )
  }
  
  /// Cancels the request.
  open func cancel() {
    guard let task = task else { return }
    
    task.cancel()
    
    NotificationCenter.default.post(
      name: Notification.Name.Task.didCancel,
      object: self,
      userInfo: [Notification.Key.task: task]
    )
  }
}

// MARK: - CustomStringConvertible

extension Request: CustomStringConvertible {
  /// The textual representation used when written to an output stream, which includes the HTTP method and URL, as
  /// well as the response status code if a response has been received.
  open var description: String {
    var components: [String] = []
    
    if let httpMethod = requesting?.httpMethod {
      components.append(httpMethod)
    }
    
    if let urlString = requesting?.url?.absoluteString {
      components.append(urlString)
    }
    
    if let response = response {
      components.append("(\(response.statusCode))")
    }
    
    return components.joined(separator: " ")
  }
}

// MARK: - CustomDebugStringConvertible

extension Request: CustomDebugStringConvertible {
  /// The textual representation used when written to an output stream, in the form of a cURL command.
  open var debugDescription: String {
    return cURLRepresentation()
  }
  
  func cURLRepresentation() -> String {
    
    
    guard let request = self.requesting,
      let url = request.url,
      let host = url.host
      else {
        return "$ curl command could not be created"
    }
    
    var components:[String]
    components = appendingComponents(request: request, url: url, host: host)
    
    return components.joined(separator: " \\\n\t")
  }
  
  func appendingComponents(request:URLRequest, url:URL, host:String) -> [String]{
    
    var components = ["$ curl -v"]
    
    if let httpMethod = request.httpMethod, httpMethod != "GET" {
      components.append("-X \(httpMethod)")
    }
    
    if let credentialStorage = self.session.configuration.urlCredentialStorage {
      components.append(appendingSecondPhase(url: url, host: host, credentialStorage: credentialStorage, credential: delegate.credential!))
    }
    
    if session.configuration.httpShouldSetCookies, let cookieStorage = session.configuration.httpCookieStorage, let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
      let string = cookies.reduce("") {
        $0 + "\($1.name)=\($1.value);"
      }
      
      #if swift(>=3.2)
        components.append("-b \"\(string[..<string.index(before: string.endIndex)])\"")
      #else
        components.append("-b \"\(string.substring(to: string.characters.index(before: string.endIndex)))\"")
      #endif
    }
    
    var headers: [AnyHashable: Any] = [:]
    
    if let additionalHeaders = session.configuration.httpAdditionalHeaders {
      for (field, value) in additionalHeaders where field != AnyHashable("Cookie") {
        headers[field] = value
      }
    }
    
    if let headerFields = request.allHTTPHeaderFields {
      for (field, value) in headerFields where field != "Cookie" {
        headers[field] = value
      }
    }
    
    for (field, value) in headers {
      components.append("-H \"\(field): \(value)\"")
    }
    
    if let httpBodyData = request.httpBody, let httpBody = String(data: httpBodyData, encoding: .utf8) {
      var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
      escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")
      
      components.append("-d \"\(escapedBody)\"")
    }
    
    components.append("\"\(url.absoluteString)\"")
    
    return components
  }
}

func appendingSecondPhase(url:URL, host:String, credentialStorage: URLCredentialStorage, credential:URLCredential) -> String {
  let credentialStorage = credentialStorage
  let protectionSpace = URLProtectionSpace(
    host: host,
    port: url.port ?? 0,
    protocol: url.scheme,
    realm: host,
    authenticationMethod: NSURLAuthenticationMethodHTTPBasic
  )
  
  if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
    for credential in credentials {
      guard let user = credential.user, let password = credential.password else { continue }
      return "-u \(user):\(password)"
    }
  } else {
    let credential = credential
    if let user = credential.user, let password = credential.password {
      return "-u \(user):\(password)"
    }
  }
  return ""
}

// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionDataTask`.
open class DataRequest: Request {
  
  // MARK: Helper Types
  
  struct Requestable: TaskConvertible {
    let urlRequest: URLRequest
    
    func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
      do {
        let req = try self.urlRequest.adapt(using: adapter)
        return queue.sync {
          session.dataTask(with: req)
        }
      } catch {
        throw AdaptError(error: error)
      }
    }
  }
  
  // MARK: Properties
  
  /// The request sent or to be sent to the server.
  open override var requesting: URLRequest? {
    if let request = super.requesting {
      return request
    }
    if let requestable = originalTask as? Requestable {
      return requestable.urlRequest
    }
    
    return nil
  }
  
  /// The progress of fetching the response data from the server for the request.
  open var progress: Progress { return dataDelegate.progress }
  
  var dataDelegate: DataTaskDelegate { return delegate as! DataTaskDelegate }
  
  // MARK: Stream
  
  /// Sets a closure to be called periodically during the lifecycle of the request as data is read from the server.
  ///
  /// - returns: The request.
  @discardableResult
  open func stream(closure: ((Data) -> Void)? = nil) -> Self {
    dataDelegate.dataStream = closure
    return self
  }
  
  // MARK: Progress
  
  /// Sets a closure to be called periodically during the lifecycle of the `Request` as data is read from the server.
  ///
  /// - returns: The request.
  @discardableResult
  open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
    dataDelegate.progressHandler = (closure, queue)
    return self
  }
}

// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionDownloadTask`.
open class DownloadRequest: Request {
  
  // MARK: Helper Types
  
  /// A collection of options to be executed prior to moving a downloaded file from the temporary URL to the
  /// destination URL.
  public struct DownloadOptions: OptionSet {
    /// Returns the raw bitmask value of the option and satisfies the `RawRepresentable` protocol.
    public let rawValue: UInt
    
    /// A `DownloadOptions` flag that creates intermediate directories for the destination URL if specified.
    public static let createIntermediateDirectories = DownloadOptions(rawValue: 1 << 0)
    
    /// A `DownloadOptions` flag that removes a previous file from the destination URL if specified.
    public static let removePreviousFile = DownloadOptions(rawValue: 1 << 1)
    
    /// Creates a `DownloadFileDestinationOptions` instance with the specified raw value.
    ///
    /// - returns: A new log level instance.
    public init(rawValue: UInt) {
      self.rawValue = rawValue
    }
  }
  
  public typealias DownloadFileDestination = (
    _ temporaryURL: URL,
    _ response: HTTPURLResponse)
    -> (destinationURL: URL, options: DownloadOptions)
  
  enum Downloadable: TaskConvertible {
    case request(URLRequest)
    case resumeData(Data)
    
    func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
      do {
        let task: URLSessionTask
        
        switch self {
        case let .request(urlRequest):
          let urlRequest = try urlRequest.adapt(using: adapter)
          task = queue.sync { session.downloadTask(with: urlRequest) }
        case let .resumeData(resumeData):
          task = queue.sync { session.downloadTask(withResumeData: resumeData) }
        }
        
        return task
      } catch {
        throw AdaptError(error: error)
      }
    }
  }
  
  // MARK: Properties
  
  /// The request sent or to be sent to the server.
  open override var requesting: URLRequest? {
    if let requesting = super.requesting {
      return requesting
    }
    
    if let downloadable = originalTask as? Downloadable, case let .request(urlRequest) = downloadable {
      return urlRequest
    }
    
    return nil
  }
  
  /// The resume data of the underlying download task if available after a failure.
  open var resumeData: Data? { return downloadDelegate.resumeData }
  
  /// The progress of downloading the response data from the server for the request.
  open var progress: Progress { return downloadDelegate.progress }
  
  var downloadDelegate: DownloadTaskDelegate { return delegate as! DownloadTaskDelegate }
  
  // MARK: State
  
  /// Cancels the request.
  open override func cancel() {
    downloadDelegate.downloadTask.cancel { self.downloadDelegate.resumeData = $0 }
    
    NotificationCenter.default.post(
      name: Notification.Name.Task.didCancel,
      object: self,
      userInfo: [Notification.Key.task: task as Any]
    )
  }
  
  // MARK: Progress
  
  /// Sets a closure to be called periodically during the lifecycle of the `Request` as data is read from the server.
  ///
  /// - returns: The request.
  @discardableResult
  open func downloadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
    downloadDelegate.progressHandler = (closure, queue)
    return self
  }
  
  // MARK: Destination
  
  /// Creates a download file destination closure which uses the default file manager to move the temporary file to a
  /// file URL in the first available directory with the specified search path directory and search path domain mask.
  ///
  /// - returns: A download file destination closure.
  open class func suggestedDownloadDestination(
    for directory: FileManager.SearchPathDirectory = .documentDirectory,
    in domain: FileManager.SearchPathDomainMask = .userDomainMask)
    -> DownloadFileDestination
  {
    return { temporaryURL, response in
      let directoryURLs = FileManager.default.urls(for: directory, in: domain)
      
      if !directoryURLs.isEmpty {
        return (directoryURLs[0].appendingPathComponent(response.suggestedFilename!), [])
      }
      
      return (temporaryURL, [])
    }
  }
}

// MARK: -

/// Specific type of `Request` that manages an underlying `URLSessionUploadTask`.
open class UploadRequest: DataRequest {
  
  // MARK: Helper Types
  
  enum Uploadable: TaskConvertible {
    case data(Data, URLRequest)
    case file(URL, URLRequest)
    case stream(InputStream, URLRequest)
    
    func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
      do {
        let task: URLSessionTask
        
        switch self {
        case let .data(data, urlRequest):
          let urlRequest = try urlRequest.adapt(using: adapter)
          task = queue.sync { session.uploadTask(with: urlRequest, from: data) }
        case let .file(url, urlRequest):
          let urlRequest = try urlRequest.adapt(using: adapter)
          task = queue.sync { session.uploadTask(with: urlRequest, fromFile: url) }
        case let .stream(_, urlRequest):
          let urlRequest = try urlRequest.adapt(using: adapter)
          task = queue.sync { session.uploadTask(withStreamedRequest: urlRequest) }
        }
        
        return task
      } catch {
        throw AdaptError(error: error)
      }
    }
  }
  
  // MARK: Properties
  
  /// The request sent or to be sent to the server.
  open override var requesting: URLRequest? {
    if let request = super.requesting {
      return request
    }
    
    guard let uploadable = originalTask as? Uploadable else {
      return nil
    }
    
    switch uploadable {
    case .data(_, let urlRequest), .file(_, let urlRequest), .stream(_, let urlRequest):
      return urlRequest
    }
  }
  
  /// The progress of uploading the payload to the server for the upload requesting.
  open var uploadProgress: Progress { return uploadDelegate.uploadProgress }
  
  var uploadDelegate: UploadTaskDelegate { return delegate as! UploadTaskDelegate }
  
  // MARK: Upload Progress
  
  /// Sets a closure to be called periodically during the lifecycle of the `UploadRequest` as data is sent to
  /// the server.
  ///
  /// - returns: The requesting.
  @discardableResult
  open func uploadProgress(queue: DispatchQueue = DispatchQueue.main, closure: @escaping ProgressHandler) -> Self {
    uploadDelegate.uploadProgressHandler = (closure, queue)
    return self
  }
}

// MARK: -

#if !os(watchOS)
  
  /// Specific type of `Request` that manages an underlying `URLSessionStreamTask`.
  @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
  open class StreamRequest: Request {
    enum Streamable: TaskConvertible {
      case stream(hostName: String, port: Int)
      case netService(NetService)
      
      func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
        let task: URLSessionTask
        
        switch self {
        case let .stream(hostName, port):
          task = queue.sync { session.streamTask(withHostName: hostName, port: port) }
        case let .netService(netService):
          task = queue.sync { session.streamTask(with: netService) }
        }
        
        return task
      }
    }
  }
  
#endif

