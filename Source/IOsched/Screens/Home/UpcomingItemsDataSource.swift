//
//  Copyright (c) 2019 Google Inc.
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

import UIKit

@objc public class UpcomingItemsDataSource: NSObject, UICollectionViewDataSource,
UICollectionViewDelegate {

  private let reservationDataSource: RemoteReservationDataSource
  private let bookmarkDataSource: RemoteBookmarkDataSource
  private let sessionsDataSource: LazyReadonlySessionsDataSource
  private let navigator: ScheduleNavigator
  let rootNavigator: RootNavigator

  /// Called each time the data source's data changes.
  public var updateHandler: ((UpcomingItemsDataSource) -> Void)?

  public init(reservations: RemoteReservationDataSource = RemoteReservationDataSource(),
              bookmarks: RemoteBookmarkDataSource = RemoteBookmarkDataSource(),
              sessions: LazyReadonlySessionsDataSource,
              scheduleNavigator: ScheduleNavigator,
              rootNavigator: RootNavigator) {
    reservationDataSource = reservations
    bookmarkDataSource = bookmarks
    sessionsDataSource = sessions
    navigator = scheduleNavigator
    self.rootNavigator = rootNavigator
    super.init()

    registerForUpdates()
  }

  lazy private(set) var upcomingEvents: [Session] = buildUpcomingEvents()

  private func buildUpcomingEvents() -> [Session] {
    let currentTimestamp = Date()
    var userAgenda: [Session] = []
    for reservedSession in reservationDataSource.reservedSessions where
      reservedSession.status == .reserved {
        if let session = sessionsDataSource[reservedSession.id],
          session.startTimestamp > currentTimestamp {
          userAgenda.append(session)
        }
    }
    for bookmarkedSessionID in bookmarkDataSource.bookmarks.keys where
      bookmarkDataSource.isBookmarked(sessionID: bookmarkedSessionID) {
        // Don't duplicate reserved/waitlisted and bookmarked sessions here.
        if reservationDataSource.reservationStatus(for: bookmarkedSessionID) != .reserved,
          let session = sessionsDataSource[bookmarkedSessionID],
          session.startTimestamp > currentTimestamp {
          userAgenda.append(session)
        }
    }
    return userAgenda.sorted { (lhs, rhs) -> Bool in
      return lhs.startTimestamp < rhs.startTimestamp
    }
  }

  func reloadData() {
    upcomingEvents = buildUpcomingEvents()
    updateHandler?(self)
  }

  private func registerForUpdates() {
    reservationDataSource.observeReservationUpdates { [weak self] (_, _) in
      self?.reloadData()
    }
    bookmarkDataSource.syncBookmarks { [weak self] (_) in
      self?.reloadData()
    }
  }

  private func unregisterForUpdates() {
    reservationDataSource.stopObservingUpdates()
    bookmarkDataSource.stopSyncingBookmarks()
  }

  deinit {
    unregisterForUpdates()
  }

  public var isEmpty: Bool {
    return upcomingEvents.isEmpty
  }

  // MARK: - UICollectionViewDataSource

  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    return upcomingEvents.count
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: UpcomingItemCollectionViewCell.reuseIdentifier(),
      for: indexPath
    ) as! UpcomingItemCollectionViewCell
    let session = upcomingEvents[indexPath.item]
    let isReserved = reservationDataSource.reservationStatus(for: session.id) == .reserved
    let isBookmarked = bookmarkDataSource.isBookmarked(sessionID: session.id)

    cell.populate(session: session, isReserved: isReserved, isBookmarked: isBookmarked)
    return cell
  }

  // MARK: - UICollectionViewDelegate

  public func collectionView(_ collectionView: UICollectionView,
                             didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)
    let session = upcomingEvents[indexPath.item]
    navigator.navigate(to: session, popToRoot: false)
  }

}
