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

class AgendaDataSource: NSObject, UICollectionViewDataSource {

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return AgendaItem.allAgendaItems.count
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    return AgendaItem.allAgendaItems[section].count
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let reuseID = AgendaCollectionViewCell.reuseIdentifier()
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseID,
                                                  for: indexPath) as! AgendaCollectionViewCell
    let agendaItem = AgendaItem.allAgendaItems[indexPath.section][indexPath.item]
    cell.populate(with: agendaItem)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {
    let reuseID = AgendaCollectionViewHeaderCell.reuseIdentifier()
    let view =
        collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                        withReuseIdentifier: reuseID,
                                                        for: indexPath)
            as! AgendaCollectionViewHeaderCell
    view.date = AgendaItem.allAgendaItems[indexPath.section][0].startDate
    view.isHidden = false
    return view
  }

}
