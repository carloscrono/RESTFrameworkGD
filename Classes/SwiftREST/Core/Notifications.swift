//
//  Notifications.swift
//
//

import Foundation

extension Notification.Name {
    /// Used as a namespace for all `URLSessionTask` related notifications.
    public struct Task {
        /// Posted when a `URLSessionTask` is resumed. The notification `object` contains the resumed `URLSessionTask`.
        public static let DidResume = Notification.Name(rawValue: "com.SwiftREST.notification.name.task.didResume")

        /// Posted when a `URLSessionTask` is suspended. The notification `object` contains the suspended `URLSessionTask`.
        public static let DidSuspend = Notification.Name(rawValue: "com.SwiftREST.notification.name.task.didSuspend")

        /// Posted when a `URLSessionTask` is cancelled. The notification `object` contains the cancelled `URLSessionTask`.
        public static let DidCancel = Notification.Name(rawValue: "com.SwiftREST.notification.name.task.didCancel")

        /// Posted when a `URLSessionTask` is completed. The notification `object` contains the completed `URLSessionTask`.
        public static let DidComplete = Notification.Name(rawValue: "com.SwiftREST.notification.name.task.didComplete")
    }
}

// MARK: -

extension Notification {
    /// Used as a namespace for all `Notification` user info dictionary keys.
    public struct Key {
        /// User info dictionary key representing the `URLSessionTask` associated with the notification.
        public static let Task = "com.SwiftREST.notification.key.task"
    }
}
