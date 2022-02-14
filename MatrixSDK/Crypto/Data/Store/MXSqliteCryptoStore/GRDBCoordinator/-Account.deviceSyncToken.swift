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

extension GRDBCoordinator {
  
  public func retrieveDeviceSyncTokenObjc(for userId: String) -> String? {
    do {
      return try self.retrieveDeviceSyncToken(for: userId)
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving device sync token for user ID \(userId): \(error)")
      return nil
    }
  }

  public func storeDeviceSyncTokenObjc(_ deviceSyncToken: String, for userId: String) {
    do {
      try self.storeDeviceSyncToken(deviceSyncToken, for: userId)
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing device sync token for user ID \(userId): \(error)")
    }
  }
  
  func retrieveDeviceSyncToken(for userId: String) throws -> String? {
    try self.pool.read { db in
      try MXGrdbOlmAccount
        .select(MXGrdbOlmAccount.CodingKeys.deviceSyncToken)
        .filter(MXGrdbOlmAccount.CodingKeys.userId == userId)
        .fetchOne(db)
    }
  }
  
  func storeDeviceSyncToken(_ deviceSyncToken: String, for userId: String) throws {
    return try self.pool.write { db in
      try MXGrdbOlmAccount
        .filter(MXGrdbOlmAccount.CodingKeys.userId == userId)
        .updateAll(db, MXGrdbOlmAccount.CodingKeys.deviceSyncToken.set(to: deviceSyncToken))
    }
  }
}