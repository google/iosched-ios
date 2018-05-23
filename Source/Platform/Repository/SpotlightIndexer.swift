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
import CoreSpotlight
import MobileCoreServices
import Domain
import AlamofireImage

public enum IndexConstants: String {
  case sessionDomainIdentifier = "com.google.iosched.session"
  case speakerDomainIdentifier = "com.google.iosched.speaker"
}

class SpotlightIndexer {
  private let sessionsRepository: SessionsRepository
  private let speakersRepository: SpeakersRepository

  init(sessionsRepository: SessionsRepository, speakersRepository: SpeakersRepository) {
    self.sessionsRepository = sessionsRepository
    self.speakersRepository = speakersRepository
  }

  func updateIndex() {
    indexSpeakers()
    indexSessions()
  }

  func indexSessions() {
    DispatchQueue.global().async {
      let indexItems = self.sessionsRepository.sessions.map { session -> CSSearchableItem in
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributeSet.title = session.title
        attributeSet.contentDescription = session.detail
        return CSSearchableItem(uniqueIdentifier: "\(IndexConstants.sessionDomainIdentifier.rawValue)/\(session.id)",
                                domainIdentifier: IndexConstants.sessionDomainIdentifier.rawValue,
                                attributeSet: attributeSet)
      }
      self.rebuildIndex(for: IndexConstants.sessionDomainIdentifier.rawValue, with: indexItems)
    }
  }

  private enum LayoutConstants {
    static let thumbnailWidth: CGFloat = 120
    static let profileImageWidth: CGFloat = LayoutConstants.thumbnailWidth
    static let profileImageHeight: CGFloat = LayoutConstants.thumbnailWidth
    static let profileImageRadius = profileImageHeight / 2.0
  }

  lazy var imageFilter: ImageFilter = {
    return AspectScaledToFillSizeWithRoundedCornersFilter(
      size: CGSize(width: LayoutConstants.profileImageWidth,
                   height: LayoutConstants.profileImageHeight),
      radius: LayoutConstants.profileImageRadius
    )
  }()

  func indexSpeakers() {
    DispatchQueue.global().async {
      let indexItems = self.speakersRepository.speakers.map { speaker -> CSSearchableItem in
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
        attributeSet.title = speaker.name
        attributeSet.contentDescription = speaker.bio

        if let url = speaker.thumbnailUrl {
          if let data = try? Data(contentsOf: url) {
            let image = UIImage(data: data, scale: UIScreen.main.scale)!

            let filteredImage = self.imageFilter.filter(image)
            let dataFiltered = UIImagePNGRepresentation(filteredImage)

            attributeSet.thumbnailData = dataFiltered
          }

        }

        return CSSearchableItem(uniqueIdentifier: "\(IndexConstants.speakerDomainIdentifier.rawValue)/\(speaker.id)",
                                domainIdentifier: IndexConstants.speakerDomainIdentifier.rawValue,
                                attributeSet: attributeSet)
      }
      self.rebuildIndex(for: IndexConstants.speakerDomainIdentifier.rawValue, with: indexItems)
    }
  }

  func rebuildIndex(for domainIdentifier: String, with indexItems: [CSSearchableItem]) {
    // let's delete all session index items first, as we don't know if the dataset contains any deletions
    CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domainIdentifier]) { error in
      if let error = error {
        print("While trying to delete index items from the index, the following error ocurred: \(error.localizedDescription)")
      } else {
        print("Successfully deleted index items.")

        CSSearchableIndex.default().indexSearchableItems(indexItems) { error in
          if let error = error {
            print("While trying to index items, the following error ocurred: \(error.localizedDescription)")
          } else {
            print("Successfully indexed \(indexItems.count) items.")
          }
        }
      }
    }
  }
}
