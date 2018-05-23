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

final class SessionDetailsViewModel {

  fileprivate enum Constants {
    static let unknownRoom = "(TBA)"
  }

  private enum CancellationConstants {
    static let confirmCancellationTitle =
        NSLocalizedString("Confirm Cancellation", comment: "Confirm cancellation title")
    static let confirmCancellationMessage =
        NSLocalizedString("Are you sure you want to cancel your session reservation?",
                          comment: "Confirm reservation cancellation message")

    static let confirmWaitlistCancellationTitle =
        NSLocalizedString("Cancel Waitlisting", comment: "Confirm cancellation title")
    static let confirmWaitlistCancellationMessage =
        NSLocalizedString("Are you sure you want to cancel your waitlist request?",
                          comment: "Confirm waitlisting cancellation message")

  }

  // MARK: - Dependencies
  private let bookmarkDataSource: RemoteBookmarkDataSource
  private let reservationDataSource: RemoteReservationDataSource
  private let userState: PersistentUserState
  private let navigator: ScheduleNavigator
  private let clashDetector: ReservationClashDetector

  // MARK: - Input
  private let session: Session

  // MARK: - Output
  var scheduleEventDetailsViewModel: ScheduleEventDetailsViewModel
  var processing = false

  init(session: Session,
       bookmarkDataSource: RemoteBookmarkDataSource,
       reservationDataSource: RemoteReservationDataSource,
       clashDetector: ReservationClashDetector,
       userState: PersistentUserState,
       navigator: ScheduleNavigator) {
    self.session = session
    self.bookmarkDataSource = bookmarkDataSource
    self.reservationDataSource = reservationDataSource
    self.userState = userState
    self.navigator = navigator
    self.clashDetector = clashDetector

    let isBookmarked = bookmarkDataSource.isBookmarked(sessionID: session.id)
    let isRegistered = userState.isUserRegistered
    let seatsAvailable = reservationService?.seatsAvailable ?? false
    let reservationStatus = reservationService?.reservationStatus ?? .none
    self.scheduleEventDetailsViewModel =
      ScheduleEventDetailsViewModel(session,
                                    bookmarked: isBookmarked,
                                    reservationStatus: reservationStatus,
                                    clashDetector: clashDetector,
                                    isUserRegistered: isRegistered,
                                    seatsAvailable: seatsAvailable,
                                    navigator: navigator)

    registerForDataLayerUpdates()
  }

  // MARK: - View updates
  typealias ViewUpdateCallback = () -> Void
  var viewUpdateCallback: ViewUpdateCallback?
  func onUpdate(_ viewUpdateCallback: @escaping ViewUpdateCallback) {
    self.viewUpdateCallback = viewUpdateCallback
  }

  func updateView() {
    self.viewUpdateCallback?()
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
      guard let strongSelf = self else { return }
      DispatchQueue.main.async {
        strongSelf.updateModel()
        strongSelf.updateView()
      }
    }

    reservationService = FirestoreReservationService(sessionID: session.id)
      .onSeatAvailabilityUpdate { [weak self] _ in
        guard let self = self else { return }
        self.processing = false
        self.updateModel()
        self.updateView()
      }
      .onReservationStatusUpdate { [weak self] _ in
        guard let self = self else { return }
        self.processing = false
        self.updateModel()
        self.updateView()
      }
      .onReservationResultUpdate { [weak self] reservationResult in
        guard let self = self else { return }

        self.processing = false
        self.updateModel()
        self.updateView()
        switch reservationResult {
        case .clash, .swapClash:
          self.handleClash()
        case .cancelled, .cancelCutoff, .cancelUnknown:
          print("Reservation removed reservation with result: \(reservationResult)")
        case .reserved:
          print("Reservation successful")
        case .waitlisted:
          print("Waitlist successful")
        case .swapped, .swapCutoff, .swapWaitlisted, .swapUnknown:
          print("Swap: \(reservationResult.rawValue)")
        case .unknown:
          print("Reservation request returned unknown result")
        case .cutoff:
          // Display cutoff error
          print("Reservation errored with cutoff")
        }
      }
  }

  deinit {
    bookmarkUpdatesObserver = nil
    reservationService = nil
  }

  private func updateModel() {
    let isBookmarked = bookmarkDataSource.isBookmarked(sessionID: session.id)
    let isRegistered = userState.isUserRegistered
    let seatsAvailable = reservationService?.seatsAvailable ?? false
    let reservationStatus = reservationService?.reservationStatus ?? .none
    self.scheduleEventDetailsViewModel =
        ScheduleEventDetailsViewModel(session,
                                      bookmarked: isBookmarked,
                                      reservationStatus: reservationStatus,
                                      clashDetector: clashDetector,
                                      isUserRegistered: isRegistered,
                                      seatsAvailable: seatsAvailable,
                                      navigator: navigator)
  }

  // MARK: - Actions
  func shareSession(sourceView: UIView?, sourceRect: CGRect? ) {
    let title = scheduleEventDetailsViewModel.title
    let link = scheduleEventDetailsViewModel.sessionURL

    let text = NSLocalizedString("Check out '\(title)' at #io19!",
        comment: "Template for sending session details. The parenthesized value 'title' will be an unlocalized session name.")
    navigator.shareSessionDetails(items: [text, link],
                                  sourceView: sourceView,
                                  sourceRect: sourceRect)
  }

  func openMap() {
    navigator.navigateToMap(roomId: scheduleEventDetailsViewModel.roomId)
  }

  func toggleBookmark() {
    let sessionID = self.scheduleEventDetailsViewModel.id
    bookmarkDataSource.toggleBookmark(sessionID: sessionID)
  }

  func addToCalendar(completion: @escaping (Error?) -> Void) {
    GoogleCalendarSessionAdder.addSessionToCalendar(session, completion: completion)
  }

  func toggleReservation() {
    guard let reservationService = reservationService else { return }

    switch reservationService.reservationStatus {
    case .reserved:
      navigator.showCancellationDialog(
        title: CancellationConstants.confirmCancellationTitle,
        message: CancellationConstants.confirmCancellationMessage
      ) { confirmCancellation in
        if confirmCancellation {
          self.processing = true
          self.updateView()
          reservationService.attemptCancellation()
        }
      }
    case .waitlisted:
      navigator.showCancellationDialog(
        title: CancellationConstants.confirmWaitlistCancellationTitle,
        message: CancellationConstants.confirmWaitlistCancellationMessage
      ) { confirmCancellation in
        if confirmCancellation {
          self.processing = true
          self.updateView()

          reservationService.attemptCancellation()
        }
      }
    case .none:
      self.processing = true
      self.updateView()

      if let clash = clashDetector.clashes(for: session).first {
        reservationService.attemptSwap(withConflictingSessionID: clash.id)
      } else {
        reservationService.attemptReservation()
      }
    }
  }

  func handleClash() {
    let clashes = clashDetector.clashes(for: session)
    switch clashes.count {
    case 0:
      break
    case 1:
      guard let clash = clashes.first else { return }
      navigator.showReservationClashDialog {
        self.attemptSwap(clashID: clash.id)
      }
    case _:
      navigator.showMultiClashDialog()
    }
  }

  func attemptSwap(clashID: String) {
    processing = true
    reservationService?.attemptSwap(withConflictingSessionID: clashID)
  }

  func rateSession() {
    let viewModel = self.scheduleEventDetailsViewModel
    navigator.navigateToFeedback(sessionID: viewModel.id, title: viewModel.title)
  }

  func detailsViewController(_ index: IndexPath) -> UIViewController? {
    let speakerViewModels = scheduleEventDetailsViewModel.speakers
    if index.row > 0, index.row - 1 < speakerViewModels.count {
      let speakerViewModel = speakerViewModels[index.row - 1]
      return navigator.speakerDetailsViewController(for: speakerViewModel.speaker)
    }

    return nil
  }

  func headerImageForRoom() -> UIImage? {
    switch session.roomName {
    case "Amphitheatre", "Stage 1", "Stage 2", "Stage 3", "Stage 4", "Stage 5", "Stage 6", "Stage 7", "Stage 8":
      if let image = UIImage(named: "session_\(session.roomName)") {
        return image
      }
    case _:
      break
    }
    if session.roomName.contains("Reviews") {
      if let image = UIImage(named: "session_officeHours") {
        return image
      }
    }
    if session.roomName.contains("Codelabs") {
      if let image = UIImage(named: "session_codelabs") {
        return image
      }
    }

    return UIImage(named: "session_extra")
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
    static let reservationButtonTitleSwap =
      NSLocalizedString("Swap reservation",
                        comment: "Text for button to swap an existing reservation with a new reservation")
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
  let sessionURL: URL
  let youtubeURL: URL?
  let location: String
  let roomId: String
  let detail: String //description
  let mainTag: EventTag?
  let tags: [EventTag]
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

  let session: Session

  var time: String {
    let date = Formatters.dateFormatter.string(from: session.startTimestamp)
    let startTime = Formatters.timeFormatter.string(from: session.startTimestamp)
    let endTime = Formatters.timeFormatter.string(from: session.endTimestamp)
    return "\(date), \(startTime) - \(endTime)"
  }

  private let feedbackAllowedAfterTimestamp: Date
  var canShowRateSessionButton: Bool {
    return Date() >= feedbackAllowedAfterTimestamp && session.type == .sessions
  }

  var headerBackgroundColor: UIColor {
    return mainTag?.color ?? Constants.headerBackgroundColor
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
      return UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
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
    let difference = session.startTimestamp.timeIntervalSinceNow
    return difference <= Constants.reservationCutOff
  }

  var reserveButtonLabel: String {
    let clash = clashDetector.clashes(for: session).count > 0
    switch reservationStatus {
    case .reserved:
      return Constants.reservationButtonTitleReserved
    case .waitlisted:
      return Constants.reservationButtonTitleWaitlisted
    case .none:
      if reservationTimeCutoffHasPassed {
        return Constants.reservationCutOffHasPassed
      }
      if !seatsAvailable {
        return Constants.reservationButtonTitleJoinWaitlist
      }
      if clash {
        return Constants.reservationButtonTitleSwap
      }
      return Constants.reservationButtonTitleReserve
    }
  }

  var reserveButtonFontColor: UIColor {
    switch reservationStatus {
    case .reserved:
      return UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
    case .waitlisted:
      return UIColor(red: 26 / 255, green: 115 / 255, blue: 232 / 255, alpha: 1)
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
    return youtubeURL != nil
  }

  init(_ session: Session,
       bookmarked: Bool,
       reservationStatus: ReservationStatus,
       clashDetector: ReservationClashDetector,
       isUserRegistered: Bool,
       seatsAvailable: Bool,
       navigator: ScheduleNavigator) {
    self.navigator = navigator
    self.session = session
    id = session.id
    title = session.title
    sessionURL = session.url
    youtubeURL = session.youtubeURL

    feedbackAllowedAfterTimestamp = session.endTimestamp - Constants.feedbackTimeBeforeSessionEnd

    location = session.roomName
    roomId = session.roomId

    detail = session.detail
    tags = session.tags
    mainTag = session.mainTopic

    speakers = session.speakers
    .map { (speaker) -> ScheduleEventDetailsSpeakerViewModel in
      return ScheduleEventDetailsSpeakerViewModel(speaker, navigator: navigator)
    }

    isBookmarked = bookmarked
    isBookmarkable = !session.isKeynote

    self.isUserRegistered = isUserRegistered
    self.seatsAvailable = seatsAvailable

    isReservable = isUserRegistered && session.isReservable

    self.reservationStatus = reservationStatus
    self.clashDetector = clashDetector
  }

  private let clashDetector: ReservationClashDetector

  func rateSession() {
    navigator.navigateToFeedback(sessionID: id, title: title)
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
  let thumbnailURL: URL?
  let id: String
  let speaker: Speaker
  private let navigator: ScheduleNavigator

  init(_ speaker: Speaker, navigator: ScheduleNavigator) {
    self.navigator = navigator

    name = speaker.name
    company = speaker.company
    thumbnailURL = speaker.thumbnailURL
    id = speaker.id
    self.speaker = speaker
  }

  func selectSpeaker(speaker: Speaker) {
    navigator.navigateToSpeakerDetails(speaker: speaker, popToRoot: false)
  }
}
