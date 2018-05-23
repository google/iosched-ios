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

protocol BookmarkDataSource {

  /// Bookmark a session
  func addBookmark(for sessionId: String)

  /// Remove bookmark for a session
  func removeBookmark(for sessionId: String)

  /// Retrieve all bookmarks stored in this data source
  func retrieveBookmarks(_ callback: @escaping (_ bookmarks: [BookmarkedSession]) -> Void)

}

protocol BatchUpdatingBookmarkDataSource {
  func saveBookmark(bookmark: BookmarkedSession)

  /// Store all given bookmarks
  func saveBookmarks(bookmarks: [BookmarkedSession])
}

extension BatchUpdatingBookmarkDataSource {
  func saveBookmarks(bookmarks: [BookmarkedSession]) {
    for bookmark in bookmarks {
      saveBookmark(bookmark: bookmark)
    }
  }
}

protocol LocalBookmarkDataSource: BookmarkDataSource {

  /// Determine whether a given session is bookmarked or not
  func isBookmarked(sessionId: String) -> Bool

}

protocol PurgeableBookmarkDataSource: BookmarkDataSource {

  /// Clear all bookmarks, if supported by the datasource
  func purgeBookmarks()

}
