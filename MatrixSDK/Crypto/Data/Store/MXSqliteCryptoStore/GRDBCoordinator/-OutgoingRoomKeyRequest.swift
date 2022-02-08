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
  public func storeOutgoingRoomKeyRequest(_ request: MXGrdbOutgoingRoomKeyRequest) {
    do {
      try self.pool.write { db in
        try request.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing Outgoing Room Key Request: \(error)")
    }
  }
  
  public func retrieveOutgoingRoomKeyRequest(requestBodyHash: String) -> MXGrdbOutgoingRoomKeyRequest? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOutgoingRoomKeyRequest
          .filter(MXGrdbOutgoingRoomKeyRequest.CodingKeys.requestBodyHash == requestBodyHash)
          .limit(1)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Outgoing Room Key Request: \(error)")
      return nil
    }
  }
 
  public func retrieveOutgoingRoomKeyRequest(state: UInt) -> MXGrdbOutgoingRoomKeyRequest? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOutgoingRoomKeyRequest
          .filter(MXGrdbOutgoingRoomKeyRequest.CodingKeys.state == state)
          .limit(1)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Outgoing Room Key Request: \(error)")
      return nil
    }
  }
  
  public func retrieveAllOutgoingRoomKeyRequests(state: UInt) -> [MXGrdbOutgoingRoomKeyRequest]? {
    do {
      return try self.pool.read { db in
        return try MXGrdbOutgoingRoomKeyRequest
          .filter(MXGrdbOutgoingRoomKeyRequest.CodingKeys.state == state)
          .fetchAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Outgoing Room Key Requests: \(error)")
      return nil
    }
  }
  
  public func updateOutgoingRoomKeyRequest(id: String, newState: UInt) {
    do {
      return try self.pool.write { db in
        try MXGrdbOutgoingRoomKeyRequest
          .filter(MXGrdbOutgoingRoomKeyRequest.CodingKeys.id == id)
          .updateAll(db, MXGrdbOutgoingRoomKeyRequest.CodingKeys.state.set(to: newState))
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error updating state of Outgoing Room Key Request with id \(id): \(error)")
    }
  }
  
  public func deleteOutgoingRoomKeyRequest(id: String) {
    do {
      return try self.pool.write { db in
        try MXGrdbOutgoingRoomKeyRequest
          .filter(MXGrdbOutgoingRoomKeyRequest.CodingKeys.id == id)
          .deleteAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error deleting state of Outgoing Room Key Request with id \(id): \(error)")
    }
  }
}
