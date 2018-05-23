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

@objc public class HomeCollectionViewDataSource: NSObject, UICollectionViewDataSource {

  // Hack to fix the animation getting stuck when navigating
  var shouldRegenerateHeaderAnimation: Bool = false

  private let upcomingItemsDataSource: UpcomingItemsDataSource
  private let signIn: SignInInterface // Used only to fetch the display name.
  private let remoteFeedDataSource = RemoteHomeFeedItemDataSource()
  private lazy var feedSectionDataSource =
      FeedSectionDataSource(remoteDataSource: remoteFeedDataSource)

  private let rootNavigator: RootNavigator
  private let sessionsDataSource: LazyReadonlySessionsDataSource

  public init(sessions: LazyReadonlySessionsDataSource,
              navigator: ScheduleNavigator,
              rootNavigator: RootNavigator,
              signIn: SignInInterface = SignIn.sharedInstance) {
    upcomingItemsDataSource = UpcomingItemsDataSource(sessions: sessions,
                                                      scheduleNavigator: navigator,
                                                      rootNavigator: rootNavigator)
    sessionsDataSource = sessions
    self.rootNavigator = rootNavigator
    self.signIn = signIn
  }

  public func syncFeedItems(_ callback: @escaping ([HomeFeedItem]) -> Void) {
    remoteFeedDataSource.syncFeedItems(callback)
  }

  public func stopSyncing() {
    remoteFeedDataSource.stopSyncing()
  }

  public func canSelectMoment(_ moment: Moment) -> Bool {
    return moment.cta != nil
  }

  public func selectMoment(_ moment: Moment) {
    guard let cta = moment.cta else { return }
    switch cta {
    case .viewLivestream:
      guard let url = moment.streamURL else { return }
      UIApplication.shared.openURL(url)
    case .viewMap:
      rootNavigator.navigateToMap(roomId: moment.featureID)
    }
  }

  public func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 3
  }

  public func collectionView(_ collectionView: UICollectionView,
                             numberOfItemsInSection section: Int) -> Int {
    switch section {
    // Top banner / countdown view
    case 0:
      return 1

    // Upcoming items in a single side-scrolling collection view
    case 1:
      return 1

    // Announcements
    case 2:
      return feedSectionDataSource.numberOfItems

    case _:
      fatalError("Unsupported section \(section)")
    }
  }

  public func collectionView(_ collectionView: UICollectionView,
                             cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch indexPath.section {
    case 0:
      return headlinerCell(for: collectionView, at: indexPath)
    case 1:
      return upcomingItemsCell(for: collectionView, at: indexPath)
    case 2:
      return feedSectionDataSource.collectionView(collectionView, cellForItemAt: indexPath)

    case _:
      fatalError("Unsupported section \(indexPath.section)")
    }
  }

  public func collectionView(_ collectionView: UICollectionView,
                             viewForSupplementaryElementOfKind kind: String,
                             at indexPath: IndexPath) -> UICollectionReusableView {
    let view = collectionView.dequeueReusableSupplementaryView(
      ofKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: HomeCollectionViewSectionHeader.reuseIdentifier(),
      for: indexPath
    )
    guard let header = view as? HomeCollectionViewSectionHeader else { return view }
    populateHeader(header, forSection: indexPath.section)
    return header
  }

  private func populateHeader(_ header: HomeCollectionViewSectionHeader, forSection section: Int) {
    var name = signIn.currentUser?.displayName
    if name == nil {
      name = signIn.currentUpgradableUser?.displayName
    }

    switch section {
    case 1:
      header.horizontalTextPadding = 16
      header.name = name
      header.title = NSLocalizedString(
        "Upcoming events",
        comment: "Section header for upcoming sessions, office hours, etc"
      )
    case 2:
      header.horizontalTextPadding = 0
      header.name = nil
      header.title = NSLocalizedString("Announcements",
                                       comment: "Section header for I/O announcements")
    case _:
      header.name = nil
      header.title = nil
    }
  }

  // Used for layout size calculating. Ideally this should be done in the collection view layout.
  private let referenceHeader: HomeCollectionViewSectionHeader =
      HomeCollectionViewSectionHeader(frame: CGRect(x: 0, y: 0, width: 375, height: 72))

  public func collectionView(_ collectionView: UICollectionView,
                             layout collectionViewLayout: UICollectionViewLayout,
                             referenceSizeForHeaderInSection section: Int) -> CGSize {
    switch section {
    case 1, 2:
      populateHeader(referenceHeader, forSection: section)
      return CGSize(width: collectionView.frame.size.width,
                    height: referenceHeader.intrinsicContentSize.height)

    case _:
      return .zero
    }
  }

  private func upcomingItemsCell(for collectionView: UICollectionView,
                                 at indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: UpcomingItemsCollectionViewCell.reuseIdentifier(),
      for: indexPath
    ) as! UpcomingItemsCollectionViewCell
    cell.populate(upcomingItems: upcomingItemsDataSource)
    return cell
  }

  private func headlinerCell(for collectionView: UICollectionView,
                             at indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: HomeCollectionViewHeadlinerCell.reuseIdentifier(),
      for: indexPath
    ) as! HomeCollectionViewHeadlinerCell

    if let moment = Moment.currentMoment() {
      cell.populate(moment: moment)
      return cell
    }

    if let view = cell.headlinerView as? CountdownView, !shouldRegenerateHeaderAnimation {
      view.stop()
      view.setupInitialState()
      view.play()
    } else {
      shouldRegenerateHeaderAnimation = false
      let view = CountdownView()
      cell.headlinerView = view
      view.play()
    }
    return cell
  }

  public func sizeForItem(index: Int, maxWidth: CGFloat) -> CGSize {
    return feedSectionDataSource.sizeForItem(index: index, maxWidth: maxWidth)
  }

}
