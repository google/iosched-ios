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

final class DefaultWritableBookmarkStore: WritableBookmarkStore {

  private let repository: BookmarkRepository
  private let userState: WritableUserState
  private let bookmarkNotificationManager: BookmarkNotificationManager
  private let sessionsRepository: SessionsRepository

  init(_ repository: BookmarkRepository,
       sessionsRepository: SessionsRepository,
       userState: WritableUserState,
       bookmarkNotificationManager: BookmarkNotificationManager) {
    self.repository = repository
    self.sessionsRepository = sessionsRepository
    self.userState = userState
    self.bookmarkNotificationManager = bookmarkNotificationManager
  }

  func toggleBookmark(sessionId: String) {
    guard let session = sessionsRepository.session(byId: sessionId) else {
      print("Session \(sessionId) not found. Can't set bookmark.")
      return
    }
    self.toggleBookmark(session: session)
  }

  func toggleBookmark(session: Session) {
    if repository.isBookmarked(sessionId: session.id) {
      repository.removeBookmark(for: session.id)
      update(sessionId: session.id, bookmarked: false)
      bookmarkNotificationManager.cancelNotification(for: session)
    }
    else {
      repository.addBookmark(for: session.id)
      update(sessionId: session.id, bookmarked: true)
      bookmarkNotificationManager.scheduleNotification(for: session)
    }
  }

  func isBookmarked(sessionId: String) -> Bool {
    return repository.isBookmarked(sessionId: sessionId)
  }

  func purgeLocalBookmarks() {
    repository.purgeLocalBookmarks()
    update()
  }

  func sync() {
    sync { }
  }

  func sync(_ completion: (() -> Void)?) {
    repository.sync {
      self.update()
      completion?()
    }
  }

  // MARK: - Publishing updates
  func update(sessionId: String, bookmarked: Bool) {
    NotificationCenter.default.post(name: .bookmarkUpdate,
                                    object: nil,
                                    userInfo: [
                                      BookmarkUpdates.sessionId: sessionId,
                                      BookmarkUpdates.isBookmarked: bookmarked
                                    ])
  }

  func update() {
    NotificationCenter.default.post(name: .bookmarkUpdate,
                                    object: nil,
                                    userInfo: [:])
  }

}
