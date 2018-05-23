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

import XCTest

@testable import IOsched

class InfoDetailSearchProviderTest: XCTestCase {

  var searchResultProvider: InfoDetailSearchProvider!

  override func setUp() {
    searchResultProvider = InfoDetailSearchProvider()
  }

  override func tearDown() {
  }

  func testItPassesInfoDetailObjectsViaUserInfo() {
    let results = searchResultProvider.matches(query: "Shoreline")
    for result in results {
      let infoDetail = result.wrappedItem as? InfoDetail
      XCTAssertNotNil(infoDetail)
    }
  }

}
