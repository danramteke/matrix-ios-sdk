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
import GRDB

extension GRDBCoordinator {
  
  public func retrieveOlmAccountDataObjc(for userId: String) -> Data? {
    do {
      return try self.retrieveOlmAccountData(for: userId)
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving OLM Account data for user ID \(userId): \(error)")
      return nil
    }
  }
  
  func retrieveOlmAccountData(for userId: String) throws -> Data? {
    try self.pool.read() { db in
      try Data.fetchOne(db, MXGrdbOlmAccount
                          .select(MXGrdbOlmAccount.CodingKeys.olmAccountData)
                          .filter(MXGrdbOlmAccount.CodingKeys.userId == userId))
    }
  }
  
  public func storeOlmAccountDataObjc(_ data: Data, for userId: String) {
    do {
      try self.storeOlmAccountData(data, for: userId)
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing OLM Account data for user ID \(userId): \(error)")
    }
  }
  
  func storeOlmAccountData(_ data: Data, for userId: String) throws {
    return try self.pool.write { db in
      try MXGrdbOlmAccount
        .filter(MXGrdbOlmAccount.CodingKeys.userId == userId)
        .updateAll(db, MXGrdbOlmAccount.CodingKeys.olmAccountData.set(to: data))
    }
  }
}
