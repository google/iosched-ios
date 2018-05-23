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
import GoogleSignIn
import GTMSessionFetcher

import FirebaseFirestore
import FirebaseAuth

/// Fetches bookmarks from Firestore, but does not keep them synchronized.
/// Call the `sync` method to synchronize bookmarks.
class RemoteBookmarkDataSource {

  private let firestore: Firestore
  private let auth: Auth

  private var listener: ListenerRegistration? {
    willSet {
      listener?.remove()
    }
  }

  private(set) var bookmarks: [String: BookmarkedSession] = [:]

  init(firestore: Firestore = Firestore.firestore(), auth: Auth = Auth.auth()) {
    self.firestore = firestore
    self.auth = auth
  }

  deinit {
    listener = nil
  }

  // MARK: - BookmarkDataSource

  func addBookmark(for sessionId: String) {
    setBookmarked(sessionId: sessionId, bookmarked: true)
  }

  func removeBookmark(for sessionId: String) {
    setBookmarked(sessionId: sessionId, bookmarked: false)
  }

  func setBookmarked(sessionId: String, bookmarked: Bool) {
    guard let user = auth.currentUser else { return }

    // It's ok for this to be out-of-sync with Firestore; fetched updates from
    // Firestore overwrite locally cached changes.
    let bookmark = BookmarkedSession(id: sessionId, bookmarked: bookmarked)
    self.bookmarks[sessionId] = bookmark

    let userEvent = firestore.userEvent(for: user, withSessionID: sessionId)

    let setOptions = SetOptions.merge()
    userEvent.setData([
      "eventId": sessionId,
      "isStarred": bookmarked
    ], options: setOptions) { error in
      if let error = error {
        print("Error writing bookmark to \(self.firestore): \(error)")
      }
    }
  }

  func isBookmarked(sessionId: String) -> Bool {
    return bookmarks[sessionId]?.bookmarked ?? false
  }

  func retrieveBookmarks(_ callback: @escaping (_ bookmarks: [BookmarkedSession]) -> Void) {
    guard let user = auth.currentUser else { return }

    let bookmarksQuery = firestore.userEvents(for: user).whereField("isStarred", isEqualTo: true)
    listener = bookmarksQuery.addSnapshotListener { [weak self] (querySnapshot, error) in
      guard let snapshot = querySnapshot else {
        print("Error fetching bookmarks: \(error!)")
        callback([])
        return
      }

      let bookmarks = snapshot.documents.map { document -> BookmarkedSession? in
        let data = document.data()
        guard let id = data["eventId"] as? String else { return nil }
        return BookmarkedSession(id: id, bookmarked: true)
      }
      .filter({ $0 != nil })
      .map({ $0! })

      for bookmark in bookmarks {
        self?.bookmarks[bookmark.id] = bookmark
      }
      callback(bookmarks)
    }
  }

  // MARK: Remote updates

  func sync(_ completion: @escaping () -> Void = { }) {
    retrieveBookmarks { _ in
      completion()
    }
  }

}

// MARK: - BatchUpdatingBookmarkDataSource

extension RemoteBookmarkDataSource: BatchUpdatingBookmarkDataSource {

  func saveBookmarks(bookmarks: [BookmarkedSession]) {

  }

  func saveBookmark(bookmark: BookmarkedSession) {

  }
}
