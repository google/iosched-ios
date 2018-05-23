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
import FirebaseFirestore

/// A type responsible for transforming a list of sessions into conference days and maintaining
/// accessory state so the sessions can be displayed.
/// - SeeAlso: DefaultScheduleViewModel
protocol SessionListViewModel {

  /// A boolean indicating whether or not the viewmodel should only show saved items (reservations
  /// and bookmarks). Defaults to false.
  var shouldShowOnlySavedItems: Bool { get set }

  /// The filter view model for the schedule maintained by this instance. The filterViewModel
  /// can be modified to filter the schedule.
  var filterViewModel: ScheduleFilterViewModel { get }

  /// A list of days that are further broken down into time slots.
  /// - SeeAlso: ConferenceDayViewModel, ConferenceTimeSlotViewModel, SessionViewModel
  var conferenceDays: [ConferenceDayViewModel] { get }

  /// The slots within a given day, where each slot is a time period roughly one session long.
  /// Since Google I/O is a multi-track event, slots may contain multiple sessions.
  func slots(forDayWithIndex index: Int) -> [ConferenceTimeSlotViewModel]

  /// The sessions in a slot in a given day.
  /// - SeeAlso: SessionViewModel
  func events(forDayWithIndex dayIndex: Int, andSlotIndex slotIndex: Int) -> [SessionViewModel]

  /// Assigns a callback that will be invoked each time the view model updates its data in
  /// a way that would cause a UI change. The closure is retained by the receiver.
  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void)

  /// Called by the consumer of this class to indicate an update request, i.e. when the user swipes
  /// down to refresh data.
  func updateModel()

  /// Called by other classes to force a view refresh.
  func updateView()

  /// This method should be called when changing the status of a bookmark (star). Classes
  /// implementing this method should use it to write the changes somewhere and call any update
  /// methods that may be affected by the changes.
  func toggleBookmark(sessionID: String)

  /// This method should be called by the consumer of this type whenever a session is selected.
  /// Types that implement this protocol are then responsible for triggering the appropriate UI
  /// updates.
  func didSelectSession(_ session: SessionViewModel)

  /// This method takes a given session and returns a view controller showing that session's
  /// details.
  func detailsViewController(for session: SessionViewModel) -> UIViewController

  /// This method should be called when the user taps the filter button.
  func didSelectFilter()

  /// This method should be called when the account button is tapped.
  func didSelectAccount()
}

private enum Formatters {

  static let dateFormatter: DateFormatter = {
    let formatter = TimeZoneAwareDateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("MMMd")
    return formatter
  }()

  static let timeSlotFormatter: DateFormatter = {
    let formatter = TimeZoneAwareDateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

  static let dateIntervalFormatter: DateIntervalFormatter = {
    let formatter = DateIntervalFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

}

class DefaultSessionListViewModel: SessionListViewModel {

  init(sessionsDataSource: LazyReadonlySessionsDataSource,
       bookmarkDataSource: RemoteBookmarkDataSource,
       reservationDataSource: RemoteReservationDataSource,
       navigator: ScheduleNavigator) {
    self.sessionsDataSource = sessionsDataSource
    self.bookmarkDataSource = bookmarkDataSource
    self.reservationDataSource = reservationDataSource
    self.navigator = navigator
    filterViewModel = ScheduleFilterViewModel()

    conferenceDays = []

    registerForTimezoneUpdates()
    registerForBookmarkUpdates()
    registerForReservationsUpdates()

    updateModel()
  }

  lazy private var clashDetector = ReservationClashDetector(sessions: sessionsDataSource,
                                                            reservations: reservationDataSource)

  // MARK: - View updates
  var viewUpdateCallback: ((_ indexPath: IndexPath?) -> Void)?
  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void) {
    self.viewUpdateCallback = viewUpdateCallback
    updateModel()
  }

  func updateView() {
    viewUpdateCallback?(nil)
  }

  deinit {
    timezoneObserver = nil
    bookmarkObserver = nil
    reservationsObserver = nil
  }

  // MARK: - Dependencies
  fileprivate let sessionsDataSource: LazyReadonlySessionsDataSource
  internal let bookmarkDataSource: RemoteBookmarkDataSource
  internal let reservationDataSource: RemoteReservationDataSource
  internal let navigator: ScheduleNavigator

  // MARK: - Output
  private lazy var savedItemsViewModel: SavedItemsViewModel = {
    return SavedItemsViewModel(reservations: reservationDataSource,
                               bookmarks: bookmarkDataSource)
  }()
  var filterViewModel: ScheduleFilterViewModel
  private(set) var conferenceDays: [ConferenceDayViewModel]

  var shouldShowOnlySavedItems: Bool {
    get {
      return savedItemsViewModel.shouldShowOnlySavedItems
    }
    set {
      savedItemsViewModel.shouldShowOnlySavedItems = newValue
    }
  }

  func slots(forDayWithIndex index: Int) -> [ConferenceTimeSlotViewModel] {
    return conferenceDays.count > 0 ? conferenceDays[index].slots : []
  }

  func events(forDayWithIndex dayIndex: Int, andSlotIndex slotIndex: Int) -> [SessionViewModel] {
    let unfilteredEvents = slots(forDayWithIndex: dayIndex)[slotIndex].events
    if filterViewModel.isEmpty && !savedItemsViewModel.shouldShowOnlySavedItems {
      return unfilteredEvents
    } else {
      return unfilteredEvents.filter { event -> Bool in
        return filterViewModel.shouldShow(topics: event.topics,
                                          levels: event.levels,
                                          types: event.types) &&
            savedItemsViewModel.shouldShow(event.session)
      }
    }
  }

  func updateModel() {
    populateConferenceDays()
    updateView()
  }

  // MARK: - Timezone observing
  private func timeZoneUpdated() {
    updateFormatters()
    updateModel()
  }

  private func updateFormatters() {
    Formatters.dateFormatter.timeZone = TimeZone.userTimeZone()
    Formatters.timeSlotFormatter.timeZone = TimeZone.userTimeZone()
    Formatters.dateIntervalFormatter.timeZone =  TimeZone.userTimeZone()
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
      guard let self = self else { return }
      self.bookmarksUpdated()
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

}

// MARK: - Actions
extension DefaultSessionListViewModel {
  func didSelectSession(_ viewModel: SessionViewModel) {
    navigator.navigate(to: viewModel.session, popToRoot: false)
  }

  func detailsViewController(for viewModel: SessionViewModel) -> UIViewController {
    return navigator.detailsViewController(for: viewModel.session)
  }

  func toggleBookmark(sessionID: String) {
    bookmarkDataSource.toggleBookmark(sessionID: sessionID)
  }

  func didSelectFilter() {
    navigator.navigateToFilter(viewModel: filterViewModel, callback: {
      self.updateView()
    })
  }

  func didSelectAccount() {
    navigator.navigateToAccount()
  }
}

// MARK: - Transformer
extension DefaultSessionListViewModel {

  /// This method transforms all inputs into the correct output
  func conferenceDays(from allSessions: [Session]) -> [ConferenceDayViewModel] {
    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = TimeZone.userTimeZone()

    let allDates = allSessions.map { event -> Date in
      return calendar.startOfDay(for: event.startTimestamp)
    }
    let uniqueDates = Set(allDates)

    // create view models for the individual days
    return uniqueDates.map { date -> ConferenceDayViewModel in
      let eventsInThisDay = allSessions.filter { event -> Bool in
        return calendar.isDate(event.startTimestamp, inSameDayAs: date)
      }

      let hours = eventsInThisDay.map { $0.startTimestamp }
      let uniqueHours = Set(hours)

      let slots = uniqueHours.map { time -> ConferenceTimeSlotViewModel in
        let eventsInThisTimeSlot = eventsInThisDay.filter { $0.startTimestamp == time }

        let eventsViewModels = eventsInThisTimeSlot.map { timedDetailedEvent -> SessionViewModel in
          return SessionViewModel(session: timedDetailedEvent,
                                  bookmarkDataSource: bookmarkDataSource,
                                  reservationDataSource: reservationDataSource,
                                  clashDetector: clashDetector,
                                  scheduleNavigator: navigator)
          }.sorted(by: <)

        return ConferenceTimeSlotViewModel(time: time, events: eventsViewModels)
      }.sorted(by: < )

      return ConferenceDayViewModel(day: date, slots: slots)
      }
      .sorted(by: < )
  }

  /// Generates a list of conference days from sessions in the sessions data source.
  func populateConferenceDays() {
    conferenceDays = conferenceDays(from: sessionsDataSource.sessions)
  }
}

// MARK: - View Models

/// A type responsible for aggregating events by day.
struct ConferenceDayViewModel {
  let day: Date
  let slots: [ConferenceTimeSlotViewModel]

  init(day: Date, slots: [ConferenceTimeSlotViewModel]) {
    self.day = day
    self.slots = slots
  }
}

extension ConferenceDayViewModel {
  var dayString: String {
    return Formatters.dateFormatter.string(from: day)
  }
}

extension ConferenceDayViewModel: Comparable { }

func == (lhs: ConferenceDayViewModel, rhs: ConferenceDayViewModel) -> Bool {
  return lhs.day == rhs.day
}

func < (lhs: ConferenceDayViewModel, rhs: ConferenceDayViewModel) -> Bool {
  return lhs.day < rhs.day
}

/// A struct responsible for aggregating events that occur at the same time. In the
/// schedule UI, this struct is also responsible for displaying the section header
/// titles (which are times).
struct ConferenceTimeSlotViewModel {
  let time: Date
  var timeSlotString: String
  let events: [SessionViewModel]

  init(time: Date, events: [SessionViewModel]) {
    self.time = time
    self.events = events

    self.timeSlotString = Formatters.timeSlotFormatter.string(from: time)
  }
}

extension ConferenceTimeSlotViewModel: Comparable { }

func == (lhs: ConferenceTimeSlotViewModel, rhs: ConferenceTimeSlotViewModel) -> Bool {
  return lhs.time == rhs.time
    && lhs.events == rhs.events
}

func < (lhs: ConferenceTimeSlotViewModel, rhs: ConferenceTimeSlotViewModel) -> Bool {
  return lhs.time < rhs.time
}

/// A type responsible for connecting sessions and session state (like reservation/star status).
/// This type is also responsible for transforming struct data into more UI-friendly types.
class SessionViewModel {

  private enum Constants {
    static let sessionBookmarkedImage = UIImage(named: "ic_session_bookmarked")!
    static let sessionBookmarkImage = UIImage(named: "ic_session_bookmark-dark")!

    static let sessionReservedImage = UIImage(named: "ic_session_reserved")!
    static let sessionWaitlistedImage = UIImage(named: "ic_waitlisted")!
    static let sessionNotReservedImage = UIImage(named: "ic_session_reserve-dark")!
  }

  // Dependencies
  let session: Session
  let formattedDateInterval: String
  let location: String
  let signIn: SignInInterface
  let reservationService: FirebaseReservationServiceInterface
  var timeAndLocation: String {
    let separator = location.isEmpty ? "" : " / "
    return[formattedDateInterval, location].joined(separator: separator)
  }
  private let reservationDataSource: RemoteReservationDataSource
  private let bookmarkDataSource: RemoteBookmarkDataSource
  private let clashDetector: ReservationClashDetector
  private let navigator: ScheduleNavigator

  /// Returns the user's reservation status for this session.
  var reservationStatus: ReservationStatus {
    return reservationDataSource.reservationStatus(for: session.id)
  }

  var bookmarkButtonImage: UIImage {
    return isBookmarked
      ? Constants.sessionBookmarkedImage
      : Constants.sessionBookmarkImage
  }

  var bookmarkButtonAccessibilityLabel: String {
    return isBookmarked
      ? NSLocalizedString("Session is bookmarked. Tap to remove bookmark.",
                          comment: "Accessibility hint for bookmark button, bookmarked state")
      : NSLocalizedString("Session is not bookmarked. Tap to add bookmark.",
                          comment: "Accessibility hint for bookmark button, non-bookmarked state.")
  }

  var isReservable: Bool {
    return signIn.currentUser != nil && session.isReservable
  }

  var reserveButtonImage: UIImage? {
    switch reservationStatus {
    case .reserved:
      return Constants.sessionReservedImage
    case .waitlisted:
      return Constants.sessionWaitlistedImage
    case .none:
      return Constants.sessionNotReservedImage
    }
  }

  var reserveButtonAccessibilityLabel: String {
    switch reservationStatus {
    case .reserved:
      return NSLocalizedString("This session is reserved. Double-tap to cancel reservation.",
                               comment: "Icon accessibility label for reserved session button")
    case .waitlisted:
      return NSLocalizedString("This session is waitlisted. Double-tap to cancel whitelisting.",
                               comment: "Icon accessibility label for waitlisted session button")
    case .none:
      return NSLocalizedString("This session is not reserved. Double-tap to reserve.",
                               comment: "Button icon accessibility label for no session reservation")
    }
  }

  init(session: Session,
       bookmarkDataSource: RemoteBookmarkDataSource,
       reservationDataSource: RemoteReservationDataSource,
       clashDetector: ReservationClashDetector,
       scheduleNavigator: ScheduleNavigator,
       signIn: SignInInterface = SignIn.sharedInstance) {
    self.session = session
    self.bookmarkDataSource = bookmarkDataSource
    self.signIn = signIn
    self.reservationDataSource = reservationDataSource
    self.reservationService = FirestoreReservationService(sessionID: session.id)
    navigator = scheduleNavigator

    formattedDateInterval = Formatters.dateIntervalFormatter.string(from: session.startTimestamp,
                                                                    to: session.endTimestamp)
    location = session.roomName
    self.clashDetector = clashDetector
  }

  var startTimeStamp: Date {
    return session.startTimestamp
  }

  var title: String {
    return session.title
  }

  var tags: [EventTag] {
    return session.tags
  }

  var topics: [EventTag] {
    return tags.filter { $0.type == .topic }
  }

  var levels: [EventTag] {
    return tags.filter { $0.type == .level }
  }

  var types: [EventTag] {
    return tags.filter { $0.type == .type }
  }

  var isBookmarked: Bool {
    return bookmarkDataSource.isBookmarked(sessionID: id)
  }

  var id: String {
    return session.id
  }

  func reserve() {
    reservationService.attemptReservation()
  }

  func cancelReservation() {
    reservationService.attemptCancellation()
  }

  func attemptReservationAction() {
    startObservingReservationResult()
    reservationService.attemptReservation()
  }

  private func startObservingReservationResult() {
    _ = reservationService.onReservationResultUpdate { reservationResult in
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

      self.stopObservingReservationResults()
    }
  }

  private func stopObservingReservationResults() {
    reservationService.removeUpdateListeners()
  }

  private func handleClash() {
    let clashes = clashDetector.clashes(for: session)
    switch clashes.count {
    case 0:
      break
    case 1:
      guard let clash = clashes.first else { return }
      navigator.showReservationClashDialog {
        self.reservationService.attemptSwap(withConflictingSessionID: clash.id)
      }
    case _:
      navigator.showMultiClashDialog()
    }
  }

}

extension SessionViewModel: Comparable { }

func == (lhs: SessionViewModel, rhs: SessionViewModel) -> Bool {
  return lhs.id == rhs.id &&
    lhs.timeAndLocation == rhs.timeAndLocation &&
    lhs.tags == rhs.tags &&
    lhs.reservationStatus == rhs.reservationStatus
}

func < (lhs: SessionViewModel, rhs: SessionViewModel) -> Bool {
  return lhs.title < rhs.title
}

extension SessionViewModel: Hashable {

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(title)
    hasher.combine(timeAndLocation)
  }

}
