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
  public func storeIncomingRoomKeyRequest(_ request: MXGrdbIncomingRoomKeyRequest) {
    do {
      try self.pool.write { db in
        try request.save(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing Incoming Room Key Request: \(error)")
    }
  }
  
  public func retrieveIncomingRoomKeyRequest(requestId: String, userId: String, deviceId: String) -> MXGrdbIncomingRoomKeyRequest? {
    do {
      return try self.pool.read { db in
        return try MXGrdbIncomingRoomKeyRequest
          .filter(MXGrdbIncomingRoomKeyRequest.CodingKeys.id == requestId)
          .filter(MXGrdbIncomingRoomKeyRequest.CodingKeys.userId == userId)
          .filter(MXGrdbIncomingRoomKeyRequest.CodingKeys.deviceId == deviceId)
          .fetchOne(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Outgoing Room Key Request: \(error)")
      return nil
    }
  }
  
  public func deleteIncomingRoomKeyRequest(requestId: String, userId: String, deviceId: String) {
    do {
      return try self.pool.write { db in
        try MXGrdbIncomingRoomKeyRequest
          .filter(MXGrdbIncomingRoomKeyRequest.CodingKeys.id == requestId)
          .filter(MXGrdbIncomingRoomKeyRequest.CodingKeys.userId == userId)
          .filter(MXGrdbIncomingRoomKeyRequest.CodingKeys.deviceId == deviceId)
          .deleteAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error deleting Outgoing Room Key Request: \(error)")
    }
  }
  
  public func retrieveAllIncomingRoomKeyRequests() -> [MXGrdbIncomingRoomKeyRequest]? {
    do {
      return try self.pool.read { db in
        return try MXGrdbIncomingRoomKeyRequest
          .fetchAll(db)
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Outgoing Room Key Request: \(error)")
      return nil
    }
  }
}
