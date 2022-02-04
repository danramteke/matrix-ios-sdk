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

import Foundation
@testable import MatrixSDK

class GRDBCoordinatorTests: XCTestCase {
  
  let dbUrl: URL = FileManager.default.temporaryDirectory.appendingPathComponent("test.sqlite")
  
  var grdb: GRDBCoordinator!
  
  override func setUpWithError() throws {
    self.grdb = try GRDBCoordinator(url: FileManager.default.temporaryDirectory.appendingPathComponent("test.sqlite"))
  }
  
  override func tearDownWithError() throws {
    try FileManager.default.removeItem(at: dbUrl)
  }
  
  func testEmptyDatabaseOnCreate() {
    XCTAssertNil(try grdb.retrieveDeviceSyncToken(for: "empty"))
    XCTAssertNil(try grdb.retrieveDeviceId(for: "empty"))
    XCTAssertNil(grdb.accountIfExists(userId: "empty"))
  }
  
  func testAccountFieldsAreEmptyOnAccountCreate() throws {
    try grdb.createAccount(userId: "abc", deviceId: "123")
    guard let account = grdb.accountIfExists(userId: "abc") else {
      XCTFail("expected account to exist")
      return
    }
  
    XCTAssertNil(account.deviceSyncToken)
    XCTAssertNil(try grdb.retrieveDeviceSyncToken(for: "abc"))
    
    XCTAssertNil(account.olmAccountData)
    
    XCTAssertEqual(account.deviceId, "123")
    XCTAssertEqual(try grdb.retrieveDeviceId(for: "abc"), "123")
  }
}
