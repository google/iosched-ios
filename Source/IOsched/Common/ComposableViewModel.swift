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

@objc protocol ComposableViewModelLayout {
  func sizeForHeader(inSection section: Int, inFrame frame: CGRect) -> CGSize
  func heightForCell(at indexPath: IndexPath, inFrame frame: CGRect) -> CGFloat
  @objc optional func backgroundColor(at indexPath: IndexPath) -> UIColor?
}

@objc protocol ComposableViewModelDataSource: class {
  func numberOfSections() -> Int
  func numberOfItemsIn(section: Int) -> Int
  @objc optional func cellClassForItemAt(indexPath: IndexPath) -> UICollectionViewCell.Type?
  @objc optional func populateCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
  @objc optional func supplementaryViewClass(ofKind kind: String, forItemAt indexPath: IndexPath) -> UICollectionReusableView.Type?
  @objc optional func populateSupplementaryView(_ view: UICollectionReusableView, forItemAt indexPath: IndexPath)
  @objc optional func didSelectItemAt(indexPath: IndexPath)
  @objc optional func previewViewControllerForItemAt(indexPath: IndexPath) -> UIViewController?
  @objc optional func isEmpty() -> Bool
}

protocol ComposableViewModel: ComposableViewModelLayout, ComposableViewModelDataSource {}

class ComposedViewModel: ComposableViewModel {

  lazy var viewModels: [ComposableViewModel] = self.initializeViewModels()

  func initializeViewModels() -> [ComposableViewModel] {
    fatalError("Subclasses must implement")
  }

  fileprivate func viewModelFor(section: Int) -> ComposableViewModel? {
    var section = section
    for viewModel in viewModels {
      if section <= viewModel.numberOfSections() - 1 {
        return viewModel
      }
      else {
        section -= viewModel.numberOfSections()
      }
    }
    return nil
  }

  fileprivate func adjustedSection(section: Int) -> Int {
    var section = section
    for viewModel in viewModels {
      if section <= viewModel.numberOfSections() - 1 {
        return section
      }
      else {
        section -= viewModel.numberOfSections()
      }
    }
    return section
  }

  fileprivate func adjustedIndexPath(indexPath: IndexPath) -> IndexPath {
    var section = indexPath.section
    for viewModel in viewModels {
      if section <= viewModel.numberOfSections() - 1 {
        return IndexPath(item: indexPath.item, section: section)
      }
      else {
        section -= viewModel.numberOfSections()
      }
    }
    return indexPath
  }

}

// MARK: - ComposableViewModelLayout

extension ComposedViewModel: ComposableViewModelLayout {

  func sizeForHeader(inSection section: Int, inFrame frame: CGRect) -> CGSize {
    guard let viewModel = viewModelFor(section: section) else { return CGSize.zero }
    let section = adjustedSection(section: section)
    return viewModel.sizeForHeader(inSection: section, inFrame: frame)
  }

  func heightForCell(at indexPath: IndexPath, inFrame frame: CGRect) -> CGFloat {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return 0 }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    return viewModel.heightForCell(at: indexPath, inFrame: frame)
  }

  func backgroundColor(at indexPath: IndexPath) -> UIColor? {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return nil }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    return viewModel.backgroundColor?(at: indexPath)
  }

}

// MARK: - ComposableViewModelDataSource

extension ComposedViewModel: ComposableViewModelDataSource {

  func numberOfSections() -> Int {
    return viewModels.map { $0.numberOfSections() }.reduce(0, +)
  }

  func numberOfItemsIn(section: Int) -> Int {
    guard let viewModel = viewModelFor(section: section) else { return 0 }
    let section = adjustedSection(section: section)
    return viewModel.numberOfItemsIn(section: section)
  }

  func isEmpty() -> Bool {
    for i in 0..<numberOfSections() {
      if numberOfItemsIn(section: i) > 0 {
        return false
      }
    }
    return true
  }

  func cellClassForItemAt(indexPath: IndexPath) -> UICollectionViewCell.Type? {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return nil }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    return viewModel.cellClassForItemAt?(indexPath: indexPath)
  }

  func supplementaryViewClass(ofKind kind: String, forItemAt indexPath: IndexPath) -> UICollectionReusableView.Type? {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return nil }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    let type = viewModel.supplementaryViewClass?(ofKind: kind, forItemAt: indexPath) ?? IOSchedCollectionViewHeaderCell.self
    return type
  }

  func populateCell(_ cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    viewModel.populateCell?(cell, forItemAt: indexPath)
  }

  func populateSupplementaryView(_ view: UICollectionReusableView, forItemAt indexPath: IndexPath) {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    viewModel.populateSupplementaryView?(view, forItemAt: indexPath)
  }

  func didSelectItemAt(indexPath: IndexPath) {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    viewModel.didSelectItemAt?(indexPath: indexPath)
  }

  func previewViewControllerForItemAt(indexPath: IndexPath) -> UIViewController? {
    guard let viewModel = viewModelFor(section: indexPath.section) else { return nil }
    let indexPath = adjustedIndexPath(indexPath: indexPath)
    return viewModel.previewViewControllerForItemAt?(indexPath: indexPath)
  }

}
