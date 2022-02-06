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
 
  public func storeOutboundGroupSession(_ session: MXGrdbOlmOutboundGroupSession) {
    do {
      return try self.pool.write { db in
        try session.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing Outbound Group Session for room ID \(session.roomId): \(error)")
    }
  }
  
  public func retrieveOutboundGroupSessionWithRoomId(_ roomId: String) -> MXGrdbOlmOutboundGroupSession? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOlmOutboundGroupSession
          .filter(MXGrdbOlmOutboundGroupSession.CodingKeys.roomId == roomId)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Outbound Group Session for room ID \(roomId): \(error)")
      return nil
    }
  }
  
  public func retrieveAllOutboundGroupSessions() -> [MXGrdbOlmOutboundGroupSession]? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOlmOutboundGroupSession
          .fetchAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving all Outbound Group Sessions: \(error)")
      return nil
    }
  }
  
  public func deleteOutboundGroupSessionsWithRoomId(_ roomId: String) {
    do {
      return try self.pool.write { db in
        try MXGrdbOlmOutboundGroupSession
          .filter(MXGrdbOlmOutboundGroupSession.CodingKeys.roomId == roomId)
          .deleteAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error deleting Outbound Group Session for room ID \(roomId): \(error)")
    }
  }
}
