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
  
  public func retrieveDeviceTrackingStatusData(for userId: String) -> Data? {
    do {
      return try self.pool.read() { db in
        try Data.fetchOne(db, MXGrdbOlmAccount
                            .select(MXGrdbOlmAccount.CodingKeys.deviceTrackingStatusData)
                            .filter(MXGrdbOlmAccount.CodingKeys.userId == userId))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Device Tracking Status for user ID \(userId): \(error)")
      return nil
    }
  }
  
  public func storeDeviceTrackingStatusData(_ data: Data, for userId: String) {
    do {
      return try self.pool.write { db in
        try MXGrdbOlmAccount
          .filter(MXGrdbOlmAccount.CodingKeys.userId == userId)
          .updateAll(db, MXGrdbOlmAccount.CodingKeys.deviceTrackingStatusData.set(to: data))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing Device Tracking Status for user ID \(userId): \(error)")
    }
  }
}
