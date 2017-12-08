//
//  SessionDelegate.swift
//

import Foundation

/// Responsible for handling all delegate callbacks for the underlying session.
open class SessionDelegate: NSObject {
  
  // MARK: URLSessionDelegate Overrides
  
  /// Overrides default behavior for URLSessionDelegate method `urlSession(_:didBecomeInvalidWithError:)`.
  open var sessionDidBecomeInvalidWithError: ((URLSession, Error?) -> Void)?
  
  /// Overrides default behavior for URLSessionDelegate method `urlSession(_:didReceive:completionHandler:)`.
  open var sessionDidReceiveChallenge: ((URLSession, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
  
  /// Overrides all behavior for URLSessionDelegate method `urlSession(_:didReceive:completionHandler:)` and requires the caller to call the `completionHandler`.
  open var sessionDidReceiveChallengeWithCompletion: ((URLSession, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?
  
  /// Overrides default behavior for URLSessionDelegate method `urlSessionDidFinishEvents(forBackgroundURLSession:)`.
  open var sessionDidFinishEventsForBackgroundURLSession: ((URLSession) -> Void)?
  
  // MARK: URLSessionTaskDelegate Overrides
  
  /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)`.
  open var taskWillPerformHTTPRedirection: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest) -> URLRequest?)?
  
  /// Overrides all behavior for URLSessionTaskDelegate method `urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)` and
  /// requires the caller to call the `completionHandler`.
  open var taskWillPerformHTTPRedirectionWithCompletion: ((URLSession, URLSessionTask, HTTPURLResponse, URLRequest, @escaping (URLRequest?) -> Void) -> Void)?
  
  /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:didReceive:completionHandler:)`.
  open var taskDidReceiveChallenge: ((URLSession, URLSessionTask, URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition, URLCredential?))?
  
  /// Overrides all behavior for URLSessionTaskDelegate method `urlSession(_:task:didReceive:completionHandler:)` and
  /// requires the caller to call the `completionHandler`.
  open var taskDidReceiveChallengeWithCompletion: ((URLSession, URLSessionTask, URLAuthenticationChallenge, @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void)?
  
  /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:needNewBodyStream:)`.
  open var taskNeedNewBodyStream: ((URLSession, URLSessionTask) -> InputStream?)?
  
  /// Overrides all behavior for URLSessionTaskDelegate method `urlSession(_:task:needNewBodyStream:)` and
  /// requires the caller to call the `completionHandler`.
  open var taskNeedNewBodyStreamWithCompletion: ((URLSession, URLSessionTask, @escaping (InputStream?) -> Void) -> Void)?
  
  /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:)`.
  open var taskDidSendBodyData: ((URLSession, URLSessionTask, Int64, Int64, Int64) -> Void)?
  
  /// Overrides default behavior for URLSessionTaskDelegate method `urlSession(_:task:didCompleteWithError:)`.
  open var taskDidComplete: ((URLSession, URLSessionTask, Error?) -> Void)?
  
  // MARK: URLSessionDataDelegate Overrides
  
  /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didReceive:completionHandler:)`.
  open var dataTaskDidReceiveResponse: ((URLSession, URLSessionDataTask, URLResponse) -> URLSession.ResponseDisposition)?
  
  /// Overrides all behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didReceive:completionHandler:)` and
  /// requires caller to call the `completionHandler`.
  open var dataTaskDidReceiveResponseWithCompletion: ((URLSession, URLSessionDataTask, URLResponse, @escaping (URLSession.ResponseDisposition) -> Void) -> Void)?
  
  /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didBecome:)`.
  open var dataTaskDidBecomeDownloadTask: ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
  
  /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:didReceive:)`.
  open var dataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
  
  /// Overrides default behavior for URLSessionDataDelegate method `urlSession(_:dataTask:willCacheResponse:completionHandler:)`.
  open var dataTaskWillCacheResponse: ((URLSession, URLSessionDataTask, CachedURLResponse) -> CachedURLResponse?)?
  
  /// Overrides all behavior for URLSessionDataDelegate method `urlSession(_:dataTask:willCacheResponse:completionHandler:)` and
  /// requires caller to call the `completionHandler`.
  open var dataTaskWillCacheResponseWithCompletion: ((URLSession, URLSessionDataTask, CachedURLResponse, @escaping (CachedURLResponse?) -> Void) -> Void)?
  
  // MARK: URLSessionDownloadDelegate Overrides
  
  /// Overrides default behavior for URLSessionDownloadDelegate method `urlSession(_:downloadTask:didFinishDownloadingTo:)`.
  open var downloadTaskDidFinishDownloadingToURL: ((URLSession, URLSessionDownloadTask, URL) -> Void)?
  
  /// Overrides default behavior for URLSessionDownloadDelegate method `urlSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)`.
  open var downloadTaskDidWriteData: ((URLSession, URLSessionDownloadTask, Int64, Int64, Int64) -> Void)?
  
  /// Overrides default behavior for URLSessionDownloadDelegate method `urlSession(_:downloadTask:didResumeAtOffset:expectedTotalBytes:)`.
  open var downloadTaskDidResumeAtOffset: ((URLSession, URLSessionDownloadTask, Int64, Int64) -> Void)?
  
  // MARK: URLSessionStreamDelegate Overrides
  
  #if !os(watchOS)
  
  /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:readClosedFor:)`.
  @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
  open var streamTaskReadClosed: ((URLSession, URLSessionStreamTask) -> Void)? {
    get {
      return streamTaskReadClosed2 as? (URLSession, URLSessionStreamTask) -> Void
    }
    set {
      streamTaskReadClosed2 = newValue
    }
  }
  
  /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:writeClosedFor:)`.
  @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
  open var streamTaskWriteClosed: ((URLSession, URLSessionStreamTask) -> Void)? {
    get {
      return streamTaskWriteClosed2 as? (URLSession, URLSessionStreamTask) -> Void
    }
    set {
      streamTaskWriteClosed2 = newValue
    }
  }
  
  /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:betterRouteDiscoveredFor:)`.
  @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
  open var streamTaskBetterRouteDiscovered: ((URLSession, URLSessionStreamTask) -> Void)? {
    get {
      return streamTaskBetterRouteDiscovered2 as? (URLSession, URLSessionStreamTask) -> Void
    }
    set {
      streamTaskBetterRouteDiscovered2 = newValue
    }
  }
  
  /// Overrides default behavior for URLSessionStreamDelegate method `urlSession(_:streamTask:didBecome:outputStream:)`.
  @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
  open var streamTaskDidBecomeInputAndOutputStreams: ((URLSession, URLSessionStreamTask, InputStream, OutputStream) -> Void)? {
    get {
      return streamTaskDidBecomeInputStream2 as? (URLSession, URLSessionStreamTask, InputStream, OutputStream) -> Void
    }
    set {
      streamTaskDidBecomeInputStream2 = newValue
    }
  }
  
  var streamTaskReadClosed2: Any?
  var streamTaskWriteClosed2: Any?
  var streamTaskBetterRouteDiscovered2: Any?
  var streamTaskDidBecomeInputStream2: Any?
  
  #endif
  
  // MARK: Properties
  
  var retrier: RequestRetrier?
  weak var sessionManager: SessionManager?
  
  private var requests: [Int: Request] = [:]
  private let lock = NSLock()
  
  /// Access the task delegate for the specified task in a thread-safe manner.
  open subscript(task: URLSessionTask) -> Request? {
    get {
      lock.lock()
      defer {
        lock.unlock()
      }
      return requests[task.taskIdentifier]
    }
    set {
      lock.lock()
      defer {
        lock.unlock()
      }
      requests[task.taskIdentifier] = newValue
    }
  }
  
  // MARK: Lifecycle
  
  /// Initializes the `SessionDelegate` instance.
  ///
  /// - returns: The new `SessionDelegate` instance.
  public override init() {
    super.init()
  }
  
  // MARK: NSObject Overrides
  
  /// Returns a `Bool` indicating whether the `SessionDelegate` implements or inherits a method that can respond
  /// to a specified message.
  ///
  /// - returns: `true` if the receiver implements or inherits a method that can respond to selector, otherwise `false`.
  open override func responds(to selector: Selector) -> Bool {
    #if !os(macOS)
      if selector == #selector(URLSessionDelegate.urlSessionDidFinishEvents(forBackgroundURLSession:)) {
        return sessionDidFinishEventsForBackgroundURLSession != nil
      }
    #endif
    
    #if !os(watchOS)
      if #available(iOS 9.0, macOS 10.11, tvOS 9.0, *) {
        switch selector {
        case #selector(URLSessionStreamDelegate.urlSession(_:readClosedFor:)):
          return streamTaskReadClosed != nil
        case #selector(URLSessionStreamDelegate.urlSession(_:writeClosedFor:)):
          return streamTaskWriteClosed != nil
        case #selector(URLSessionStreamDelegate.urlSession(_:betterRouteDiscoveredFor:)):
          return streamTaskBetterRouteDiscovered != nil
        case #selector(URLSessionStreamDelegate.urlSession(_:streamTask:didBecome:outputStream:)):
          return streamTaskDidBecomeInputAndOutputStreams != nil
        default:
          break
        }
      }
    #endif
    
    switch selector {
    case #selector(URLSessionDelegate.urlSession(_:didBecomeInvalidWithError:)):
      return sessionDidBecomeInvalidWithError != nil
    case #selector(URLSessionDelegate.urlSession(_:didReceive:completionHandler:)):
      return (sessionDidReceiveChallenge != nil  || sessionDidReceiveChallengeWithCompletion != nil)
    case #selector(URLSessionTaskDelegate.urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)):
      return (taskWillPerformHTTPRedirection != nil || taskWillPerformHTTPRedirectionWithCompletion != nil)
    case #selector(URLSessionDataDelegate.urlSession(_:dataTask:didReceive:completionHandler:)):
      return (dataTaskDidReceiveResponse != nil || dataTaskDidReceiveResponseWithCompletion != nil)
    default:
      return type(of: self).instancesRespond(to: selector)
    }
  }
}

// MARK: - URLSessionDelegate

extension SessionDelegate: URLSessionDelegate {
  /// Tells the delegate that the session has been invalidated.
  ///
  /// - parameter error:   The error that caused invalidation, or nil if the invalidation was explicit.
  open func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
    sessionDidBecomeInvalidWithError?(session, error)
  }
  
  /// Requests credentials from the delegate in response to a session-level authentication request from the
  /// remote server.
  ///
  open func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
    guard sessionDidReceiveChallengeWithCompletion == nil else {
      sessionDidReceiveChallengeWithCompletion?(session, challenge, completionHandler)
      return
    }
    
    var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
    var credential: URLCredential?
    
    if let sessionDidReceiveChallenge = sessionDidReceiveChallenge {
      (disposition, credential) = sessionDidReceiveChallenge(session, challenge)
    } else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
      let host = challenge.protectionSpace.host
      
      if
        let serverTrustPolicy = session.serverTrustPolicyManager?.serverTrustPolicy(forHost: host),
        let serverTrust = challenge.protectionSpace.serverTrust
      {
        if serverTrustPolicy.evaluate(serverTrust, forHost: host) {
          disposition = .useCredential
          credential = URLCredential(trust: serverTrust)
        } else {
          disposition = .cancelAuthenticationChallenge
        }
      }
    }
    
    completionHandler(disposition, credential)
  }
  
  #if !os(macOS)
  
  /// Tells the delegate that all messages enqueued for a session have been delivered.
  ///
  /// - parameter session: The session that no longer has any outstanding requests.
  open func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
    sessionDidFinishEventsForBackgroundURLSession?(session)
  }
  
  #endif
}

// MARK: - URLSessionTaskDelegate

extension SessionDelegate: URLSessionTaskDelegate {
  /// Tells the delegate that the remote server requested an HTTP redirect.
  ///
  open func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void)
  {
    guard taskWillPerformHTTPRedirectionWithCompletion == nil else {
      taskWillPerformHTTPRedirectionWithCompletion?(session, task, response, request, completionHandler)
      return
    }
    
    var redirectRequest: URLRequest? = request
    
    if let taskWillPerformHTTPRedirection = taskWillPerformHTTPRedirection {
      redirectRequest = taskWillPerformHTTPRedirection(session, task, response, request)
    }
    
    completionHandler(redirectRequest)
  }
  
  /// Requests credentials from the delegate in response to an authentication request from the remote server.
  ///
  open func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
  {
    guard taskDidReceiveChallengeWithCompletion == nil else {
      taskDidReceiveChallengeWithCompletion?(session, task, challenge, completionHandler)
      return
    }
    
    if let taskDidReceiveChallenge = taskDidReceiveChallenge {
      let result = taskDidReceiveChallenge(session, task, challenge)
      completionHandler(result.0, result.1)
    } else if let delegate = self[task]?.delegate {
      delegate.urlSession(
        session,
        task: task,
        didReceive: challenge,
        completionHandler: completionHandler
      )
    } else {
      urlSession(session, didReceive: challenge, completionHandler: completionHandler)
    }
  }
  
  /// Tells the delegate when a task requires a new request body stream to send to the remote server.
  ///
  open func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    needNewBodyStream completionHandler: @escaping (InputStream?) -> Void)
  {
    guard taskNeedNewBodyStreamWithCompletion == nil else {
      taskNeedNewBodyStreamWithCompletion?(session, task, completionHandler)
      return
    }
    
    if let taskNeedNewBodyStream = taskNeedNewBodyStream {
      completionHandler(taskNeedNewBodyStream(session, task))
    } else if let delegate = self[task]?.delegate {
      delegate.urlSession(session, task: task, needNewBodyStream: completionHandler)
    }
  }
  
  /// Periodically informs the delegate of the progress of sending body content to the server.
  ///
  open func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didSendBodyData bytesSent: Int64,
    totalBytesSent: Int64,
    totalBytesExpectedToSend: Int64)
  {
    if let taskDidSendBodyData = taskDidSendBodyData {
      taskDidSendBodyData(session, task, bytesSent, totalBytesSent, totalBytesExpectedToSend)
    } else if let delegate = self[task]?.delegate as? UploadTaskDelegate {
      delegate.urlSession2(
        session,
        task: task,
        didSendBodyData: bytesSent,
        totalBytesSent: totalBytesSent,
        totalBytesExpectedToSend: totalBytesExpectedToSend
      )
    }
  }
  
  #if !os(watchOS)
  
  /// Tells the delegate that the session finished collecting metrics for the task.
  ///
  @available(iOS 10.0, macOS 10.12, tvOS 10.0, *)
  @objc(URLSession:task:didFinishCollectingMetrics:)
  open func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
    self[task]?.delegate.metrics = metrics
  }
  
  #endif
  
  /// Tells the delegate that the task finished transferring data.
  ///
  open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    /// Executed after it is determined that the request is not going to be retried
    let completeTask: (URLSession, URLSessionTask, Error?) -> Void = { [weak self] session, task, error in
      guard let strongSelf = self else { return }
      
      strongSelf.taskDidComplete?(session, task, error)
      
      strongSelf[task]?.delegate.urlSession(session, task: task, didCompleteWithError: error)
      
      NotificationCenter.default.post(
        name: Notification.Name.Task.didComplete,
        object: strongSelf,
        userInfo: [Notification.Key.task: task]
      )
      
      strongSelf[task] = nil
    }
    
    guard let request = self[task], let sessionManager = sessionManager else {
      completeTask(session, task, error)
      return
    }
    
    // Run all validations on the request before checking if an error occurred
    request.validations.forEach { $0() }
    
    // Determine whether an error has occurred
    var error: Error? = error
    
    if request.delegate.error != nil {
      error = request.delegate.error
    }
    
    /// If an error occurred and the retrier is set, asynchronously ask the retrier if the request
    /// should be retried. Otherwise, complete the task by notifying the task delegate.
    if let retrier = retrier, let error = error {
      retrierLint(retrier: retrier, error: error, sessionManager: sessionManager, request: request, session: session, task: task, completeTask: completeTask)
    } else {
      completeTask(session, task, error)
    }
  }
  
  
  //Fix for SonarQ
  func retrierLint(retrier: RequestRetrier, error: Error, sessionManager: SessionManager, request: Request, session: URLSession, task: URLSessionTask, completeTask: @escaping (URLSession, URLSessionTask, Error?)->Void) {
    
    retrier.should(sessionManager, retry: request, with: error) { [weak self] shouldRetry, timeDelay in
      guard shouldRetry else {
        completeTask(session, task, error)
        return
      }
      
      DispatchQueue.utility.after(timeDelay) { [weak self] in
        guard let strongSelf = self else { return }
        
        let retrySucceeded = strongSelf.sessionManager?.retry(request) ?? false
        
        if retrySucceeded, let task = request.task {
          strongSelf[task] = request
          return
        } else {
          completeTask(session, task, error)
        }
      }
    }
    
  }
}

// MARK: - URLSessionDataDelegate

extension SessionDelegate: URLSessionDataDelegate {
  /// Tells the delegate that the data task received the initial reply (headers) from the server.
  ///
  open func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
  {
    guard dataTaskDidReceiveResponseWithCompletion == nil else {
      dataTaskDidReceiveResponseWithCompletion?(session, dataTask, response, completionHandler)
      return
    }
    
    var disposition: URLSession.ResponseDisposition = .allow
    
    if let dataTaskDidReceiveResponse = dataTaskDidReceiveResponse {
      disposition = dataTaskDidReceiveResponse(session, dataTask, response)
    }
    
    completionHandler(disposition)
  }
  
  /// Tells the delegate that the data task was changed to a download task.
  ///
  open func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didBecome downloadTask: URLSessionDownloadTask)
  {
    if let dataTaskDidBecomeDownloadTask = dataTaskDidBecomeDownloadTask {
      dataTaskDidBecomeDownloadTask(session, dataTask, downloadTask)
    } else {
      self[downloadTask]?.delegate = DownloadTaskDelegate(task: downloadTask)
    }
  }
  
  /// Tells the delegate that the data task has received some of the expected data.
  ///
  open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    if let dataTaskDidReceiveData = dataTaskDidReceiveData {
      dataTaskDidReceiveData(session, dataTask, data)
    } else if let delegate = self[dataTask]?.delegate as? DataTaskDelegate {
      delegate.urlSession(session, dataTask: dataTask, didReceive: data)
    }
  }
  
  /// Asks the delegate whether the data (or upload) task should store the response in the cache.
  ///
  open func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    willCacheResponse proposedResponse: CachedURLResponse,
    completionHandler: @escaping (CachedURLResponse?) -> Void)
  {
    guard dataTaskWillCacheResponseWithCompletion == nil else {
      dataTaskWillCacheResponseWithCompletion?(session, dataTask, proposedResponse, completionHandler)
      return
    }
    
    if let dataTaskWillCacheResponse = dataTaskWillCacheResponse {
      completionHandler(dataTaskWillCacheResponse(session, dataTask, proposedResponse))
    } else if let delegate = self[dataTask]?.delegate as? DataTaskDelegate {
      delegate.urlSession(
        session,
        dataTask: dataTask,
        willCacheResponse: proposedResponse,
        completionHandler: completionHandler
      )
    } else {
      completionHandler(proposedResponse)
    }
  }
}

// MARK: - URLSessionDownloadDelegate

extension SessionDelegate: URLSessionDownloadDelegate {
  /// Tells the delegate that a download task has finished downloading.
  ///
  open func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didFinishDownloadingTo location: URL)
  {
    if let downloadTaskDidFinishDownloadingToURL = downloadTaskDidFinishDownloadingToURL {
      downloadTaskDidFinishDownloadingToURL(session, downloadTask, location)
    } else if let delegate = self[downloadTask]?.delegate as? DownloadTaskDelegate {
      delegate.urlSession(session, downloadTask: downloadTask, didFinishDownloadingTo: location)
    }
  }
  
  /// Periodically informs the delegate about the download’s progress.
  ///
  open func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didWriteData bytesWritten: Int64,
    totalBytesWritten: Int64,
    totalBytesExpectedToWrite: Int64)
  {
    if let downloadTaskDidWriteData = downloadTaskDidWriteData {
      downloadTaskDidWriteData(session, downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)
    } else if let delegate = self[downloadTask]?.delegate as? DownloadTaskDelegate {
      delegate.urlSession(
        session,
        downloadTask: downloadTask,
        didWriteData: bytesWritten,
        totalBytesWritten: totalBytesWritten,
        totalBytesExpectedToWrite: totalBytesExpectedToWrite
      )
    }
  }
  
  /// Tells the delegate that the download task has resumed downloading.
  ///
  open func urlSession(
    _ session: URLSession,
    downloadTask: URLSessionDownloadTask,
    didResumeAtOffset fileOffset: Int64,
    expectedTotalBytes: Int64)
  {
    if let downloadTaskDidResumeAtOffset = downloadTaskDidResumeAtOffset {
      downloadTaskDidResumeAtOffset(session, downloadTask, fileOffset, expectedTotalBytes)
    } else if let delegate = self[downloadTask]?.delegate as? DownloadTaskDelegate {
      delegate.urlSession(
        session,
        downloadTask: downloadTask,
        didResumeAtOffset: fileOffset,
        expectedTotalBytes: expectedTotalBytes
      )
    }
  }
}

// MARK: - URLSessionStreamDelegate

#if !os(watchOS)
  
  @available(iOS 9.0, macOS 10.11, tvOS 9.0, *)
  extension SessionDelegate: URLSessionStreamDelegate {
    /// Tells the delegate that the read side of the connection has been closed.
    ///
    open func urlSession(_ session: URLSession, readClosedFor streamTask: URLSessionStreamTask) {
      streamTaskReadClosed?(session, streamTask)
    }
    
    /// Tells the delegate that the write side of the connection has been closed.
    ///
    open func urlSession(_ session: URLSession, writeClosedFor streamTask: URLSessionStreamTask) {
      streamTaskWriteClosed?(session, streamTask)
    }
    
    /// Tells the delegate that the system has determined that a better route to the host is available.
    ///
    open func urlSession(_ session: URLSession, betterRouteDiscoveredFor streamTask: URLSessionStreamTask) {
      streamTaskBetterRouteDiscovered?(session, streamTask)
    }
    
    /// Tells the delegate that the stream task has been completed and provides the unopened stream objects.
    ///
    open func urlSession(
      _ session: URLSession,
      streamTask: URLSessionStreamTask,
      didBecome inputStream: InputStream,
      outputStream: OutputStream)
    {
      streamTaskDidBecomeInputAndOutputStreams?(session, streamTask, inputStream, outputStream)
    }
  }
  
#endif
