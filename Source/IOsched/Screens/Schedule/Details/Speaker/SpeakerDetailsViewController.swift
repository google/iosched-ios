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
import MaterialComponents

class SpeakerDetailsViewController: BaseCollectionViewController {

  var viewModel: SpeakerDetailsViewModel

  lazy var measureSpeakerCell: SpeakerDetailsCollectionViewSpeakerCell = self.setupMeasureSpeakerCell()
  lazy var measureMainInfoCell: SpeakerDetailsCollectionViewMainInfoCell = self.setupMeasureMainInfoCell()
  lazy var measureEventInfoCell: ScheduleViewCollectionViewCell = self.setupMeasureEventInfoCell()

  required init(viewModel: SpeakerDetailsViewModel) {
    self.viewModel = viewModel
    let layout = MDCCollectionViewFlowLayout()
    super.init(collectionViewLayout: layout)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    registerForViewUpdates()
  }

// MARK: - View setup

  private struct LayoutConstants {
    static let fabOffset: CGFloat = 15
  }

  @objc override func setupViews() {
    super.setupViews()

    setupCollectionView()

    appBar.navigationBar.tintColor = MDCPalette.grey.tint800

    setup3DTouch()
  }

  func registerForViewUpdates() {
    viewModel.onUpdate { indexPath in
      self.performViewUpdate(indexPath: indexPath)
    }
  }

  func performViewUpdate(indexPath: IndexPath?) {
    if let indexPath = indexPath {
      self.collectionView?.reloadItems(at: [indexPath])
    }
    else {
      self.collectionView?.reloadData()
    }
  }

  func setupCollectionView() {
    collectionView?.register(MDCCollectionViewTextCell.self)
    collectionView?.register(ScheduleViewCollectionViewCell.self)
    collectionView?.register(SpeakerDetailsCollectionViewSpeakerCell.self)
    collectionView?.register(SpeakerDetailsCollectionViewMainInfoCell.self)
    collectionView?.register(MDCCollectionViewTextCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader)

    styler.cellStyle = .default
    styler.shouldAnimateCellsOnAppearance = false
  }

  @objc override func setupAppBar() -> MDCAppBar {
    let appBar = super.setupAppBar()
    return appBar
  }

  func setupMeasureSpeakerCell() -> SpeakerDetailsCollectionViewSpeakerCell {
    return SpeakerDetailsCollectionViewSpeakerCell(frame: CGRect(x: 0,
                                                                 y: 0,
                                                                 width: self.view.frame.width,
                                                                 height: self.view.frame.height))
  }

  func setupMeasureMainInfoCell() -> SpeakerDetailsCollectionViewMainInfoCell {
    return SpeakerDetailsCollectionViewMainInfoCell(frame: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: self.view.frame.width,
                                                                  height: self.view.frame.height))
  }

  func setupMeasureEventInfoCell() -> ScheduleViewCollectionViewCell {
    return ScheduleViewCollectionViewCell(frame: CGRect(x: 0,
                                                                  y: 0,
                                                                  width: self.view.frame.width,
                                                                  height: self.view.frame.height))
  }

// MARK: - ViewControllerStylable

  private enum StylingConstants {
    static let maxHeaderHeight: CGFloat = 80
    static let minHeaderHeight: CGFloat = 80
  }

  @objc override var minHeaderHeight: CGFloat {
    return StylingConstants.minHeaderHeight
  }

  @objc override var maxHeaderHeight: CGFloat {
    return StylingConstants.maxHeaderHeight
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .default
  }

// MARK: - Analytics

  @objc override var screenName: String? {
    guard let name = viewModel.speakerDetailsViewModel?.name else { return nil }
    return AnalyticsParameters.itemID(forSpeakerName: name)
  }

}


// MARK: - UICollectionView Layout

extension SpeakerDetailsViewController {

  override func collectionView(_ collectionView: UICollectionView, cellHeightAt indexPath: IndexPath) -> CGFloat {
    let measureCell: MDCCollectionViewCell = {
      if indexPath.section == 0 {
        if indexPath.row == 0 {
          return measureSpeakerCell
        }
        else {
          return measureMainInfoCell
        }
      }
      else {
        return measureEventInfoCell
      }
  }()

    populateCell(cell: measureCell, forItemAt: indexPath)
    return measureCell.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
  }
}

// MARK: - UICollectionView DataSource

extension SpeakerDetailsViewController {

  override func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               referenceSizeForHeaderInSection section: Int) -> CGSize {
    return viewModel.sizeForHeader(inSection: section, inFrame: collectionView.bounds)
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return viewModel.numberOfItemsInSection(section)
  }

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    let numberOfSections = viewModel.numberOfSections()
    return numberOfSections
  }

  func populateCell(cell: MDCCollectionViewCell, forItemAt indexPath: IndexPath) {
    if let cell = cell as? SpeakerDetailsCollectionViewMainInfoCell {
      cell.viewModel = viewModel.speakerDetailsMainInfoViewModel
    }

    if let cell = cell as? SpeakerDetailsCollectionViewSpeakerCell {
      cell.viewModel = viewModel.speakerDetailsViewModel
    }

    if let cell = cell as? ScheduleViewCollectionViewCell {
      cell.viewModel  = viewModel.relatedSessionAtIndex(indexPath.row)
      cell.onBookmarkTapped { sessionId in
        self.viewModel.toggleBookmark(sessionId: sessionId)
      }
    }
  }

  override func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                               withReuseIdentifier: MDCCollectionViewTextCell.self.reuseIdentifier(),
                                                               for: indexPath)
    viewModel.populateSupplementaryView(view, forItemAt: indexPath)
    return view
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
      viewModel.didSelectItemAt(indexPath: indexPath)
  }

  override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
    return (((collectionView.cellForItem(at: indexPath) as? ScheduleViewCollectionViewCell) != nil))
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.section == 0 {
      if indexPath.row == 0 {
        let cell: SpeakerDetailsCollectionViewSpeakerCell = collectionView.dequeueReusableCell(for: indexPath)
        populateCell(cell: cell, forItemAt: indexPath)
        return cell
      }
      else if indexPath.row >= 1 {
        let cell: SpeakerDetailsCollectionViewMainInfoCell = collectionView.dequeueReusableCell(for: indexPath)
        populateCell(cell: cell, forItemAt: indexPath)
        return cell
      }
    }
    else if indexPath.section == 1 {
      let cell: ScheduleViewCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
      populateCell(cell: cell, forItemAt: indexPath)
      return cell
    }

    let cell: MDCCollectionViewTextCell = collectionView.dequeueReusableCell(for: indexPath)
    cell.textLabel?.text = "Not implemented"
    return cell
  }
}

extension SpeakerDetailsViewController: UIViewControllerPreviewingDelegate {

  func setup3DTouch() {
    if let collectionView = collectionView {
      registerForPreviewing(with: self, sourceView: collectionView)
    }
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing,
                         viewControllerForLocation location: CGPoint) -> UIViewController? {
    if let indexPath = collectionView?.indexPathForItem(at: location), let cellAttributes = collectionView?.layoutAttributesForItem(at: indexPath) {
      // This will show the cell clearly and blur the rest of the screen for our peek.
      previewingContext.sourceRect = cellAttributes.frame

      return viewModel.detailsViewController(for: indexPath)
    }
    return nil
  }

  func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
    self.navigationController?.pushViewController(viewControllerToCommit, animated: true)
  }
}
