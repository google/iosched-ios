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
import Domain

final class BookmarkRepository {

  private let remoteDataSource: RemoteBookmarkDataSource

  var bookmarkNotificationManager: BookmarkNotificationManager?
  private let sessionsRepository: SessionsRepository

  init(bookmarkNotificationManager: BookmarkNotificationManager? = nil, sessionsRepository: SessionsRepository) {
    self.bookmarkNotificationManager = bookmarkNotificationManager
    self.sessionsRepository = sessionsRepository
    remoteDataSource = RemoteBookmarkDataSource()
  }

  func addBookmark(for sessionId: String) {
    remoteDataSource.addBookmark(for: sessionId)
  }

  func removeBookmark(for sessionId: String) {
    remoteDataSource.removeBookmark(for: sessionId)
  }

  func purgeLocalBookmarks() {
    // This method doesn't do anything, since the cache is managed by Firestore.
  }

  func isBookmarked(sessionId: String) -> Bool {
    return remoteDataSource.isBookmarked(sessionId: sessionId)
  }

  func sync(_ completion: @escaping () -> Void = { }) {
    remoteDataSource.sync(completion)
  }

}

// MARK: - Bookmark notification handling

extension BookmarkRepository {

  func updateLocalNotifications(bookmarks: [BookmarkedSession]) {
    bookmarks.forEach { bookmark in
      if let session = self.sessionsRepository.session(byId: bookmark.id) {
        if bookmark.bookmarked {
          self.bookmarkNotificationManager?.scheduleNotification(for: session)
        }
        else {
          self.bookmarkNotificationManager?.cancelNotification(for: session)
        }
      }
    }
  }

}
