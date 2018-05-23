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
import GoogleSignIn
import GTMSessionFetcher

import FirebaseFirestore
import FirebaseAuth

/// Fetches bookmarks from Firestore, but does not keep them synchronized.
/// Call the `sync` method to synchronize bookmarks.
public class RemoteBookmarkDataSource {

  private let firestore: Firestore
  private let signIn: SignInInterface

  private var listener: ListenerRegistration? {
    willSet {
      listener?.remove()
    }
  }

  private(set) var bookmarks: [String: BookmarkedSession] = [:]

  public init(firestore: Firestore = Firestore.firestore(),
              signIn: SignInInterface = SignIn.sharedInstance) {
    self.firestore = firestore
    self.signIn = signIn

    observeSignInUpdates()
  }

  deinit {
    listener = nil
    stopObservingSignInUpdates()
    stopSyncingBookmarks()
  }

  // MARK: - BookmarkDataSource

  public func addBookmark(for sessionID: String) {
    setBookmarked(sessionID: sessionID, bookmarked: true)
  }

  public func removeBookmark(for sessionID: String) {
    setBookmarked(sessionID: sessionID, bookmarked: false)
  }

  public func setBookmarked(sessionID: String, bookmarked: Bool) {
    guard let user = signIn.currentUpgradableUser else { return }

    // It's ok for this to be out-of-sync with Firestore; fetched updates from
    // Firestore overwrite locally cached changes.
    let bookmark = BookmarkedSession(id: sessionID, bookmarked: bookmarked)
    self.bookmarks[sessionID] = bookmark

    let userEvent = firestore.userEvent(for: user, withSessionID: sessionID)

    userEvent.setData([
      "eventId": sessionID,
      "isStarred": bookmarked
    ], merge: true) { error in
      if let error = error {
        print("Error writing bookmark to \(self.firestore): \(error)")
      }
    }
  }

  public func toggleBookmark(sessionID: String) {
    if isBookmarked(sessionID: sessionID) {
      removeBookmark(for: sessionID)
    } else {
      addBookmark(for: sessionID)
    }
  }

  public func isBookmarked(sessionID: String) -> Bool {
    return bookmarks[sessionID]?.bookmarked ?? false
  }

  /// Used to keep track of an active listener when auth status changes.
  private var syncCallback: (([BookmarkedSession]) -> Void)?

  public func syncBookmarks(_ callback: @escaping (_ bookmarks: [BookmarkedSession]) -> Void) {
    syncCallback = callback
    guard let user = signIn.currentUpgradableUser else { return }

    let bookmarksQuery = firestore.userEvents(for: user).whereField("isStarred", isEqualTo: true)
    listener = bookmarksQuery.addSnapshotListener { [weak self] (querySnapshot, error) in
      defer {
        NotificationCenter.default.post(name: .bookmarkUpdate, object: nil)
      }
      guard let self = self, let snapshot = querySnapshot else {
        if let error = error {
          print("Error fetching bookmarks: \(error)")
        }
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

      self.bookmarks.removeAll()
      for bookmark in bookmarks {
        self.bookmarks[bookmark.id] = bookmark
      }
      callback(bookmarks)
    }
  }

  public func stopSyncingBookmarks() {
    listener = nil
    syncCallback = nil
    self.bookmarks.removeAll()
  }

  // MARK: - SignIn listeners

  private var authChangeHandle: Any?
  private var signInHandle: Any?
  private var signOutHandle: Any?

  private func onSignIn() {
    guard let callback = syncCallback else { return }
    self.syncBookmarks(callback)
  }

  private func onSignOut() {
    self.listener = nil
    self.bookmarks = [:]
    self.syncCallback?([])
  }

  private func observeSignInUpdates() {
    authChangeHandle = signIn.addAnonymousAuthStateHandler { [weak self] user in
      guard let self = self else { return }
      if user != nil {
        self.onSignIn()
      } else {
        self.onSignOut()
      }
    }
    signInHandle = signIn.addGoogleSignInHandler(self) { [weak self] in
      guard let self = self else { return }
      self.onSignIn()
    }
    signOutHandle = signIn.addGoogleSignOutHandler(self) { [weak self] in
      guard let self = self else { return }
      self.onSignOut()
    }
  }

  private func stopObservingSignInUpdates() {
    if let handle = authChangeHandle {
      signIn.removeAnonymousAuthStateHandler(handle)
    }
    if let handle = signInHandle {
      signIn.removeGoogleSignInHandler(handle)
    }
    if let handle = signOutHandle {
      signIn.removeGoogleSignOutHandler(handle)
    }
  }

}

extension NSNotification.Name {

  static let bookmarkUpdate = NSNotification.Name("com.google.iosched.bookmarkUpdate")

}
