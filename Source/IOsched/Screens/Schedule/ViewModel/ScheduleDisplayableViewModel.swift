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

import UIKit
import MaterialComponents

class ScheduleDisplayableViewModel: NSObject, UICollectionViewDataSource {

  private(set) var wrappedModel: SessionListViewModel

  /// A map to store cell height calculations for faster layout. This is invalidated whenever the
  /// user's device font size changes.
  fileprivate var cachedHeights: [SessionViewModel: CGFloat] = [:]

  lazy var measureCell: ScheduleViewCollectionViewCell = self.setupMeasureCell()

  private func setupMeasureCell() -> ScheduleViewCollectionViewCell {
    return ScheduleViewCollectionViewCell(frame: CGRect())
  }

  @available(*, unavailable)
  override init() {
    fatalError("Use init(wrappedModel:)")
  }

  init(wrappedModel: SessionListViewModel) {
    self.wrappedModel = wrappedModel
    super.init()
  }

  var conferenceDays: [ConferenceDayViewModel] {
    return wrappedModel.conferenceDays
  }

  func filterSelected() {
    wrappedModel.didSelectFilter()
  }

  func didSelectAccount() {
    wrappedModel.didSelectAccount()
  }

  func showOnlySavedEvents() {
    wrappedModel.shouldShowOnlySavedItems = true
  }

  func showAllEvents() {
    wrappedModel.shouldShowOnlySavedItems = false
  }

// MARK: - ScheduleViewModelLayout

  func sizeForHeader(inSection section: Int, inFrame frame: CGRect) -> CGSize {
    guard eventsForSection(section).count > 0 else { return .zero }
    return CGSize(width: frame.size.width, height: MDCCellDefaultOneLineHeight)
  }

  func heightForCell(at indexPath: IndexPath, inFrame frame: CGRect) -> CGFloat {
    let session = self.session(for: indexPath)
    if let cached = cachedHeights[session] {
      return cached
    }

    measureCell.bounds = frame
    measureCell.contentView.bounds = frame
    populateCell(measureCell, forItemAt: indexPath)

    let height = measureCell.heightForContents(maxWidth: frame.size.width)
    cachedHeights[session] = height
    return height
  }

  func invalidateHeights() {
    cachedHeights = [:]
  }

// MARK: - UICollectionViewDataSource

  private func slotForSection(_ section: Int) -> ConferenceTimeSlotViewModel {
    let days = wrappedModel.conferenceDays.count
    var section = section
    for i in 0 ..< days {
      let slots = wrappedModel.slots(forDayWithIndex: i)
      if slots.count <= section {
        section -= slots.count
      } else {
        return slots[section]
      }
    }
    let totalSections = conferenceDays.reduce(0) { $0 + $1.slots.count }
    fatalError("Section out of bounds: \(section), days: \(totalSections)")
  }

  private func eventsForSection(_ section: Int) -> [SessionViewModel] {
    let days = wrappedModel.conferenceDays.count
    var section = section
    for i in 0 ..< days {
      let slots = wrappedModel.slots(forDayWithIndex: i)
      if slots.count <= section {
        section -= slots.count
      } else {
        let dayIndex = i
        let slotIndex = section
        return wrappedModel.events(forDayWithIndex: dayIndex, andSlotIndex: slotIndex)
      }
    }
    return []
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    // Treat the wrapped model's data as a single view, where breaks between
    // days are special index paths that can be navigated to via tab bar buttons above the
    // collection view. Individual sections represent time slots in each day.
    var totalSlots = 0
    for i in 0 ..< conferenceDays.count {
      let slots = wrappedModel.slots(forDayWithIndex: i)
      totalSlots += slots.count
    }
    return totalSlots
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    let items = eventsForSection(section).count
    return items
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ScheduleViewCollectionViewCell.reuseIdentifier(),
      for: indexPath
    )
    populateCell(cell, forItemAt: indexPath)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {
    let view = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind,
      withReuseIdentifier: ScheduleSectionHeaderReusableView.reuseIdentifier(),
      for: indexPath
    )
    if kind == UICollectionView.elementKindSectionHeader,
        let headerView = view as? ScheduleSectionHeaderReusableView {
      view.isHidden =
          self.collectionView(collectionView, numberOfItemsInSection: indexPath.section) == 0
      populateSupplementaryView(headerView, forItemAt: indexPath)
    }
    return view
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    didSelectItemAt(indexPath: indexPath)
  }

  private func session(for indexPath: IndexPath) -> SessionViewModel {
    let events = eventsForSection(indexPath.section)
    return events[indexPath.item]
  }

  func populateCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard let cell = cell as? ScheduleViewCollectionViewCell else { return }
    let session = self.session(for: indexPath)
    cell.viewModel = session
    cell.isUserInteractionEnabled = true
    cell.onBookmarkTapped { sessionID in
      self.wrappedModel.toggleBookmark(sessionID: sessionID)
    }
  }

  func populateSupplementaryView(_ view: ScheduleSectionHeaderReusableView,
                                 forItemAt indexPath: IndexPath) {
    let slot = slotForSection(indexPath.section)
    view.date = slot.time
  }

  func didSelectItemAt(indexPath: IndexPath) {
    let event = session(for: indexPath)
    wrappedModel.didSelectSession(event)
  }

  func previewViewControllerForItemAt(indexPath: IndexPath) -> UIViewController? {
    let event = session(for: indexPath)
    return wrappedModel.detailsViewController(for: event)
  }

  func isEmpty() -> Bool {
    for i in 0 ..< wrappedModel.conferenceDays.count {
      if !isEmpty(forDayWithIndex: i) {
        return false
      }
    }
    return true
  }

  func isEmpty(forDayWithIndex index: Int) -> Bool {
    let slots = wrappedModel.slots(forDayWithIndex: index)
    guard !slots.isEmpty else { return true }
    for i in 0 ..< slots.count {
      let eventCount = wrappedModel.events(forDayWithIndex: index, andSlotIndex: i).count
      if eventCount > 0 {
        return false
      }
    }
    return true
  }

  func dayForSection(_ section: Int) -> Int {
    var section = section
    for i in 0 ..< wrappedModel.conferenceDays.count {
      let sectionsInDay = wrappedModel.slots(forDayWithIndex: i).count
      if section < sectionsInDay {
        return i
      }
      section -= sectionsInDay
    }
    let total = wrappedModel.conferenceDays.reduce(0) { $0 + $1.slots.count }
    fatalError("Section out of bounds: \(section), total sections across all days: \(total)")
  }

// MARK: - View updates

  var viewUpdateCallback: ((_ indexPath: IndexPath?) -> Void)?
  func onUpdate(_ viewUpdateCallback: @escaping (_ indexPath: IndexPath?) -> Void) {
    wrappedModel.onUpdate { indexPath in
      viewUpdateCallback(indexPath)
    }
  }

  func updateModel() {
    wrappedModel.updateModel()
  }

  func indexPath(forDay day: Int) -> IndexPath? {
    guard day < wrappedModel.conferenceDays.count && day >= 0 else { return nil }
    guard !isEmpty(forDayWithIndex: day) else { return nil }
    var sectionForDay = 0
    for i in 0 ..< day {
      sectionForDay += wrappedModel.slots(forDayWithIndex: i).count
    }
    let totalDaySlots = wrappedModel.slots(forDayWithIndex: day).count
    var sectionInDay = 0
    while wrappedModel.events(forDayWithIndex: day, andSlotIndex: sectionInDay).isEmpty {
      if sectionInDay >= totalDaySlots { return nil }
      sectionInDay += 1
    }
    let section = sectionForDay + sectionInDay
    return IndexPath(item: 0, section: section)
  }

  func collectionView(_ collectionView: UICollectionView,
                      scrollToDay day: Int,
                      animated: Bool = true) {
    if let indexPath = indexPath(forDay: day) {
      collectionView.scrollToItem(at: indexPath, at: .top, animated: animated)
    }
  }

}
