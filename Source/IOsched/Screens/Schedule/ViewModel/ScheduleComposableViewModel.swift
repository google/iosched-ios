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

class ScheduleComposableViewModel: ComposableViewModel, DaySelectable {

  let wrappedModel: ScheduleViewModel
  var selectedDay = 0
  fileprivate var cachedHeights: [ConferenceEventViewModel: CGFloat] = [:]

  lazy var measureCell: ScheduleViewCollectionViewCell = self.setupMeasureCell()

  private func setupMeasureCell() -> ScheduleViewCollectionViewCell {
    return ScheduleViewCollectionViewCell(frame: CGRect())
  }

  init(wrappedModel: ScheduleViewModel) {
    self.wrappedModel = wrappedModel
  }

}

// MARK: - ComposableViewModelLayout

extension ScheduleComposableViewModel: ComposableViewModelLayout {

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

}

// MARK: - ComposableViewModelDataSource

extension ScheduleComposableViewModel: ComposableViewModelDataSource {

  func numberOfSections() -> Int {
    return wrappedModel.slots(forDayWithIndex: selectedDay)?.count ?? 0
  }

  func numberOfItemsIn(section: Int) -> Int {
    return wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: section)?.count ?? 0
  }

  func cellClassForItemAt(indexPath: IndexPath) -> UICollectionViewCell.Type? {
    return ScheduleViewCollectionViewCell.self
  }

  func session(forIndexPath indexPath: IndexPath) -> ConferenceEventViewModel? {
    let events = wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: indexPath.section)
    return events?[indexPath.row]
  }

  func populateCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard let cell = cell as? ScheduleViewCollectionViewCell else { return }
    if let session = session(forIndexPath: indexPath) {
      cell.viewModel = session
      cell.isUserInteractionEnabled = session.isNavigatable
      cell.onBookmarkTapped { sessionId in
        self.wrappedModel.toggleBookmark(sessionId: sessionId)
      }
    }
  }

  func supplementaryViewClass(ofKind kind: String, forItemAt indexPath: IndexPath) -> UICollectionReusableView.Type? {
    return IOSchedCollectionViewHeaderCell.self
  }

  func populateSupplementaryView(_ view: UICollectionReusableView, forItemAt indexPath: IndexPath) {
    if let sectionHeader = view as? IOSchedCollectionViewHeaderCell {
      let slot = wrappedModel.slots(forDayWithIndex: selectedDay)?[indexPath.section]
      sectionHeader.date = slot?.time
    }
  }

  func didSelectItemAt(indexPath: IndexPath) {
    let events = wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: indexPath.section)
    if let event = events?[indexPath.row] {
      wrappedModel.didSelectSession(event)
    }
  }

  func previewViewControllerForItemAt(indexPath: IndexPath) -> UIViewController? {
    let events = wrappedModel.events(forDayWithIndex: selectedDay, andSlotIndex: indexPath.section)
    if let event = events?[indexPath.row], event.isNavigatable == true {
      return wrappedModel.detailsViewController(for: event)
    }
    return nil
  }

}
