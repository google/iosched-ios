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

class ScheduleDisplayableViewModel {

  private(set) var wrappedModel: ScheduleViewModel
  var selectedDay = 0

  /// A map to store cell height calculations for faster layout. This is invalidated whenever the
  /// user's device font size changes.
  fileprivate var cachedHeights: [SessionViewModel: CGFloat] = [:]

  lazy var measureCell: ScheduleViewCollectionViewCell = self.setupMeasureCell()

  private func setupMeasureCell() -> ScheduleViewCollectionViewCell {
    return ScheduleViewCollectionViewCell(frame: CGRect())
  }

  init(wrappedModel: ScheduleViewModel) {
    self.wrappedModel = wrappedModel
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
    return CGSize(width: frame.size.width, height: MDCCellDefaultOneLineHeight)
  }

  func heightForCell(at indexPath: IndexPath, inFrame frame: CGRect) -> CGFloat {
    guard let session = session(forIndexPath: indexPath) else { return 0 }
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

  func backgroundColor(at indexPath: IndexPath) -> UIColor {
    return .white
  }

// MARK: - ScheduleViewModelDataSource

  func numberOfSections() -> Int {
    return wrappedModel.slots(forDayWithIndex: selectedDay).count
  }

  func numberOfItemsIn(section: Int) -> Int {
    return wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: section).count
  }

  func cellClassForItemAt(indexPath: IndexPath) -> UICollectionViewCell.Type {
    return ScheduleViewCollectionViewCell.self
  }

  func session(forIndexPath indexPath: IndexPath) -> SessionViewModel? {
    let events = wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: indexPath.section)
    guard indexPath.row < events.count else {
      return nil
    }
    return events[indexPath.row]
  }

  func populateCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard let cell = cell as? ScheduleViewCollectionViewCell else { return }
    if let session = session(forIndexPath: indexPath) {
      cell.viewModel = session
      cell.isUserInteractionEnabled = true
      cell.onBookmarkTapped { sessionID in
        self.wrappedModel.toggleBookmark(sessionID: sessionID)
      }
    }
  }

  func supplementaryViewClass(ofKind kind: String,
                              forItemAt indexPath: IndexPath) -> UICollectionReusableView.Type {
    return IOSchedCollectionViewHeaderCell.self
  }

  func populateSupplementaryView(_ view: UICollectionReusableView, forItemAt indexPath: IndexPath) {
    if let sectionHeader = view as? IOSchedCollectionViewHeaderCell {
      let slot = wrappedModel.slots(forDayWithIndex: selectedDay)[indexPath.section]
      sectionHeader.date = slot.time
    }
  }

  func didSelectItemAt(indexPath: IndexPath) {
    let events = wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: indexPath.section)
    let event = events[indexPath.row]
    wrappedModel.didSelectSession(event)
  }

  func previewViewControllerForItemAt(indexPath: IndexPath) -> UIViewController? {
    let events = wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: indexPath.section)
    let event = events[indexPath.row]
    return wrappedModel.detailsViewController(for: event)
  }

  func isEmpty() -> Bool {
    for i in 0 ..< numberOfSections() {
      if numberOfItemsIn(section: i) > 0 {
        return false
      }
    }
    return true
  }

  func isEmpty(forDayWithIndex index: Int) -> Bool {
    return wrappedModel.slots(forDayWithIndex: index).count == 0
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

}
