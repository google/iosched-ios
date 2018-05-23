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

protocol ScheduleViewModel {
  var filterViewModel: ScheduleFilterViewModel { get }
  var conferenceDays: [ConferenceDayViewModel] { get }
  func slots(forDayWithIndex index: Int) -> [ConferenceTimeSlotViewModel]?
  func events(forDayWithIndex dayIndex: Int, andSlotIndex slotIndex: Int) -> [ConferenceEventViewModel]?

  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void)
  func updateModel()
  func updateView(at indexPath: IndexPath?)

  func isBookmarkNotificationSuppressed(isBookmarked: Bool) -> Bool
  func suppressBookmarkedNotification(isBookmarked: Bool)

  func toggleBookmark(sessionId: String)
  func didSelectSession(_ session: ConferenceEventViewModel)
  func detailsViewController(for session: ConferenceEventViewModel) -> UIViewController
  func didSelectFilter()
  func addEventsSelected(day: Int)
}

private enum Formatters {
  static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.setLocalizedDateFormatFromTemplate("MMMd")
    return formatter
  }()

  static let timeSlotFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

  static let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.userTimeZone()
    return formatter
  }()

}

class DefaultScheduleViewModel: ScheduleViewModel {

  fileprivate enum Constants {
    static let day0: Date = {
      var components = DateComponents()
      components.year = 2017
      components.month = 5
      components.day = 16
      var calendar = Calendar.current
      calendar.timeZone = TimeZone.userTimeZone()
      return calendar.date(from: components)!
    }()
  }

  init(conferenceDataSource: ConferenceDataSource,
       bookmarkStore: WritableBookmarkStore,
       reservationStore: ReadonlyReservationStore,
       userState: WritableUserState,
       rootNavigator: RootNavigator,
       navigator: ScheduleNavigator) {
    self.conferenceDataSource = conferenceDataSource
    self.bookmarkStore = bookmarkStore
    self.reservationStore = reservationStore
    self.userState = userState
    self.rootNavigator = rootNavigator
    self.navigator = navigator
    filterViewModel = ScheduleFilterViewModel(conferenceDataSource: self.conferenceDataSource,
                                              navigator: navigator)

    conferenceDays = []

    registerForTimezoneUpdates()
    registerForBookmarkUpdates()
    registerForReservationsUpdates()

    updateModel()
  }

  func isBookmarkNotificationSuppressed(isBookmarked: Bool) -> Bool {
    return isBookmarked ?
      userState.isBookmarkNotificationSuppressed :
      userState.isUnbookmarkNotificationSuppressed
  }

  func suppressBookmarkedNotification(isBookmarked: Bool) {
    if isBookmarked {
      userState.setBookmarkNotificationSuppressed(true)
    } else {
      userState.setUnbookmarkNotificationSuppressed(true)
    }
  }

  func notifyViewOfBookmark(isBookmarked: Bool) {
    DispatchQueue.main.async { [weak self] in
      self?.navigator.showBookmarkToast(viewModel: self, isBookmarked: isBookmarked)
    }
  }

  // MARK: - View updates
  var viewUpdateCallback: ((_ indexPath: IndexPath?) -> Void)?
  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void) {
    self.viewUpdateCallback = viewUpdateCallback
    updateModel()
  }

  func updateView(at indexPath: IndexPath? = nil) {
    DispatchQueue.main.async { [weak self] in
      self?.viewUpdateCallback?(indexPath)
    }
  }

  deinit {
    timezoneObserver = nil
    bookmarkObserver = nil
    reservationsObserver = nil
  }

  // MARK: - Dependencies
  fileprivate var conferenceDataSource: ConferenceDataSource
  internal let bookmarkStore: WritableBookmarkStore
  internal let reservationStore: ReadonlyReservationStore
  internal let userState: WritableUserState
  internal let rootNavigator: RootNavigator
  internal let navigator: ScheduleNavigator

  // MARK: - Output
  var filterViewModel: ScheduleFilterViewModel
  var conferenceDays: [ConferenceDayViewModel]

  func slots(forDayWithIndex index: Int) -> [ConferenceTimeSlotViewModel]? {
    return conferenceDays.count > 0 ? conferenceDays[index].slots : []
  }

  func events(forDayWithIndex dayIndex: Int, andSlotIndex slotIndex: Int) -> [ConferenceEventViewModel]? {
    guard let unfilteredEvents = slots(forDayWithIndex: dayIndex)?[slotIndex].events else { return nil }
    return unfilteredEvents.filter { event -> Bool in
      return filterViewModel.shouldShow(tags: event.tags,
                                        levels: event.levels,
                                        themes: event.themes,
                                        isLiveStream: event.isLivestream,
                                        isSession: event.isSession)
    }
  }

  func updateModel() {
    DispatchQueue.global().async { [weak self] in
      self?.transform()
      DispatchQueue.main.async { [weak self] in
        self?.updateView()
      }
    }
  }

  // MARK: - Timezone observing
  private func timeZoneUpdated() {
    updateFormatters()
    updateModel()
  }

  private func updateFormatters() {
    Formatters.dateFormatter.timeZone = TimeZone.userTimeZone()
    Formatters.timeSlotFormatter.timeZone = TimeZone.userTimeZone()
    Formatters.timeFormatter.timeZone =  TimeZone.userTimeZone()
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
                                                              queue: nil) { [weak self] notification in
      guard self != nil else { return }
      if let isBookmarked = notification.userInfo?[BookmarkUpdates.isBookmarked] as? Bool {
        self?.notifyViewOfBookmark(isBookmarked: isBookmarked)
      }
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

}

// MARK: - Actions
extension DefaultScheduleViewModel {
  func didSelectSession(_ session: ConferenceEventViewModel) {
    navigator.navigateToSessionDetails(sessionId: session.id, popToRoot: false)
  }

  func detailsViewController(for session: ConferenceEventViewModel) -> UIViewController {
    return navigator.detailsViewController(for: session.id)
  }

  func toggleBookmark(sessionId: String) {
    DispatchQueue.global().async {
      self.bookmarkStore.toggleBookmark(sessionId: sessionId)
    }
  }

  func didSelectFilter() {
    navigator.navigateToFilter(viewModel: filterViewModel, callback: {
      self.updateView()
    })
  }

  func addEventsSelected(day: Int) {
    rootNavigator.navigateToSchedule(day: day)
  }

  func accountSelected() {
    navigator.navigateToAccount()
  }
}

extension Date {
  private enum Constants {
    static let userTimeFlags: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .timeZone]
    static let userDateFlags: Set<Calendar.Component> = [.year, .month, .day, .timeZone]
  }

  private var calendar: Calendar {
    return TimeZoneAwareCalendar.autoupdatingCurrent
  }

  var userTimeZoneTime: Date {
    let components = calendar.dateComponents(Constants.userTimeFlags, from: self)
    return calendar.date(from: components)!
  }

}

// MARK: - Transformer
extension DefaultScheduleViewModel {

  /// This method transforms all inputs into the correct output
  func transform() {
    let allEvents = conferenceDataSource.allEvents

    var calendar = Calendar.autoupdatingCurrent
    calendar.timeZone = TimeZone.userTimeZone()

    let allDates = allEvents.map { event -> Date in
      return calendar.startOfDay(for: event.startTimestamp)
    }
    let uniqueDates = distinct2(allDates)

    // create view models for the individual days
    conferenceDays = uniqueDates.map { date -> ConferenceDayViewModel in
      let eventsInThisDay = allEvents.filter { event -> Bool in
        return calendar.isDate(event.startTimestamp, inSameDayAs: date)
      }

      let hours = eventsInThisDay.map { $0.startTimestamp }
      let uniqueHours = distinct2(hours)

      let slots = uniqueHours.map { time -> ConferenceTimeSlotViewModel in
        let eventsInThisTimeSlot = eventsInThisDay.filter { $0.startTimestamp == time }

        let eventsViewModels = eventsInThisTimeSlot.map { timedDetailedEvent -> ConferenceEventViewModel in
          return ConferenceEventViewModel(event: timedDetailedEvent,
                                          conferenceDataSource: conferenceDataSource,
                                          bookmarkStore: bookmarkStore,
                                          reservationStore: reservationStore)
          }.sorted(by: <)

        return ConferenceTimeSlotViewModel(time: time, events: eventsViewModels)
      }.sorted(by: < )

      return ConferenceDayViewModel(day: date, slots: slots)
      }
      .filter { $0.day != Constants.day0 }
      .sorted(by: < )

  }
}

func distinct2<T: Equatable>(_ source: [T]) -> [T] {
    var unique = [T]()
    source.forEach { item in
        if !unique.contains(item) {
            unique.append(item)
        }
    }
    return unique
}

// MARK: - View Models

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

struct ConferenceTimeSlotViewModel {
  let time: Date
  var timeSlotString: String
  let events: [ConferenceEventViewModel]

  init(time: Date, events: [ConferenceEventViewModel]) {
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

struct ConferenceEventViewModel {

  private enum Constants {
    static let blockId = "__block_id__"

    static let sessionBookmarkedImage = UIImage(named: "ic_session_bookmarked")!
    static let sessionBookmarkImage = UIImage(named: "ic_session_bookmark-dark")!

    static let sessionReservedImage = UIImage(named: "ic_session_reserved")!
    static let sessionWaitlistedImage = UIImage(named: "ic_waitlisted")!
  }

  let id: String
  let title: String
  let startTimeStamp: Date
  let timeAndLocation: String
  let tags: [TagEventViewModel]
  let levels: [LevelEventViewModel]
  let themes: [ThemeEventViewModel]
  let isLivestream: Bool
  let isSession: Bool

  private let conferenceDataSource: ConferenceDataSource

  private let reservationStore: ReadonlyReservationStore

  /// Whether the user has reserved a seat for this session
  var reservationStatus: ReservationStatus {
    return self.reservationStore.reservationStatus(sessionId: id)
  }

  /// Some sessions (such as meals and badge pickup) are not bookmarkable
  let isBookmarkable: Bool

  /// Some sessions (such as badge pick up, meal breaks) don't have any details to navigate to
  let isNavigatable: Bool

  private let bookmarkStore: WritableBookmarkStore
  var isBookmarked: Bool = false

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

  var reservedIconImage: UIImage? {
    switch reservationStatus {
    case .reserved:
      return Constants.sessionReservedImage
    case .waitlisted:
      return Constants.sessionWaitlistedImage
    default:
      return nil
    }
  }

  var reservedLabel: String {
    switch reservationStatus {
    case .reserved:
      return NSLocalizedString("RESERVED",
                               comment: "Reserved status for sessions")
    case .waitlisted:
      return NSLocalizedString("WAITLISTED",
                               comment: "Waitlisted status for sessions")
    default:
      return NSLocalizedString("UNKNOWN",
                               comment: "Unknown reservation status session")
    }
  }

  var reservedIconAccessibilityLabel: String {
    switch reservationStatus {
    case .reserved:
      return NSLocalizedString("Session is reserved.",
                               comment: "Accessibility hint for reserved session")
    case .waitlisted:
      return NSLocalizedString("Session is waitlisted.",
                               comment: "Accessibility hint for waitlisted session")
    default:
      return NSLocalizedString("Unknown reservation status",
                               comment: "Accessibility hint for unknown reservation status session")
    }
  }

  let isBreak: Bool
  let isConcert: Bool
  let isMeal: Bool

  var breakIconImage: UIImage? {
    if isConcert {
      return UIImage(named: "concert")!
    }
    if isMeal {
      return UIImage(named: "food")!
    }
    return nil
  }

  var breakIconAccessibilityLabel: String? {
    if isConcert {
      return NSLocalizedString("Concert", comment: "Concert")
    }
    if isMeal {
      return NSLocalizedString("Food break", comment: "Food break")
    }
    return nil
  }

  init(event: TimedDetailedEvent,
       conferenceDataSource: ConferenceDataSource,
       bookmarkStore: WritableBookmarkStore,
       reservationStore: ReadonlyReservationStore) {
    self.conferenceDataSource = conferenceDataSource
    self.bookmarkStore = bookmarkStore
    self.reservationStore = reservationStore

    title = event.title
    startTimeStamp = event.startTimestamp

    let startTime = Formatters.timeFormatter.string(from: event.startTimestamp)
    let endTime = Formatters.timeFormatter.string(from: event.endTimestamp)
    let timeSpan = "\(startTime) - \(endTime)"

    if let session = event as? Session {
      id = session.id

      isBookmarked = self.bookmarkStore.isBookmarked(sessionId: id)

      let room = conferenceDataSource.room(by: session.roomId)
      let roomName = room?.name ?? ""
      let separator = roomName.isEmpty ? "" : " / "
      timeAndLocation = [timeSpan, roomName].joined(separator: separator)

      tags = conferenceDataSource.allTopics.filter { conferenceTag -> Bool in
        return session.tagNames.contains(conferenceTag.name)
      }.map { conferenceTag -> TagEventViewModel in
        let colorHex = conferenceTag.colorString ?? "#efefef"
        return TagEventViewModel(name: conferenceTag.name, color: colorHex)
      }

      levels = conferenceDataSource.allLevels.filter { conferenceTag -> Bool in
        if conferenceTag.type == .level {
          return session.tagNames.contains(conferenceTag.name)
        }
        return false
        }.map { conferenceTag -> LevelEventViewModel in
          if conferenceTag.type == .level {
            return LevelEventViewModel(name: conferenceTag.name)
          }
          return LevelEventViewModel(name: "(unknown)")
      }

      themes = conferenceDataSource.allTypes.filter { conferenceTag -> Bool in
        return session.tagNames.contains(conferenceTag.name)
      }.map { conferenceTag -> ThemeEventViewModel in
        return ThemeEventViewModel(name: conferenceTag.name)
      }

      isNavigatable = true
      isBookmarkable = !session.isKeynote
      isBreak = false
      isMeal = false
      isConcert = false
      isLivestream = session.isLivestream || session.youtubeUrl != nil
      isSession = true
    }
    else if let block = event as? Block {
      id = Constants.blockId
      let detail = block.detail
      let separator = detail.isEmpty ? "" : " / "
      timeAndLocation = [timeSpan, detail].joined(separator: separator)
      tags = [TagEventViewModel]()
      levels = [LevelEventViewModel]()
      themes = [ThemeEventViewModel]()
      isNavigatable = false
      isBookmarkable = false
      isBreak = block.isBreak
      isMeal = block.isMeal
      isConcert = block.isConcert
      isLivestream = false
      isSession = false
    }
    else {
      fatalError("Event must either be of type Session or Block")
    }
  }
}

extension ConferenceEventViewModel: Comparable { }

func == (lhs: ConferenceEventViewModel, rhs: ConferenceEventViewModel) -> Bool {
  return lhs.id == rhs.id &&
    lhs.timeAndLocation == rhs.timeAndLocation &&
    lhs.tags == rhs.tags &&
    lhs.isLivestream == rhs.isLivestream &&
    lhs.isSession == rhs.isSession &&
    lhs.reservationStatus == rhs.reservationStatus &&
    lhs.isBookmarkable == rhs.isBookmarkable &&
    lhs.isNavigatable == rhs.isNavigatable
}

func < (lhs: ConferenceEventViewModel, rhs: ConferenceEventViewModel) -> Bool {
  return lhs.startTimeStamp < rhs.startTimeStamp
}

extension ConferenceEventViewModel: Hashable {
  var hashValue: Int {
    return id.hashValue ^ title.hashValue ^ timeAndLocation.hashValue
  }
}

struct TagEventViewModel {
  let name: String
  let color: String
}

struct LevelEventViewModel {
  let name: String
}

struct ThemeEventViewModel {
  let name: String
}

extension TagEventViewModel: Equatable {
  static func == (lhs: TagEventViewModel, rhs: TagEventViewModel) -> Bool {
    return lhs.name == rhs.name && lhs.color == rhs.color
  }
}
