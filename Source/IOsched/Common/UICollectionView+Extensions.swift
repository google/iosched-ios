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

extension UICollectionView {

  func register(_ cellClass: Swift.AnyClass) {
    register(cellClass, forCellWithReuseIdentifier: String(describing: cellClass))
  }

  func dequeueReusableCell<Cell: UICollectionViewCell>(for indexPath: IndexPath) -> Cell {
    if let cell = dequeueReusableCell(withReuseIdentifier: String(describing: Cell.self), for: indexPath) as? Cell {
      return cell
    }
    else {
      fatalError("Inconsistent cell registration")
    }
  }

  func register(_ viewClass: Swift.AnyClass, forSupplementaryViewOfKind elementKind: String) {
    register(viewClass, forSupplementaryViewOfKind: elementKind, withReuseIdentifier: String(describing: viewClass))
  }

  func dequeueReusableSupplementaryView<View: UICollectionReusableView>(ofKind elementKind: String, for indexPath: IndexPath) -> View {
    if let view = dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: String(describing: View.self), for: indexPath) as? View {
      return view
    }
    else {
      fatalError("Inconsistent view registration")
    }
  }

}
