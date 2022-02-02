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

@objcMembers public class GRDBCoordinator: NSObject {
  
  private let pool: DatabasePool
  
  public init(url: URL) throws {
    
    let pool = try DatabasePool(path: url.absoluteString)
    
    var migrator = DatabaseMigrator()
    migrator.registerMigration("createOlmAccount") { db in
      try db.create(table: "OlmAccount") { t in
        t.column("userId", .text).notNull()
        t.column("deviceId", .text).notNull()
        t.primaryKey(["userId"], onConflict: .rollback)
      }
    }
    
    try migrator.migrate(pool)
    self.pool = pool
  }
  
  public func accountIfExists(userId: String) -> MXGrdbOlmAccount? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOlmAccount.filter(MXGrdbOlmAccount.CodingKeys.userId == userId).fetchOne(db)
      }
    } catch {
      return nil
    }
  }
  
  public func createAccount(userId: String, deviceId: String) throws {
    let account = MXGrdbOlmAccount(deviceId: deviceId, userId: userId)
    try self.pool.write { db in
      try account.save(db)
    }
  }
  
  public func storeDeviceId(_ deviceId: String, for userId: String) throws {
    
    struct OlmAccountUserIdDeviceId: Codable, PersistableRecord, FetchableRecord {
      static let databaseTableName: String = MXGrdbOlmAccount.databaseTableName
      var deviceId: String
      var userId: String
      enum CodingKeys: String, CodingKey, ColumnExpression {
        case deviceId, userId
      }
    }
    
    try self.pool.write { db in
      
      guard var account = try? OlmAccountUserIdDeviceId.filter(OlmAccountUserIdDeviceId.CodingKeys.userId == userId).fetchOne(db) else {
        return
      }
      
      account.deviceId = deviceId
      try account.update(db)
    }
  }
}
