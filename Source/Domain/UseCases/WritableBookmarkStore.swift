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

// Constants for NotificationCenter updates
public enum BookmarkUpdates {
  public static let sessionId = "sessionId"
  public static let isBookmarked = "isBookmarked"
}

public extension Notification.Name {
  public static let bookmarkUpdate = Notification.Name("bookmarkUpdate")
}

public protocol WritableBookmarkStore {
  func toggleBookmark(sessionId: String)
  func isBookmarked(sessionId: String) -> Bool
  func purgeLocalBookmarks()
  func sync()
  func sync(_ completion: (() -> Void)?)
}
