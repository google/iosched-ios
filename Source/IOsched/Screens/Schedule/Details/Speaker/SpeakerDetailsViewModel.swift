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
import Platform
import MaterialComponents

final class SpeakerDetailsViewModel {

  // MARK: - Dependencies
  private let conferenceDataSource: ConferenceDataSource
  private let bookmarkStore: WritableBookmarkStore
  private let reservationStore: ReadonlyReservationStore
  private let navigator: ScheduleNavigator

  // MARK: - Input
  let speaker: Speaker

  // MARK: - Output
  var speakerDetailsViewModel: ScheduleEventDetailsSpeakerViewModel?
  var speakerDetailsMainInfoViewModel: SpeakerDetailsMainInfoViewModel?
  var relatedSessions: [ConferenceEventViewModel]?

  init(conferenceDataSource: ConferenceDataSource,
       bookmarkStore: WritableBookmarkStore,
       reservationStore: ReadonlyReservationStore,
       navigator: ScheduleNavigator,
       speaker: Speaker) {
    self.conferenceDataSource = conferenceDataSource
    self.bookmarkStore = bookmarkStore
    self.reservationStore = reservationStore
    self.navigator = navigator

    self.speaker = speaker

    registerForTimezoneUpdates()
    registerForBookmarkUpdates()
    registerForReservationsUpdates()

    updateModel()
  }

  /// This method transform all inputs into the correct output
  func transform() {
    self.speakerDetailsViewModel = ScheduleEventDetailsSpeakerViewModel(speaker, navigator: navigator)
    self.speakerDetailsMainInfoViewModel  = SpeakerDetailsMainInfoViewModel(speaker, navigator: navigator)
    self.relatedSessions = conferenceDataSource.allSessions
      .filter { $0.speakerIds.contains(speaker.id) }
      .map {
        ConferenceEventViewModel(event: $0,
                                 conferenceDataSource: self.conferenceDataSource,
                                 bookmarkStore: self.bookmarkStore,
                                 reservationStore: self.reservationStore)
    }
  }

  func toggleBookmark(sessionId: String) {
    DispatchQueue.global().async {
      self.bookmarkStore.toggleBookmark(sessionId: sessionId)
    }
  }

  // MARK: - View updates
  var viewUpdateCallback: ((_ indexPath: IndexPath?) -> Void)?
  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void) {
    self.viewUpdateCallback = viewUpdateCallback
    updateModel()
  }

  func indexPath(for sessionId: String) -> IndexPath? {
    if let eventIndex = self.relatedSessions?.index(where: { $0.id == sessionId }) {
      return IndexPath(row: eventIndex, section: 1)
    }

    return nil
  }

  // MARK: - Model updates
  fileprivate var conferenceUpdatesObserver: NSObjectProtocol!
  fileprivate var bookmarkUpdatesObserver: NSObjectProtocol!
  private func registerForDataLayerUpdates() {
    let center = NotificationCenter.default
    conferenceUpdatesObserver = center.addObserver(forName: .conferenceUpdate,
                                                   object: nil,
                                                   queue: nil) { [weak self] _ in
                                                    // reload view
                                                    self?.updateView()
    }

    bookmarkUpdatesObserver = center.addObserver(forName: .bookmarkUpdate,
                                                 object: nil,
                                                 queue: nil) { [weak self] notification in
                                                  guard self != nil else { return }
                                                  // no need to update the model, as bookmarked sessions will be filtered later
                                                  if let sessionId = notification.userInfo?[BookmarkUpdates.sessionId] as? String {
                                                    let indexPath = self?.indexPath(for: sessionId)
                                                    self?.updateView(at: indexPath)
                                                  }
                                                  else {
                                                    self?.updateView()
                                                  }
    }
  }

  deinit {
    timezoneObserver = nil
    NotificationCenter.default.removeObserver(conferenceUpdatesObserver)
    NotificationCenter.default.removeObserver(bookmarkUpdatesObserver)
  }

  func updateModel() {
    transform()
    updateView()
  }

  func updateView(at indexPath: IndexPath? = nil) {
    DispatchQueue.main.async { [weak self] in
      self?.viewUpdateCallback?(indexPath)
    }
  }

  // MARK: - Timezone observing
  private func timeZoneUpdated() {
    updateModel()
  }

  private var timezoneObserver: Any? {
    willSet {
      if let observer = timezoneObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  private func registerForTimezoneUpdates() {
    timezoneObserver = NotificationCenter.default.addObserver(forName: .timezoneUpdate,
                                                              object: nil,
                                                              queue: nil) { [weak self] _ in
      // update timezone
      self?.timeZoneUpdated()
    }
  }

  // MARK: - Data update observing

  func bookmarksUpdated() {
    updateModel()
  }

  private var bookmarkObserver: Any? {
    willSet {
      if let observer = bookmarkObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  private func registerForBookmarkUpdates() {
    bookmarkObserver = NotificationCenter.default.addObserver(forName: .bookmarkUpdate,
                                                              object: nil,
                                                              queue: nil) { [weak self] _ in
      guard self != nil else { return }
      self?.bookmarksUpdated()
    }
  }

  func reservationsUpdated() {
    updateModel()
  }

  private var reservationsObserver: Any? {
    willSet {
      if let observer = reservationsObserver {
        NotificationCenter.default.removeObserver(observer)
      }
    }
  }

  private func registerForReservationsUpdates() {
    reservationsObserver = NotificationCenter.default.addObserver(forName: .reservationUpdate,
                                                                  object: nil,
                                                                  queue: nil) { [weak self] _ in
      self?.reservationsUpdated()
    }
  }

  func numberOfItemsInSection(_ section: Int) -> Int {
    if let count = relatedSessions?.count {
      return section == 0 ? 2 : count
    }

    return section == 0 ? 2 : 0
  }

  func numberOfSections() -> Int {
    return relatedSessions?.count ?? 0 > 0 ? 2 : 1
  }

  func detailsViewController(for index: IndexPath) -> UIViewController? {
    if index.section == 1,
      let session = relatedSessionAtIndex(index.row) {
      return navigator.detailsViewController(for: session.id)
    }

    return nil
  }

  func populateSupplementaryView(_ view: UICollectionReusableView, forItemAt indexPath: IndexPath) {
    if let sectionHeader = view as? MDCCollectionViewTextCell {
      sectionHeader.shouldHideSeparator = false
      sectionHeader.textLabel?.text = NSLocalizedString("Related Sessions", comment: "Indicates that the list following has sessions given by the same speaker").localizedUppercase
    }
  }

  func didSelectItemAt(indexPath index: IndexPath) {
    if index.section == 1,
      relatedSessions!.count > index.row,
      let session = relatedSessions?[index.row] {
      navigator.navigateToSessionDetails(sessionId: session.id, popToRoot: false)
    }
  }

  func relatedSessionAtIndex(_ index: Int) -> ConferenceEventViewModel? {
    return relatedSessions?[index]
  }

  private enum LayoutConstants {
    static let cellheight: CGFloat = 112
    static let sectionHeight: CGFloat = 50
    static let headerSize = CGSize.zero
  }

  func sizeForHeader(inSection section: Int, inFrame frame: CGRect) -> CGSize {
    switch section {
    case 0:
      return LayoutConstants.headerSize
    case _:
      return CGSize(width: frame.width, height: LayoutConstants.sectionHeight)
    }
  }
}

struct SpeakerDetailsMainInfoViewModel {
  let bio: String
  let plusOneUrl: URL?
  let twitterUrl: URL?
  private let navigator: ScheduleNavigator

  init (_ speaker: Speaker, navigator: ScheduleNavigator) {
    bio = speaker.bio
    plusOneUrl = speaker.plusOneUrl
    twitterUrl = speaker.twitterUrl
    self.navigator = navigator
  }

  func twitterTapped() {
    if let twitterUrl = twitterUrl {
      self.navigator.navigateToURL(twitterUrl)
    }
  }

  func plusTapped() {
    if let plusOneUrl = plusOneUrl {
      self.navigator.navigateToURL(plusOneUrl)
    }
  }
}
