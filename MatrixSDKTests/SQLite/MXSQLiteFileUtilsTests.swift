// 
// Copyright 2021 The Matrix.org Foundation C.I.C
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest
@testable import MatrixSDK

class MXSQLiteFileUtilsTests: XCTestCase {

    func test_defaultStoreFolder_usesBundleIdFromBundle() {
      let url = MXSQLiteFileUtils.defaultStoreFolder(for: nil)
      XCTAssertEqual(url.lastPathComponent, "com.apple.dt.xctest.tool")
    }

  func test_defaultStoreFolder_usesBundleIdFromParamWhenPresent() {
    let url = MXSQLiteFileUtils.defaultStoreFolder(for: "com.example.app")
    XCTAssertEqual(url.lastPathComponent, "com.example.app")
  }
  
  func test_mxStoreFolder_appendsFolderNameInAllCases() {
    XCTAssertEqual(MXSQLiteFileUtils.mxStoreFolder(for: nil).lastPathComponent, "MXSQLiteCryptoStore")
    XCTAssertEqual(MXSQLiteFileUtils.mxStoreFolder(for: "com.example.app").lastPathComponent, "MXSQLiteCryptoStore")
  }
}
