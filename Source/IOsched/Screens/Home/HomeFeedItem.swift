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

import FirebaseFirestore

public struct HomeFeedItem {

  public var title: String
  public var message: String
  public var timestamp: Date

  public var category: String
  public var color: String
  public var active: Bool
  public var emergency: Bool

}

extension HomeFeedItem {

  public init?(dictionary: [String: Any]) {
    guard let title = dictionary["title"] as? String,
        let message = dictionary["message"] as? String,
        let timestamp = dictionary["timeStamp"] as? Timestamp,
        let category = dictionary["category"] as? String,
        let color = dictionary["color"] as? String,
        let active = dictionary["active"] as? Bool,
        let emergency = dictionary["emergency"] as? Bool else { return nil }

    self.title = title
    self.message = message
    self.timestamp = timestamp.dateValue()
    self.category = category
    self.color = color
    self.active = active
    self.emergency = emergency
  }

}

public class RemoteHomeFeedItemDataSource {

  public private(set) var feedItems: [HomeFeedItem] = []

  public var activeFeedItems: [HomeFeedItem] {
    let currentTimestamp = Date()
    return feedItems.filter {
      currentTimestamp > $0.timestamp
    } .sorted { (lhs, rhs) -> Bool in
      return lhs.timestamp <= rhs.timestamp
    }
  }

  private var firestoreListener: ListenerRegistration?
  private let firestore: Firestore

  public init(firestore: Firestore) {
    self.firestore = firestore
  }

  public convenience init() {
    self.init(firestore: Firestore.firestore())
  }

  public func syncFeedItems(_ callback: @escaping ([HomeFeedItem]) -> Void) {
    firestoreListener = firestore.feed.addSnapshotListener { (snapshot, error) in
      if let error = error {
        print("Error fetching feed items: \(error)")
        return
      }
      guard let snapshot = snapshot else {
        print("Unexpectedly found nil snapshot when fetching feed items")
        return
      }

      var feedItems: [HomeFeedItem] = []
      for document in snapshot.documents {
        if let item = HomeFeedItem(dictionary: document.data()) {
          feedItems.append(item)
        }
      }

      self.feedItems = feedItems
      self.cacheAttributedStrings()
      callback(feedItems)
    }
  }

  public func stopSyncing() {
    firestoreListener?.remove()
    firestoreListener = nil
  }

  // Avoids a crash. Not sure why. Has something to do with NSAttributedString using WebKit
  // to create attributed strings from HTML.
  private func cacheAttributedStrings() {
    for item in feedItems {
      _ = InfoDetail.attributedText(detail: item.message)
    }
  }

}

class FeedSectionDataSource {

  private let remoteDataSource: RemoteHomeFeedItemDataSource

  init(remoteDataSource: RemoteHomeFeedItemDataSource) {
    self.remoteDataSource = remoteDataSource
  }

  var numberOfItems: Int {
    // Always show at least one cell.
    return max(remoteDataSource.activeFeedItems.count, 1)
  }

  func itemAtIndex(_ index: Int) -> HomeFeedItem {
    return remoteDataSource.activeFeedItems[index]
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard !remoteDataSource.activeFeedItems.isEmpty else {
      return noAnnouncementsCell(collectionView: collectionView, indexPath: indexPath)
    }
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: HomeFeedItemCollectionViewCell.reuseIdentifier(),
      for: indexPath
      ) as! HomeFeedItemCollectionViewCell
    let feedItem = itemAtIndex(indexPath.item)
    cell.populate(feedItem: feedItem)
    return cell
  }

  private func noAnnouncementsCell(collectionView: UICollectionView,
                                   indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: NoAnnouncementsCollectionViewCell.reuseIdentifier(),
      for: indexPath
    ) as! NoAnnouncementsCollectionViewCell
    return cell
  }

  func sizeForItem(index: Int, maxWidth: CGFloat) -> CGSize {
    guard !remoteDataSource.activeFeedItems.isEmpty else {
      let height = NoAnnouncementsCollectionViewCell.height
      return CGSize(width: maxWidth, height: height)
    }
    let item = itemAtIndex(index)
    return HomeFeedItemCollectionViewCell.sizeForContents(item, maxWidth: maxWidth)
  }

}
