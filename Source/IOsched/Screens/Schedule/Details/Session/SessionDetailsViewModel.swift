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
import FirebaseDatabase

final class SessionDetailsViewModel {

  fileprivate enum Constants {
    static let unknownRoom = "(TBA)"
  }

  private enum CancellationConstants {
    static let confirmCancellationTitle = NSLocalizedString("Confirm Cancellation", comment: "Confirm cancellation title")
    static let confirmCancellationMessage = NSLocalizedString("Are you sure you want to cancel your session reservation?",
                                                              comment: "Confirm cancellation message")

    static let confirmWaitlistCancellationTitle = NSLocalizedString("Cancel Waitlisting", comment: "Confirm cancellation title")
    static let confirmWaitlistCancellationMessage = NSLocalizedString("Are you sure you want to cancel your waitlist request?",
                                                              comment: "Confirm cancellation message")

  }

  // MARK: - Dependencies
  private let conferenceDataSource: ConferenceDataSource
  private let bookmarkStore: WritableBookmarkStore
  private let reservationStore: ReadonlyReservationStore
  private let userState: WritableUserState
  private let navigator: ScheduleNavigator

  // MARK: - Input
  private let sessionId: String

  // MARK: - Output
  var scheduleEventDetailsViewModel: ScheduleEventDetailsViewModel?
  var processing = false

  init(conferenceDataSource: ConferenceDataSource,
       bookmarkStore: WritableBookmarkStore,
       reservationStore: ReadonlyReservationStore,
       userState: WritableUserState,
       navigator: ScheduleNavigator,
       sessionId: String) {
    self.conferenceDataSource = conferenceDataSource
    self.bookmarkStore = bookmarkStore
    self.reservationStore = reservationStore
    self.userState = userState
    self.navigator = navigator

    self.sessionId = sessionId

    registerForDataLayerUpdates()
    updateModel(forceUpdate: true)
  }

  // MARK: - View updates
  typealias ViewUpdateCallback = () -> Void
  var viewUpdateCallback: ViewUpdateCallback?
  func onUpdate(_ viewUpdateCallback: @escaping ViewUpdateCallback) {
    self.viewUpdateCallback = viewUpdateCallback
  }

  func updateView() {
    DispatchQueue.main.async { [weak self] in
      self?.viewUpdateCallback?()
    }
  }

  // MARK: - Model updates

  private var bookmarkUpdatesObserver: Any? {
    willSet {
      if let bookmarkUpdatesObserver = bookmarkUpdatesObserver {
        NotificationCenter.default.removeObserver(bookmarkUpdatesObserver)
      }
    }
  }

  private var reservationService: FirebaseReservationServiceInterface?

  private func registerForDataLayerUpdates() {
    let center = NotificationCenter.default
    bookmarkUpdatesObserver = center.addObserver(forName: .bookmarkUpdate,
                                                 object: nil,
                                                 queue: nil) { [weak self] _ in
      self?.updateModel()
      self?.updateView()
    }

    reservationService = FirebaseReservationService2(sessionID: self.sessionId)
      .onSeatAvailabilityUpdate { seatsAvailable in
        self.processing = false
        self.updateModel()
        self.updateView()
      }
      .onReservationProcessUpdate { reservationStatus in
        self.reservationStore.updateReservationStatus(sessionId: self.sessionId,
                                                      status: reservationStatus)

        self.processing = false
        self.updateModel()
        self.updateView()
      }
      .onReservationResultUpdate { reservationResult in
        if reservationResult == .clash {
          self.processing = false
          self.updateView()
          self.navigator.showReservationClashDialog()
        }
      }
  }

  deinit {
    bookmarkUpdatesObserver = nil
    reservationService = nil
  }

  private func updateModel(forceUpdate: Bool = false) {
    if forceUpdate {
      if let session = conferenceDataSource.session(by: sessionId) {
        let isBookmarked = bookmarkStore.isBookmarked(sessionId: sessionId)
        let isRegistered = userState.isUserRegistered
        let seatsAvailable = reservationService?.seatsAvailable ?? false
        let reservationStatus = reservationService?.reservationStatus ?? .none
        self.scheduleEventDetailsViewModel =
            ScheduleEventDetailsViewModel(session,
                                          bookmarked: isBookmarked,
                                          reservationStatus: reservationStatus,
                                          isUserRegistered: isRegistered,
                                          seatsAvailable: seatsAvailable,
                                          conferenceDataSource: self.conferenceDataSource,
                                          navigator: navigator)
      }
    }
    else {
      guard let currentViewModel = self.scheduleEventDetailsViewModel else { return }
      let isBookmarked = bookmarkStore.isBookmarked(sessionId: sessionId)
      let isRegistered = userState.isUserRegistered
      let seatsAvailable = reservationService?.seatsAvailable ?? false
      let reservationStatus = reservationService?.reservationStatus ?? .none

      self.scheduleEventDetailsViewModel = ScheduleEventDetailsViewModel(currentViewModel,
                                                                         bookmarked: isBookmarked,
                                                                         reservationStatus: reservationStatus,
                                                                         isUserRegistered: isRegistered,
                                                                         seatsAvailable: seatsAvailable,
                                                                         navigator: navigator)
    }
  }

  // MARK: - Actions
  func shareSession(sourceView: UIView?, sourceRect: CGRect? ) {
    guard let title = scheduleEventDetailsViewModel?.title else { return }
    guard let link = scheduleEventDetailsViewModel?.sessionUrl else { return }

    let text = NSLocalizedString("Check out '\(title)' at #io18!", comment: "Template for sending session details. The parenthesized value 'title' will be an unlocalized session name.")
    navigator.shareSessionDetails(items: [text, link],
                                  sourceView: sourceView,
                                  sourceRect: sourceRect)
  }

  func openMap() {
    navigator.navigateToMap(roomId: (scheduleEventDetailsViewModel?.roomId))
  }

  func toggleBookmark() {
    guard let sessionId = self.scheduleEventDetailsViewModel?.id else { return }
    self.bookmarkStore.toggleBookmark(sessionId: sessionId)
  }

  func toggleReservation() {
    guard let reservationService = reservationService else { return }

    switch reservationService.reservationStatus {
    case .reserved:
      navigator.showCancellationDialog(title: CancellationConstants.confirmCancellationTitle,
                                       message: CancellationConstants.confirmCancellationMessage) { confirmCancellation in
        if confirmCancellation {
          self.processing = true
          self.updateView()

          reservationService.attemptCancellation()
        }
      }
    case .waitlisted:
      navigator.showCancellationDialog(title: CancellationConstants.confirmWaitlistCancellationTitle,
                                       message: CancellationConstants.confirmWaitlistCancellationMessage) { confirmCancellation in
        if confirmCancellation {
          self.processing = true
          self.updateView()

          reservationService.attemptCancellation()
        }
      }
    case .none:
      self.processing = true
      self.updateView()

      reservationService.attemptReservation()
    }
  }

  func rateSession() {
    guard let viewModel = self.scheduleEventDetailsViewModel else { return }
    navigator.navigateToFeedback(sessionId: viewModel.id, title: viewModel.title)
  }

  func detailsViewController(_ index: IndexPath) -> UIViewController? {
    if index.row > 0,
      let speakerViewModels = scheduleEventDetailsViewModel?.speakers, index.row - 1 < speakerViewModels.count {
      let speakerViewModel = speakerViewModels[index.row - 1]
      return navigator.speakerDetailsViewController(for: speakerViewModel.speaker)
    }

    return nil
  }
}

struct ScheduleEventDetailsViewModel {
  private enum Constants {
    static let headerBackgroundColor = UIColor(hex: "#00e4ff")

    static let removeFromMyIO = NSLocalizedString("Remove from My Events",
                                                  comment: "Text for preview action")
    static let addToMyIO = NSLocalizedString("Add to My Events",
                                             comment: "Text for preview action")
    static let feedbackTimeBeforeSessionEnd = TimeInterval(15 * 60) // 15 minutes.

    static let reservationCutOff: TimeInterval = 60 * 60 // one hour before

    static let reservationButtonTitleReserve =
      NSLocalizedString("Reserve seat",
                        comment: "Text for action to reserve seat")
    static let reservationButtonTitleReserved =
      NSLocalizedString("Seat reserved",
                        comment: "Text for button when seat is reserved")
    static let reservationButtonTitleJoinWaitlist =
      NSLocalizedString("Join waitlist",
                        comment: "Button label for joining waitlist")
    static let reservationButtonTitleWaitlisted =
      NSLocalizedString("Waitlisted",
                        comment: "Button title for waitlisted sessions")
    static let reservationCutOffHasPassed =
      NSLocalizedString("Reservation no longer possible",
                        comment: "Button label for reservation no longer possible")
  }

  let id: String
  let title: String
  let sessionUrl: URL
  let youtubeUrl: URL?
  let time: String
  let startTimestamp: Date
  let location: String
  let roomId: String
  let detail: String //description
  let mainTag: ScheduleEventDetailsTagViewModel?
  let tags: [ScheduleEventDetailsTagViewModel]
  let speakers: [ScheduleEventDetailsSpeakerViewModel]
  let isBookmarked: Bool
  let reservationStatus: ReservationStatus
  let navigator: ScheduleNavigator

  /// Some sessions (such as meals and badge pickup) are not bookmarkable
  let isBookmarkable: Bool

  /// Only sessions are reservable
  let isReservable: Bool

  let isUserRegistered: Bool

  let seatsAvailable: Bool

  private let feedbackAllowedAfterTimestamp: Date
  var canShowRateSessionButton: Bool {
    return Date() >= feedbackAllowedAfterTimestamp
  }

  var headerBackgroundColor: UIColor {
    guard let hexColor = mainTag?.color else { return Constants.headerBackgroundColor }
    return UIColor(hex: hexColor)
  }

  var bookmarkPreviewActionTitle: String {
    return isBookmarked
      ? Constants.removeFromMyIO
      : Constants.addToMyIO
  }

  var bookmarkButtonBackgroundColor: UIColor {
    return UIColor.white
  }

  var bookmarkButtonImage: UIImage {
    return isBookmarked
      ? UIImage(named: "ic_session_bookmarked")!
      : UIImage(named: "ic_session_bookmark-dark")!
  }

  var bookmarkButtonAccessibilityLabel: String {
    return isBookmarked
      ? NSLocalizedString("Session is bookmarked. Tap to remove bookmark.",
                          comment: "Accessibility hint for bookmark button, bookmarked state")
      : NSLocalizedString("Session is not bookmarked. Tap to add bookmark.",
                          comment: "Accessibility hint for bookmark button, non-bookmarked state.")
  }

  var reserveButtonBackgroundColor: UIColor {
    switch reservationStatus {
    case .reserved:
      return MDCPalette.grey.tint200
    case .waitlisted:
      return MDCPalette.grey.tint200
    case .none:
      if seatsAvailable {
        return MDCPalette.indigo.accent200!
      }
      else {
        return MDCPalette.indigo.accent200!
      }
    }
  }

  var reserveButtonImage: UIImage {
    switch reservationStatus {
    case .reserved:
      return UIImage(named: "ic_session_reserved")!
    case .waitlisted:
      return UIImage(named: "ic_waitlisted")!
    case .none:
      if seatsAvailable {
        return UIImage(named: "ic_session_reserve")!
      }
      else {
        return UIImage(named: "ic_hourglass_empty_white")!
      }
    }
  }

  // if there is less than one hour between now and session start, cut off has passed
  var reservationTimeCutoffHasPassed: Bool {
    let now = Date()
    let difference = startTimestamp.timeIntervalSince(now)
    return difference <= Constants.reservationCutOff
  }

  var reserveButtonLabel: String {
    switch reservationStatus {
    case .reserved:
      return Constants.reservationButtonTitleReserved
    case .waitlisted:
      return Constants.reservationButtonTitleWaitlisted
    case .none:
      if seatsAvailable && !reservationTimeCutoffHasPassed {
        return Constants.reservationButtonTitleReserve
      }
      else if reservationTimeCutoffHasPassed {
        return Constants.reservationCutOffHasPassed
      }
      else {
        return Constants.reservationButtonTitleJoinWaitlist
      }
    }
  }

  var reserveButtonFontColor: UIColor {
    switch reservationStatus {
    case .reserved:
      return MDCPalette.indigo.accent200!
    case .waitlisted:
      return MDCPalette.indigo.accent200!
    case .none:
      if seatsAvailable {
        return UIColor.white
      }
      else {
        return UIColor.white
      }
    }
  }

  var shouldDisplayVideoplayer: Bool {
    return youtubeUrl != nil
  }

  init(_ session: Session,
       bookmarked: Bool,
       reservationStatus: ReservationStatus,
       isUserRegistered: Bool,
       seatsAvailable: Bool,
       conferenceDataSource: ConferenceDataSource,
       navigator: ScheduleNavigator) {
    self.navigator = navigator
    id = session.id
    title = session.title
    sessionUrl = session.url
    youtubeUrl = session.youtubeUrl

    let date = Formatters.dateFormatter.string(from: session.startTimestamp)
    startTimestamp = session.startTimestamp
    let startTime = Formatters.timeFormatter.string(from: session.startTimestamp)
    let endTime = Formatters.timeFormatter.string(from: session.endTimestamp)
    time = "\(date), \(startTime) - \(endTime)"

    feedbackAllowedAfterTimestamp = session.endTimestamp - Constants.feedbackTimeBeforeSessionEnd

    location = session.roomName
    roomId = session.roomId

    detail = session.detail

    tags = conferenceDataSource.allTopics.filter { conferenceTag -> Bool in
      return session.tagNames.contains(conferenceTag.name)
      }.map { conferenceTag -> ScheduleEventDetailsTagViewModel in
        let colorHex = conferenceTag.colorString ?? "#efefef"
        return ScheduleEventDetailsTagViewModel(name: conferenceTag.name, color: colorHex)
    }

    mainTag = tags.filter {
      guard let eventTag = EventTag(name: $0.name) else { return false }
      return eventTag.name == session.mainTagId
    }.first

    speakers = session.speakers
    .map { (speaker) -> ScheduleEventDetailsSpeakerViewModel in
      return ScheduleEventDetailsSpeakerViewModel(speaker, navigator: navigator)
    }

    isBookmarked = bookmarked
    isBookmarkable = !session.isKeynote

    self.isUserRegistered = isUserRegistered
    self.seatsAvailable = seatsAvailable

    isReservable = session.type == .session && isUserRegistered

    self.reservationStatus = reservationStatus
  }

  init(_ viewModel: ScheduleEventDetailsViewModel,
       bookmarked: Bool,
       reservationStatus: ReservationStatus,
       isUserRegistered: Bool,
       seatsAvailable: Bool,
       navigator: ScheduleNavigator) {
    self.id = viewModel.id
    self.title = viewModel.title
    self.sessionUrl = viewModel.sessionUrl
    self.youtubeUrl = viewModel.youtubeUrl
    self.time = viewModel.time
    self.startTimestamp = viewModel.startTimestamp
    self.location = viewModel.location
    self.roomId = viewModel.roomId
    self.detail = viewModel.detail
    self.tags = viewModel.tags
    self.mainTag = viewModel.mainTag
    self.speakers = viewModel.speakers
    self.isBookmarked = bookmarked
    self.isBookmarkable = viewModel.isBookmarkable
    self.reservationStatus = reservationStatus
    self.isReservable = viewModel.isReservable
    self.isUserRegistered = isUserRegistered
    self.seatsAvailable = seatsAvailable
    self.feedbackAllowedAfterTimestamp = viewModel.feedbackAllowedAfterTimestamp
    self.navigator = navigator
  }

  func rateSession() {
    navigator.navigateToFeedback(sessionId: id, title: title)
  }
}

extension ScheduleEventDetailsViewModel {
  fileprivate struct Formatters {
    static let dateFormatter: DateFormatter = {
      let formatter = TimeZoneAwareDateFormatter()
      formatter.setLocalizedDateFormatFromTemplate("MMMdd")
      formatter.timeZone = TimeZone.userTimeZone()
      return formatter
    }()

    static let timeFormatter: DateFormatter = {
      let formatter = TimeZoneAwareDateFormatter()
      formatter.timeStyle = .short
      formatter.timeZone = TimeZone.userTimeZone()
      return formatter
    }()
  }
}

struct ScheduleEventDetailsSpeakerViewModel {
  let name: String
  let company: String
  let thumbnailUrl: URL?
  let id: String
  let speaker: Speaker
  private let navigator: ScheduleNavigator

  init(_ speaker: Speaker, navigator: ScheduleNavigator) {
    self.navigator = navigator

    name = speaker.name
    company = speaker.company
    thumbnailUrl = speaker.thumbnailUrl
    id = speaker.id
    self.speaker = speaker
  }

  func selectSpeaker(speaker: Speaker) {
    navigator.navigateToSpeakerDetails(speaker: speaker, popToRoot: false)
  }
}

struct ScheduleEventReleatedSessionViewModel {
  let title: String
  let durationAndLocation: String
  // tags
}

struct ScheduleEventDetailsTagViewModel {
  let name: String
  let color: String

  public init(name: String, color: String) {
    self.name = name
    self.color = color
  }
}
