//
//  Copyright (c) 2019 Google Inc.
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

public class UpcomingItemsCollectionViewCell: UICollectionViewCell {

  static var cellHeight: CGFloat {
    return UpcomingItemCollectionViewCell.cellSize.height + 16
  }

  public lazy private(set) var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.itemSize = UpcomingItemCollectionViewCell.cellSize
    layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    let collectionView = UICollectionView(frame: contentView.frame, collectionViewLayout: layout)
    collectionView.contentInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    collectionView.backgroundColor = .clear
    collectionView.register(
      UpcomingItemCollectionViewCell.self,
      forCellWithReuseIdentifier: UpcomingItemCollectionViewCell.reuseIdentifier()
    )
    return collectionView
  }()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.addSubview(collectionView)
    setupConstraints()
  }

  private var upcomingItemsDataSource: UpcomingItemsDataSource?
  private lazy var emptyItemsView = EmptyItemsBackgroundView(frame: contentView.bounds)

  public func populate(upcomingItems: UpcomingItemsDataSource) {
    upcomingItems.reloadData()
    upcomingItemsDataSource = upcomingItems
    collectionView.dataSource = upcomingItems
    collectionView.delegate = upcomingItems
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.reloadData()

    upcomingItems.updateHandler = { dataSource in
      if dataSource.isEmpty {
        self.showEmptyItemsView(dataSource: dataSource)
      } else {
        self.hideEmptyItemsView()
      }
      self.collectionView.reloadData()
    }
  }

  func showEmptyItemsView(dataSource: UpcomingItemsDataSource) {
    emptyItemsView.navigator = dataSource.rootNavigator
    collectionView.backgroundView = emptyItemsView
  }

  func hideEmptyItemsView() {
    collectionView.backgroundView = nil
    emptyItemsView.removeFromSuperview()
  }

  public override func prepareForReuse() {
    collectionView.dataSource = nil
    upcomingItemsDataSource?.updateHandler = nil
    upcomingItemsDataSource = nil
  }

  private func setupConstraints() {
    let constraints: [NSLayoutConstraint] = [
      NSLayoutConstraint(item: collectionView,
                         attribute: .top,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .top,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: collectionView,
                         attribute: .left,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .left,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: collectionView,
                         attribute: .right,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .right,
                         multiplier: 1,
                         constant: 0),
      NSLayoutConstraint(item: collectionView,
                         attribute: .bottom,
                         relatedBy: .equal,
                         toItem: contentView,
                         attribute: .bottom,
                         multiplier: 1,
                         constant: 0)
    ]

    contentView.addConstraints(constraints)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
