//
//  Copyright (c) 2017 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// A data source that wraps an AutoUpdatingConferenceData type and provides lazy updates.
/// This type exists to limit too many callback invocations from happening in views
/// that are not currently being displayed. Since I/O schedule data does not change
/// very often, this type defers the update-pulling to the views that consume it and ensures
/// that updates are pulled immediately since the AutoUpdatingConferenceData has already
/// downloaded the changes into memory.
/// - SeeAlso: DefaultLazyReadonlySessionsDataSource
public protocol LazyReadonlySessionsDataSource {

  /// The list of all sessions.
  var sessions: [Session] { get }

  /// The session for a provided session ID, or nil if it doesn't exist.
  subscript(id: String) -> Session? { get }

  /// A pseudorandom session ID from the list of all sessions, or nil if
  /// there are currently no sessions in the data source.
  func randomSessionId() -> String?

  /// Updates the data source's sessions from memory. Returns immediately and is not
  /// asynchronous, so callers can assume that the data source contains the latest data
  /// immediately after invoking this method. Types that implement this protocol should
  /// be careful to avoid side effects beyond updating internal state in this method, since
  /// it may be called by other initializers.
  func update()

}

public class DefaultLazyReadonlySessionsDataSource: LazyReadonlySessionsDataSource {

  fileprivate var dataSource: AutoUpdatingConferenceData
  fileprivate var sessionsMap = [String: Session]()

  public init(dataSource: AutoUpdatingConferenceData) {
    self.dataSource = dataSource
    syncWithDataSource()
  }

  public func update() {
    syncWithDataSource()
  }
}

// MARK: - Accessing elements

extension DefaultLazyReadonlySessionsDataSource {
  public var sessions: [Session] {
    /// Returns locally stored values, since the list of sessions in the data source
    /// may have changed.
    return Array(sessionsMap.values)
  }

  public subscript(id: String) -> Session? {
    return sessionsMap[id]
  }

  public func randomSessionId() -> String? {
    return sessions.randomElement()?.id
  }

}

// MARK: - Updating elements from the data source

extension DefaultLazyReadonlySessionsDataSource {

  /// Overwrites the DefaultSessionRepository's local sessions with sessions from the
  /// data source. This method is called on init, so it must not have any side effects.
  /// (besides print and mutating local properties)
  fileprivate func syncWithDataSource() {
    guard !dataSource.conference.isEmpty else {
      print("Repository didn't get any conference data. Not updating repository state.")
      return
    }

    sessionsMap.removeAll()
    dataSource.conference.forEach { session in
      sessionsMap[session.id] = session
    }
  }
}
