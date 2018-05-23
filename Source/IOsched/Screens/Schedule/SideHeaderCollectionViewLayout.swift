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

class SideHeaderCollectionViewLayout: MDCCollectionViewFlowLayout {

  public let dateWidth: CGFloat = 60

  public var shouldShowSideHeaderViews = true

  required init(coder: NSCoder) {
    fatalError("init(coder:) is not supported")
  }

  public override init() {
    super.init()
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let originalAttributes = super.layoutAttributesForElements(in: rect) else { return nil }
    guard shouldShowSideHeaderViews else {
      return originalAttributes
    }
    for attributes in originalAttributes {
      let elementKind = attributes.representedElementKind
      if elementKind == UICollectionView.elementKindSectionHeader {
        var frame = attributes.frame
        frame.size.height = 100
        frame.size.width = dateWidth
        attributes.frame = frame
      } else if elementKind == nil {
        var frame = attributes.frame
        frame.size.width -= dateWidth
        frame.origin.x += dateWidth
        attributes.frame = frame
      }
    }
    return originalAttributes
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard let attributes = super.layoutAttributesForItem(at: indexPath) else { return nil }
    guard shouldShowSideHeaderViews else {
      return attributes
    }
    var frame = attributes.frame
    frame.size.width -= dateWidth
    frame.origin.x += dateWidth
    attributes.frame = frame
    return attributes
  }

  override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    guard let attributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind,
                                                                      at: indexPath) else {
      return nil
    }
    guard shouldShowSideHeaderViews else {
      return attributes
    }
    var frame = attributes.frame
    frame.size.height = 100
    frame.size.width = dateWidth
    attributes.frame = frame
    return attributes
  }

}
