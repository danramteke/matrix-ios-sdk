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
  
  public func retrieveOlmSessionForSessionId(_ sessionId: String, deviceKey: String) -> MXGrdbOlmSession? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOlmSession
          .filter(MXGrdbOlmSession.CodingKeys.id == sessionId)
          .filter(MXGrdbOlmSession.CodingKeys.deviceKey == deviceKey)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving OLM session: \(error)")
      return nil
    }
  }
  
  public func storeOlmSession(_ olmSession: MXGrdbOlmSession) {
    do {
      try self.pool.write { db in
        try olmSession.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing OLM session: \(error)")
    }
  }
  
  public func performOlmSessionTransactionForSessionId(_ sessionId: String, deviceKey: String, block: (MXGrdbOlmSession?)->()) {
    do {
      try self.pool.write { db in
        let maybeSession = try MXGrdbOlmSession
          .filter(MXGrdbOlmSession.CodingKeys.id == sessionId)
          .filter(MXGrdbOlmSession.CodingKeys.deviceKey == deviceKey)
          .fetchOne(db)
        block(maybeSession)
        try maybeSession?.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error performing OLM session transaction: \(error)")
    }
  }
}
