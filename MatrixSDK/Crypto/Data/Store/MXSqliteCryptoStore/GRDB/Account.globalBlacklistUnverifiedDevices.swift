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

import GRDB

extension GRDBCoordinator {
  
  public func retrieveGlobalBlacklistUnverifiedDevices(for userId: String) -> Bool {
    do {
      return try self.pool.read { db in
        try MXGrdbOlmAccount
          .select(MXGrdbOlmAccount.CodingKeys.globalBlacklistUnverifiedDevices)
          .filter(MXGrdbOlmAccount.CodingKeys.userId == userId)
          .fetchOne(db) ?? false
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving GlobalBlacklistUnverifiedDevices for user ID \(userId). Defaulting to false. \(error)")
      return false
    }
  }
  
  public func storeGlobalBlacklistUnverifiedDevices(_ globalBlacklistUnverifiedDevices: Bool, for userId: String) {
    do {
      return try self.pool.write { db in
        try MXGrdbOlmAccount
          .filter(MXGrdbOlmAccount.CodingKeys.userId == userId)
          .updateAll(db, MXGrdbOlmAccount.CodingKeys.globalBlacklistUnverifiedDevices.set(to: globalBlacklistUnverifiedDevices))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing GlobalBlacklistUnverifiedDevices for user ID \(userId): \(error)")
    }
  }
}
