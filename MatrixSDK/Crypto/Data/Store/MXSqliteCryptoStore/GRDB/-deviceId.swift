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

public struct OlmAccountNotFound: Error {
  public let userId: String
}

extension GRDBCoordinator {
  
  public func retrieveDeviceId(for userId: String) throws -> String {
    try self.pool.read({ db in
      guard let account = try OlmAccount_DeviceId
              .filter(OlmAccount_DeviceId.CodingKeys.userId == userId)
              .fetchOne(db) else {
                throw OlmAccountNotFound(userId: userId)
              }
      
      return account.deviceId
    })
  }
  
  public func storeDeviceId(_ deviceId: String, for userId: String) throws {
    
    try self.pool.write { db in
      
      guard var account = try OlmAccount_DeviceId
              .filter(OlmAccount_DeviceId.CodingKeys.userId == userId)
              .fetchOne(db) else {
                throw OlmAccountNotFound(userId: userId)
              }
      
      account.deviceId = deviceId
      try account.update(db)
    }
  }
}

private struct OlmAccount_DeviceId: Codable, PersistableRecord, FetchableRecord {
  static let databaseTableName: String = MXGrdbOlmAccount.databaseTableName
  
  let userId: String
  var deviceId: String
  
  enum CodingKeys: String, CodingKey, ColumnExpression {
    case deviceId, userId
  }
}
