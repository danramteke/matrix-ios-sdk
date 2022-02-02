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
  
  public func retrieveDeviceSyncTokenObjc(for userId: String) -> String? {
    do {
      return try self.retrieveDeviceSyncToken(for: userId)
    } catch {
      MXLog.debug("[\(String(describing: Self.self))] error retrieving device sync token for user ID \(userId): \(error)")
      return nil
    }
  }

  public func storeDeviceSyncTokenObjc(_ deviceSyncToken: String, for userId: String) {
    do {
      try self.storeDeviceSyncToken(deviceSyncToken, for: userId)
    } catch {
      MXLog.debug("[\(String(describing: Self.self))] error storing device sync token for user ID \(userId): \(error)")
    }
  }
  
  func retrieveDeviceSyncToken(for userId: String) throws -> String? {
    try self.pool.read({ db in
      guard let account = try OlmAccount_DeviceSyncToken
              .filter(OlmAccount_DeviceSyncToken.CodingKeys.userId == userId)
              .fetchOne(db) else {
                return nil
              }
      
      return account.deviceSyncToken
    })
  }
  
  func storeDeviceSyncToken(_ deviceSyncToken: String, for userId: String) throws {
    try self.pool.write { db in
      guard var account = try OlmAccount_DeviceSyncToken
              .filter(OlmAccount_DeviceSyncToken.CodingKeys.userId == userId)
              .fetchOne(db) else {
                return
              }
      
      account.deviceSyncToken = deviceSyncToken
      try account.update(db)
    }
  }
}

private struct OlmAccount_DeviceSyncToken: Codable, PersistableRecord, FetchableRecord {
  static let databaseTableName: String = MXGrdbOlmAccount.databaseTableName
  
  let userId: String
  var deviceSyncToken: String?
  
  enum CodingKeys: String, CodingKey, ColumnExpression {
    case deviceSyncToken, userId
  }
}
