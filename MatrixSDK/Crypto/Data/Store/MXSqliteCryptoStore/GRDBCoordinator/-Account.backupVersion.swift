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
  
  public func retrieveBackupVersion(for userId: String) -> String? {
    do {
      return try self.pool.read() { db in
        try String.fetchOne(db, MXGrdbOlmAccount
                            .select(MXGrdbOlmAccount.CodingKeys.backupVersion)
                            .filter(MXGrdbOlmAccount.CodingKeys.userId == userId))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Backup Version for user ID \(userId): \(error)")
      return nil
    }
  }
  
  public func storeBackupVersion(_ backupVersion: String, for userId: String) {
    do {
      return try self.pool.write { db in
        try MXGrdbOlmAccount
          .filter(MXGrdbOlmAccount.CodingKeys.userId == userId)
          .updateAll(db, MXGrdbOlmAccount.CodingKeys.backupVersion.set(to: backupVersion))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing BackupVersion for user ID \(userId): \(error)")
    }
  }
}
