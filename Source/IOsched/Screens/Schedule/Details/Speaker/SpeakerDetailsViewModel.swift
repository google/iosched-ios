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

import MaterialComponents

final class SpeakerDetailsViewModel {

  // MARK: - Dependencies
  private let sessionsDataSource: LazyReadonlySessionsDataSource
  private let bookmarkDataSource: RemoteBookmarkDataSource
  private let reservationDataSource: RemoteReservationDataSource
  private let navigator: ScheduleNavigator

  // MARK: - Input
  let speaker: Speaker

  // MARK: - Output
  var speakerDetailsViewModel: ScheduleEventDetailsSpeakerViewModel?
  var speakerDetailsMainInfoViewModel: SpeakerDetailsMainInfoViewModel?
  var relatedSessions: [SessionViewModel]?

  private lazy var clashDetector = ReservationClashDetector(sessions: sessionsDataSource,
                                                            reservations: reservationDataSource)

  init(sessionsDataSource: LazyReadonlySessionsDataSource,
       bookmarkDataSource: RemoteBookmarkDataSource,
       reservationDataSource: RemoteReservationDataSource,
       navigator: ScheduleNavigator,
       speaker: Speaker) {
    self.sessionsDataSource = sessionsDataSource
    self.bookmarkDataSource = bookmarkDataSource
    self.reservationDataSource = reservationDataSource
    self.navigator = navigator

    self.speaker = speaker

    registerForTimezoneUpdates()
    registerForBookmarkUpdates()
    registerForReservationsUpdates()

    updateModel()
  }

  /// This method transform all inputs into the correct output
  func transform() {
    self.speakerDetailsViewModel =
        ScheduleEventDetailsSpeakerViewModel(speaker, navigator: navigator)
    self.speakerDetailsMainInfoViewModel =
        SpeakerDetailsMainInfoViewModel(speaker, navigator: navigator)
    self.relatedSessions = sessionsDataSource.sessions
      .filter { $0.speakers.contains(speaker) }
      .map {
        SessionViewModel(session: $0,
                         bookmarkDataSource: self.bookmarkDataSource,
                         reservationDataSource: self.reservationDataSource,
                         clashDetector: clashDetector,
                         scheduleNavigator: navigator)
    }
  }

  func toggleBookmark(sessionID: String) {
    self.bookmarkDataSource.toggleBookmark(sessionID: sessionID)
  }

  // MARK: - View updates
  var viewUpdateCallback: ((_ indexPath: IndexPath?) -> Void)?
  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void) {
    self.viewUpdateCallback = viewUpdateCallback
    updateModel()
  }

  func indexPath(for sessionID: String) -> IndexPath? {
    if let eventIndex = self.relatedSessions?.index(where: { $0.id == sessionID }) {
      return IndexPath(row: eventIndex, section: 1)
    }

    return nil
  }

  // MARK: - Model updates
  fileprivate var bookmarkUpdatesObserver: Any?
  private func registerForDataLayerUpdates() {
    let center = NotificationCenter.default

    bookmarkUpdatesObserver = center.addObserver(forName: .bookmarkUpdate,
                                                 object: nil,
                                                 queue: nil) { [weak self] _ in
      guard let self = self else { return }
      // no need to update the model, as bookmarked sessions will be filtered later
      self.updateView()
    }
  }

  deinit {
    timezoneObserver = nil
    if let observer = bookmarkUpdatesObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  func updateModel() {
    transform()
    updateView()
  }

  func updateView(at indexPath: IndexPath? = nil) {
    DispatchQueue.main.async {
      self.viewUpdateCallback?(indexPath)
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

  // MARK: - Header images

  private static let allImageNames = [
    "speaker_ab", "speaker_cd", "speaker_ef", "speaker_gh", "speaker_ij", "speaker_kl",
    "speaker_mn", "speaker_op", "speaker_qr", "speaker_st", "speaker_uvw", "speaker_xyz"
  ]

  func headerImageForSpeaker() -> UIImage? {
    // Semi-random, but consistent per speaker.
    let index = abs(speaker.name.hash % SpeakerDetailsViewModel.allImageNames.count)
    let imageName = SpeakerDetailsViewModel.allImageNames[index]
    return UIImage(named: imageName)
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
      let viewModel = relatedSessionAtIndex(index.row) {
      return navigator.detailsViewController(for: viewModel.session)
    }

    return nil
  }

  func populateSupplementaryView(_ view: UICollectionReusableView, forItemAt indexPath: IndexPath) {
    if let sectionHeader = view as? MDCCollectionViewTextCell {
      sectionHeader.shouldHideSeparator = false
      sectionHeader.textLabel?.text = NSLocalizedString("Related Sessions", comment: "Indicates that the list following has sessions given by the same speaker")
    }
  }

  func didSelectItemAt(indexPath index: IndexPath) {
    if index.section == 1,
      let count = relatedSessions?.count,
      count > index.row,
      let viewModel = relatedSessions?[index.row] {
      navigator.navigate(to: viewModel.session, popToRoot: false)
    }
  }

  func relatedSessionAtIndex(_ index: Int) -> SessionViewModel? {
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
  let twitterURL: URL?
  private let navigator: ScheduleNavigator

  init (_ speaker: Speaker, navigator: ScheduleNavigator) {
    bio = speaker.bio
    twitterURL = speaker.twitterURL
    self.navigator = navigator
  }

  func twitterTapped() {
    if let twitterURL = twitterURL {
      self.navigator.navigateToURL(twitterURL)
    }
  }

}
