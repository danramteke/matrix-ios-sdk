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
   
  public func retrieveSharedOutboundSessionWithRoomId(_ roomId: String, sessionId: String) -> MXUsersDevicesMap<NSNumber>? {
    do {
      return try self.pool.read { db in
        return try MXGrdbSharedOutboundSession
          .filter(MXGrdbSharedOutboundSession.CodingKeys.roomId == roomId)
          .filter(MXGrdbSharedOutboundSession.CodingKeys.sessionId == sessionId)
          .fetchAll(db)
          .reduce(MXUsersDevicesMap<NSNumber>(), { partialResult, row in
            partialResult.setObject(NSNumber(value: row.messageIndex), forUser: row.userId, andDevice: row.deviceId)
            return partialResult
          })
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving Shared Outbound Session for room ID \(roomId) and session ID \(sessionId): \(error)")
      return nil
    }
  }
  
  public func retrieveMessageIndexSharedOutboundSessionWithRoomId(_ roomId: String, sessionId: String, userId: String, deviceId: String) -> NSNumber? {
    do {
      return try self.pool.read { db in
        return try MXGrdbSharedOutboundSession
          .select(MXGrdbSharedOutboundSession.CodingKeys.messageIndex)
          .filter(MXGrdbSharedOutboundSession.CodingKeys.roomId == roomId)
          .filter(MXGrdbSharedOutboundSession.CodingKeys.sessionId == sessionId)
          .filter(MXGrdbSharedOutboundSession.CodingKeys.userId == userId)
          .filter(MXGrdbSharedOutboundSession.CodingKeys.deviceId == deviceId)
          .asRequest(of: UInt.self)
          .fetchOne(db)
          .map { uint in
            return NSNumber(value: uint)
          }
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error retrieving message index of Shared Outbound Session for room ID \(roomId) and session ID \(sessionId): \(error)")
      return nil
    }
  }
    
  public func storeSharedOutboundSession(devices: MXUsersDevicesMap<NSNumber>, messageIndex: UInt, roomId: String, sessionId: String) {
    do {
      try self.pool.write { db in
        for userId in devices.userIds() {
          for deviceId in devices.deviceIds(forUser: userId) {
            
            guard try MXGrdbDevice.filter(MXGrdbDevice.CodingKeys.id == deviceId).fetchCount(db) > 0 else {
              MXLog.debug("[\(String(describing: Self.self))] storeSharedOutboundSession cannot find device with the ID \(deviceId)")
              continue
            }
            
            guard try MXGrdbUser.filter(MXGrdbUser.CodingKeys.id == userId).fetchCount(db) > 0 else {
              MXLog.debug("[\(String(describing: Self.self))] storeSharedOutboundSession cannot find user with the ID \(userId)")
              continue
            }
            
            try MXGrdbSharedOutboundSession(roomId: roomId, sessionId: sessionId, deviceId: deviceId, userId: userId, messageIndex: messageIndex)
              .save(db)
          }
        }
      }
    } catch {
      MXLog.error("[\(String(describing: Self.self))] error storing devices for Shared Outbound Session for room ID \(roomId) and session ID \(sessionId): \(error)")
    }
  }
}
