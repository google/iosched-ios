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

class AgendaCollectionViewHeaderCell: IOSchedCollectionViewHeaderCell {

  private static let dayNameFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "E"
    return formatter
  }()

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "d"
    return formatter
  }()

  private static let accessibilityFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMMd"
    return formatter
  }()

  override var date: Date? {
    didSet {
      guard let date = date else { return }
      let dayName = AgendaCollectionViewHeaderCell.dayNameFormatter.string(from: date)
      let day = AgendaCollectionViewHeaderCell.dateFormatter.string(from: date)

      timeLabel.text = day
      ampmLabel.text = dayName
    }
  }

  override var timeLabelConstraints: [NSLayoutConstraint] {
    return [
      NSLayoutConstraint(item: timeLabel, attribute: .left,
                         relatedBy: .equal,
                         toItem: self, attribute: .left,
                         multiplier: 1, constant: 4),
      NSLayoutConstraint(item: timeLabel, attribute: .right,
                         relatedBy: .equal,
                         toItem: self, attribute: .right,
                         multiplier: 1, constant: 0),
      NSLayoutConstraint(item: timeLabel, attribute: .top,
                         relatedBy: .equal,
                         toItem: self, attribute: .top,
                         multiplier: 1, constant: 46),
    ]
  }

  // MARK: - UIAccessibility

  override var accessibilityLabel: String? {
    get {
      guard let date = date else { return nil }
      return AgendaCollectionViewHeaderCell.accessibilityFormatter.string(from: date)
    } set {}
  }

}
