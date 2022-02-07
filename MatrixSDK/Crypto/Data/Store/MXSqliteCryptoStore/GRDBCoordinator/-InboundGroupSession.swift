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
  
  public func countInboundGroupSessionsOnlyBackedUp(_ onlyBackedUp: Bool) -> Int {
    do {
      return try self.pool.read { db in
        if onlyBackedUp {
          return try MXGrdbOlmInboundGroupSession
            .filter(MXGrdbOlmInboundGroupSession.CodingKeys.backedUp == true)
            .fetchCount(db)
        } else {
          return try MXGrdbOlmInboundGroupSession
            .fetchCount(db)
        }
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving count of Inbound Group Sessions: \(error)")
      return 0
    }
  }
  
  public func storeInboundGroupSessions(_ sessionList: Array<MXGrdbOlmInboundGroupSession>) {
    do {
      try self.pool.write { db in
        try sessionList.forEach { session in
          try session.save(db)
        }
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing Inbound Group Sessions: \(error)")
    }
  }

  public func deleteInboundGroupSessionBySessionId(_ sessionId: String, senderKey: String) {
    do {
      return try self.pool.write { db in
        try MXGrdbOlmInboundGroupSession
          .filter(MXGrdbOlmInboundGroupSession.CodingKeys.id == sessionId)
          .filter(MXGrdbOlmInboundGroupSession.CodingKeys.senderKey == senderKey)
          .deleteAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error deleting Inbound Group Session for session ID \(sessionId) and sender key \(senderKey): \(error)")
    }
  }
  
  public func retrieveInboundGroupSessionBySessionId(_ sessionId: String, senderKey: String) -> MXGrdbOlmInboundGroupSession? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOlmInboundGroupSession
          .filter(MXGrdbOlmInboundGroupSession.CodingKeys.id == sessionId)
          .filter(MXGrdbOlmInboundGroupSession.CodingKeys.senderKey == senderKey)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Inbound Group Session for session ID \(sessionId) and sender key \(senderKey): \(error)")
      return nil
    }
  }
  
  public func retrieveAllInboundGroupSessions() -> [MXGrdbOlmInboundGroupSession]? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOlmInboundGroupSession
          .fetchAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving all Inbound Group Sessions: \(error)")
      return nil
    }
  }
  
  public func performOlmInboundGroupSessionTransactionForSessionId(_ sessionId: String, senderKey: String, block: (MXGrdbOlmInboundGroupSession?)->()) {
    do {
      try self.pool.write { db in
        let maybeSession = try MXGrdbOlmInboundGroupSession
          .filter(MXGrdbOlmInboundGroupSession.CodingKeys.id == sessionId)
          .filter(MXGrdbOlmInboundGroupSession.CodingKeys.senderKey == senderKey)
          .fetchOne(db)
        block(maybeSession)
        try maybeSession?.update(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error performing OLM inbound group session transaction: \(error)")
    }
  }
  
  public func resetBackupMarkers() {
    do {
      return try self.pool.write { db in
        try MXGrdbOlmInboundGroupSession
          .updateAll(db, MXGrdbOlmInboundGroupSession.CodingKeys.backedUp.set(to: false))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error resetting backup markers for OLM inbound group session transaction: \(error)")
    }
  }
  
  public func markBackupDoneForInboundGroupSessions(_ sessions: [MXOlmInboundGroupSession]) {
    do {
      return try self.pool.write { db in
        for session in sessions {
          try MXGrdbOlmInboundGroupSession
            .filter(MXGrdbOlmInboundGroupSession.CodingKeys.senderKey == session.senderKey && MXGrdbOlmInboundGroupSession.CodingKeys.id == session.sessionIdentifier())
            .updateAll(db, MXGrdbOlmInboundGroupSession.CodingKeys.backedUp
                        .set(to: true))
        }
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error marking backup done for OLM inbound group session transaction: \(error)")
    }
  }
  
  public func retrieveInboundGroupSessionsToBackup(limit: Int) -> [MXGrdbOlmInboundGroupSession]? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOlmInboundGroupSession
          .filter(MXGrdbOlmInboundGroupSession.CodingKeys.backedUp == false)
          .limit(limit)
          .fetchAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving all Inbound Group Sessions: \(error)")
      return nil
    }
  }
}
