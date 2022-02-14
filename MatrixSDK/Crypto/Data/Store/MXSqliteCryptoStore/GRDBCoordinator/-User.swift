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
  
  public func retrieveCrossSigningKeysDataFor(userId: String) -> Data? {
    do {
      return try self.pool.read() { db in
        try MXGrdbUser
          .select(MXGrdbUser.CodingKeys.crossSigningKeysData)
          .filter(MXGrdbUser.CodingKeys.id == userId)
          .asRequest(of: Data?.self)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Cross Signing Keys Data for user ID \(userId): \(error)")
      return nil
    }
  }
  
  public func retrieveAllCrossSigningKeysData() -> [Data] {
    do {
      return try self.pool.read() { db in
        return try MXGrdbUser
          .select(MXGrdbUser.CodingKeys.crossSigningKeysData)
          .asRequest(of: Data?.self)
          .fetchAll(db)
          .compactMap({ $0 })
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving all Cross Signing Keys Data: \(error)")
      return []
    }
  }
  
  public func storeCrossSigningKeys(data: Data, for userId: String) {
    do {
      return try self.pool.write { db in
        let _ = try MXGrdbUser.findOrCreate(id: userId, db: db)
        
        try MXGrdbUser
          .filter(MXGrdbUser.CodingKeys.id == userId)
          .updateAll(db, MXGrdbUser.CodingKeys.crossSigningKeysData.set(to: data))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing Cross Signing Keys Data for user ID \(userId): \(error)")
    }
  }
}
